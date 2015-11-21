/** \file
 * Vector display using the MCP4921 DAC on the teensy3.1.
 *
 * this uses the DMA hardware to drive the SPI output and
 * the second chip select pin (6) to enable/disable the beam.
 *
 * format of commands is 3-bytes per command.
 * 2 bits
 *  00 == number of lines to be sent
 *  01 == "pen up" move to new X,Y
 *  10 == normal line to X,Y
 *  11 == bright line to X,Y
 * 11 bits of X (or number of lines)
 * 11 bits of Y
 *
 * the Z axis on the vectrex needs to swing 0 to 5V, so it uses
 * an NPN transistor to switch it totally off.
 */
#include <SPI.h>
#include "DMAChannel.h"

#define SS_PIN	10
#define SS2_PIN	6
#define SDI	11
#define SCK	13

#define DEBUG_PIN	8
#define DELAY_PIN	7
#define IO_PIN	5

#define MAX_PTS 3000
static unsigned rx_points;
static unsigned num_points;
static uint16_t points[MAX_PTS][2];
static unsigned do_resync;

#define MOVETO		(1<<11)
#define LINETO		(2<<11)
#define BRIGHTTO	(3<<11)

static unsigned bright_off = 0;
int bright_x = 2048;




#undef FLIP_Y
#undef FLIP_X
#undef SWAP_XY
#undef LINE_BRIGHT_DOUBLE

#define BRIGHT_SHIFT	1 // larger numbers == dimmer lines
#define NORMAL_SHIFT	1
#undef OFF_JUMP	// don't wait, just go!
#define OFF_SHIFT	5
#define OFF_DWELL0	14 // time to sit beam on before starting a transit
#define OFF_DWELL1	0 // time to sit before starting a transit
#define OFF_DWELL2	19 // time to sit after finishing a transit
//#define TRANSIT_SPEED	2000

#define CONFIG_DACZ	// If there is a Z dac, rather than a PNP

#ifdef OFF_JUMP
#define REST_X 0
#define REST_Y 0
#else
#define REST_X 2048
#define REST_Y 2048
#endif

static DMAChannel spi_dma;
#define SPI_DMA_MAX 4096
//#define SPI_DMA_MAX 2048
static uint32_t spi_dma_q[2][SPI_DMA_MAX];
static unsigned spi_dma_which;
static unsigned spi_dma_count;
static unsigned spi_dma_in_progress;
static unsigned spi_dma_cs; // which pins are we using for IO

#define SPI_DMA_CS_BEAM_ON 2
#define SPI_DMA_CS_BEAM_OFF 1


static int
spi_dma_tx_append(
	uint16_t value
)
{
	spi_dma_q[spi_dma_which][spi_dma_count++] = 0
		| ((uint32_t) value)
		| (spi_dma_cs << 16) // enable the chip select line
		;

	if (spi_dma_count == SPI_DMA_MAX)
		return 1;
	return 0;
}


static void
spi_dma_tx()
{
	if (spi_dma_count == 0)
		return;

	digitalWriteFast(DELAY_PIN, 1);

	// add a EOQ to the last entry
	spi_dma_q[spi_dma_which][spi_dma_count-1] |= (1<<27);

	spi_dma.clearComplete();
	spi_dma.clearError();
	spi_dma.sourceBuffer(
		spi_dma_q[spi_dma_which],
		4 * spi_dma_count  // in bytes, not thingies
	);

	spi_dma_which = !spi_dma_which;
	spi_dma_count = 0;

	SPI0_SR = 0xFF0F0000;
	SPI0_RSER = 0
		| SPI_RSER_RFDF_RE
		| SPI_RSER_RFDF_DIRS
		| SPI_RSER_TFFF_RE
		| SPI_RSER_TFFF_DIRS;

	spi_dma.enable();
	spi_dma_in_progress = 1;
}


static int
spi_dma_tx_complete()
{
	//cli();

	// if nothing is in progress, we're "complete"
	if (!spi_dma_in_progress)
	{
		//sei();
		return 1;
	}

	if (!spi_dma.complete())
	{
		//sei();
		return 0;
	}

	digitalWriteFast(DELAY_PIN, 0);

	spi_dma.clearComplete();
	spi_dma.clearError();

	// the DMA hardware lies; it is not actually complete
	delayMicroseconds(5);
	//sei();

	// we are done!
	SPI0_RSER = 0;
	SPI0_SR = 0xFF0F0000;
	spi_dma_in_progress = 0;
	return 1;
}


static void
spi_dma_setup()
{
	spi_dma.disable();
	spi_dma.destination((volatile uint32_t&) SPI0_PUSHR);
	spi_dma.disableOnCompletion();
	spi_dma.triggerAtHardwareEvent(DMAMUX_SOURCE_SPI0_TX);
	spi_dma.transferSize(4); // write all 32-bits of PUSHR

	SPI.beginTransaction(SPISettings(20000000, MSBFIRST, SPI_MODE0));

	// configure the output on pin 10 for !SS0 from the SPI hardware
	// and pin 6 for !SS1.
	CORE_PIN10_CONFIG = PORT_PCR_DSE | PORT_PCR_MUX(2);
	CORE_PIN6_CONFIG = PORT_PCR_DSE | PORT_PCR_MUX(2);

	// configure the frame size for 16-bit transfers
	SPI0_CTAR0 |= 0xF << 27;

	// send something to get it started

	spi_dma_which = 0;
	spi_dma_count = 0;

	spi_dma_tx_append(0);
	spi_dma_tx_append(0);
	spi_dma_tx();
}



void
setup()
{
	Serial.begin(9600);
	pinMode(DELAY_PIN, OUTPUT);
	pinMode(DEBUG_PIN, OUTPUT);
	pinMode(IO_PIN, OUTPUT);

	digitalWrite(DELAY_PIN, 0);
	digitalWrite(DEBUG_PIN, 0);
	digitalWrite(IO_PIN, 0);

	digitalWrite(SS2_PIN, 0);

	pinMode(SS_PIN, OUTPUT);
	pinMode(SS2_PIN, OUTPUT);
	pinMode(SDI, OUTPUT);
	pinMode(SCK, OUTPUT);

#if 1
	// fill in some points for test and calibration
	int i = 0;
	points[i][0] = 0 | MOVETO;
	points[i++][1] = 0;
	points[i][0] = 512 | LINETO;
	points[i++][1] = 0;
	points[i][0] = 512 | LINETO;
	points[i++][1] = 512;
	points[i][0] = 0 | LINETO;
	points[i++][1] = 512;
	points[i][0] = 0 | LINETO;
	points[i++][1] = 0;

	points[i][0] = 2047 | MOVETO;
	points[i++][1] = 0;
	points[i][0] = (2047 - 128) | LINETO;
	points[i++][1] = 0;
	points[i][0] = (2047 - 0) | LINETO;
	points[i++][1] = 128;
	points[i][0] = 2047 | LINETO;
	points[i++][1] = 0;

	points[i][0] = 2047 | MOVETO;
	points[i++][1] = 2047;
	points[i][0] = (2047 - 128) | LINETO;
	points[i++][1] = 2047;
	points[i][0] = (2047 - 128) | LINETO;
	points[i++][1] = (2047 - 128);
	points[i][0] = (2047 - 0) | LINETO;
	points[i++][1] = (2047 - 128);
	points[i][0] = 2047 | LINETO;
	points[i++][1] = 2047;

	points[i][0] = 0 | MOVETO;
	points[i++][1] = 2047;
	points[i][0] = 128 | LINETO;
	points[i++][1] = 2047;
	points[i][0] = 128 | LINETO;
	points[i++][1] = (2047 - 128);
	points[i][0] = 0 | LINETO;
	points[i++][1] = (2047 - 128);
	points[i][0] = 0 | LINETO;
	points[i++][1] = 2047;

	points[i][0] = 1024 | MOVETO;
	points[i++][1] = 512;
	points[i][0] = 1024 | BRIGHTTO;
	points[i++][1] = 1024+512;

	points[i][0] = 512 | MOVETO;
	points[i++][1] = 1024;
	points[i][0] = (1024+512) | BRIGHTTO;
	points[i++][1] = 1024;

	for(unsigned j = 0 ; j <= 512 ; j += 64)
	{
		points[i][0] = 0 | MOVETO;
		points[i++][1] = 0;
		points[i][0] = 512 | LINETO;
		points[i++][1] = j;
	}

	for(unsigned j = 0 ; j < 512 ; j += 64)
	{
		points[i][0] = 0 | MOVETO;
		points[i++][1] = 0;
		points[i][0] = j | LINETO;
		points[i++][1] = 512;
	}

	// and a small v.st logo
	const int vx = 1024+256;
	const int vy = 1024+512;
	const int doty = vy-12*8;
	const int dotx = vx;
	const int sy = vy-24*8;
	const int sx = vx;
	const int ty = vy-36*8;
	const int tx = vx;

#define MOVE_LINE(x,y, dx, dy) do { \
	points[i][0] = (x + dy*8) | MOVETO; \
	points[i++][1] = (y - dx*8); \
} while(0)
#define DRAW_LINE(x,y, dx,dy) do { \
	points[i][0] = (x + dy*8) | LINETO; \
	points[i++][1] = (y - dx*8); \
} while(0)

	MOVE_LINE(vx, vy, 0, 12);
	DRAW_LINE(vx, vy, 4, 0);
	DRAW_LINE(vx, vy, 8, 12);

	MOVE_LINE(dotx, doty, 3, 0);
	DRAW_LINE(dotx, doty, 4, 0);

	MOVE_LINE(sx, sy, 0, 2);
	DRAW_LINE(sx, sy, 2, 0);
	DRAW_LINE(sx, sy, 8, 0);
	DRAW_LINE(sx, sy, 8, 5);
	DRAW_LINE(sx, sy, 0, 7);
	DRAW_LINE(sx, sy, 0, 12);
	DRAW_LINE(sx, sy, 6, 12);
	DRAW_LINE(sx, sy, 8, 10);

	MOVE_LINE(tx, ty, 0, 12);
	DRAW_LINE(tx, ty, 8, 12);
	MOVE_LINE(tx, ty, 4, 12);
	DRAW_LINE(tx, ty, 4, 0);

	num_points = i;
#endif
	

#ifdef SLOW_SPI
	SPI.begin();
	SPI.setClockDivider(SPI_CLOCK_DIV2);
#else
	//spi4teensy3::init(0);
	SPI.begin();
	SPI.setClockDivider(SPI_CLOCK_DIV2);

	//DMASPI0.begin();
	//DMASPI0.start();
	spi_dma_setup();
#endif
}


static void
mpc4921_write(
	int channel,
	uint16_t value
)
{
	value &= 0x0FFF; // mask out just the 12 bits of data

#if 1
	// select the output channel, buffered, no gain
	value |= 0x7000 | (channel == 1 ? 0x8000 : 0x0000);
#else
	// select the output channel, unbuffered, no gain
	value |= 0x3000 | (channel == 1 ? 0x8000 : 0x0000);
#endif

#ifdef SLOW_SPI
	SPI.transfer((value >> 8) & 0xFF);
	SPI.transfer((value >> 0) & 0xFF);
#else
	if (spi_dma_tx_append(value) == 0)
		return;

	// wait for the previous line to finish
	while(!spi_dma_tx_complete())
		;

	// now send this line, which swaps buffers
	spi_dma_tx();
#endif
}




// x and y position are in 12-bit range
static uint16_t x_pos;
static uint16_t y_pos;

#ifdef SWAP_XY
#define DAC_X_CHAN 1
#define DAC_Y_CHAN 0
#else
#define DAC_X_CHAN 0
#define DAC_Y_CHAN 1
#endif

static inline void
goto_x(
	uint16_t x
)
{
	x_pos = x;
#ifdef FLIP_X
	mpc4921_write(DAC_X_CHAN, 4095 - x);
#else
	mpc4921_write(DAC_X_CHAN, x);
#endif
}

static inline void
goto_y(
	uint16_t y
)
{
	y_pos = y;
#ifdef FLIP_Y
	mpc4921_write(DAC_Y_CHAN, 4095 - y);
#else
	mpc4921_write(DAC_Y_CHAN, y);
#endif
}

static inline void
brightness(
	uint16_t bright
)
{
#ifdef CONFIG_DACZ
	spi_dma_cs = SPI_DMA_CS_BEAM_OFF;
	mpc4921_write(1, 2048);
	mpc4921_write(0, bright);
	spi_dma_cs = SPI_DMA_CS_BEAM_ON;
#else
	// nothing to do
	(void) bright;
#endif
}

static inline void
_lineto(
	int x1,
	int y1,
	const int bright_shift
)
{
	int dx;
	int dy;
	int sx;
	int sy;

	const int x1_orig = x1;
	const int y1_orig = y1;

	int x_off = x1 & ((1 << bright_shift) - 1);
	int y_off = y1 & ((1 << bright_shift) - 1);
	x1 >>= bright_shift;
	y1 >>= bright_shift;
	int x0 = x_pos >> bright_shift;
	int y0 = y_pos >> bright_shift;

	goto_x(x_pos);
	goto_y(y_pos);

	if (x0 <= x1)
	{
		dx = x1 - x0;
		sx = 1;
	} else {
		dx = x0 - x1;
		sx = -1;
	}

	if (y0 <= y1)
	{
		dy = y1 - y0;
		sy = 1;
	} else {
		dy = y0 - y1;
		sy = -1;
	}

	int err = dx - dy;

	while (1)
	{
		if (x0 == x1 && y0 == y1)
			break;

		int e2 = 2 * err;
		if (e2 > -dy)
		{
			err = err - dy;
			x0 += sx;
			goto_x(x_off + (x0 << bright_shift));
		}
		if (e2 < dx)
		{
			err = err + dx;
			y0 += sy;
			goto_y(y_off + (y0 << bright_shift));
		}

#ifdef LINE_BRIGHT_DOUBLE
		if (bright_shift == 0)
		{
			goto_x(x_off + (x0 << bright_shift));
			goto_y(y_off + (y0 << bright_shift));
		}
#endif
	}

	// ensure that we end up exactly where we want
	goto_x(x1_orig);
	goto_y(y1_orig);
}


void
lineto(
	int x1,
	int y1
)
{
#ifdef CONFIG_DACZ
	brightness(3700);
#endif
	_lineto(x1, y1, NORMAL_SHIFT);
}

void
lineto_bright(
	int x1,
	int y1
)
{
#ifdef CONFIG_DACZ
	brightness(4095);
#endif
	_lineto(x1, y1, BRIGHT_SHIFT);
}


static void
dwell(
	const int count
)
{
	for (int i = 0 ; i < count ; i++)
	{
		if (i & 1)
			goto_x(x_pos);
		else
			goto_y(y_pos);
	}
}


void
lineto_off(
	int x1,
	int y1
)
{
#ifdef OFF_JUMP
	goto_x(x1);
	goto_y(y1);
#else
	
#ifdef CONFIG_DACZ
	brightness(bright_off); // halfway
#else

	if (spi_dma_cs != SPI_DMA_CS_BEAM_OFF)
	{
		// hold the current position for a few clocks
		// with the beam on
		dwell(OFF_DWELL0);
	}

	spi_dma_cs = SPI_DMA_CS_BEAM_OFF;
#endif

	// hold the current position for a few clocks
	// with the beam off
	dwell(OFF_DWELL1);
	_lineto(x1, y1, OFF_SHIFT);


	dwell(OFF_DWELL2);
#endif // OFF_JUMP
}

uint8_t
read_blocking()
{
	while(1)
	{
		int c = Serial.read();
		if (c >= 0)
			return c;
	}
}


static int
read_data()
{
	static uint32_t cmd;
	static unsigned offset;

	int c = Serial.read();
	if (c < 0)
		return -1;

	digitalWriteFast(IO_PIN, 1);

#if 0
	static int new_bright = 0;
	if ('0' <= c && c <= '9')
	{
		new_bright = (new_bright * 10) + c - '0';
		return 0;
	}

	if (c == '\n')
	{
		bright_x = new_bright;
		new_bright = 0;
		return 1;
	}

	return -1;
#endif

	//Serial.print("----- read: ");
	//Serial.println(c);

	// if we are resyncing, wait for a non-zero byte
	if (do_resync)
	{
		if (c == 0)
			return 0;
		do_resync = 0;
	}

	cmd = (cmd << 8) | c;
	offset++;

	if (offset != 3)
		return 0;

	// we have a new command
	// check for a resync
	if (cmd == 0)
	{
		do_resync = 1;
		offset = cmd = 0;
		return 0;
	}

	unsigned bright	= (cmd >> 22) & 0x3;
	unsigned x	= (cmd >> 11) & 0x7FF;
	unsigned y	= (cmd >> 0) & 0x7FF;

	offset = cmd = 0;

	// bright 0, switch buffers
	if (bright == 0)
	{
		num_points = rx_points;
		rx_points = 0;

		//Serial.print("*** fb");
		//Serial.print(fb);
		//Serial.print(" ");
		//Serial.println(num_points);
		digitalWriteFast(IO_PIN, 0);
		return 1;
	}

	uint16_t * pt = points[rx_points++];
	pt[0] = x | (bright << 11);
	pt[1] = y;

	return 0;
}


void
loop()
{
	//Serial.print(fb);
	//Serial.print(' ');
	//Serial.print(num_points);
	//Serial.println();

	static uint32_t frame_micros;
	uint32_t now;

	while(1)
	{
		now = micros();

		// make sure we flush the partial buffer
		// once the last one has completed
		if (spi_dma_tx_complete())
		{
			if (rx_points == 0 && now - frame_micros > 25000u)
				break;
			spi_dma_tx();
		}

		// start redraw when read_data is done
		if (Serial.available() && read_data() == 1)
			break;
	}

	// if there are any DMAs currently in transit, wait for them
	// to complete.
	while (!spi_dma_tx_complete())
		;

	frame_micros = now;

	// flag that we have started an output frame
	digitalWriteFast(DEBUG_PIN, 1);

	for(unsigned n = 0 ; n < num_points ; n++)
	{
		const uint16_t * const pt = points[n];
		uint16_t x = pt[0];
		uint16_t y = pt[1];
		unsigned intensity = (x >> 11) & 0x3;
#if 0
		x = (x & 0x7FF) << 1;
		y = (y & 0x7FF) << 1;
#else
		x = ((x & 0x7FF) >> 0) + 1024;
		y = ((y & 0x7FF) >> 0) + 1024;
#endif

		if (intensity == 1)
			lineto_off(x,y);
		else
		if (intensity == 2)
			lineto(x, y);
		else
			lineto_bright(x, y);
	}

	// go to the center of the screen, turn the beam off
	brightness(bright_off);

	goto_x(REST_X);
	goto_y(REST_Y);

	// the USB loop above will flush eventually
	digitalWriteFast(DEBUG_PIN, 0);

	Serial.println(bright_x);
}

