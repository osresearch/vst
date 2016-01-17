/** \file
 * Vector display using the MCP4921 DAC on the teensy3.1.
 *
 * More info: https://trmm.net/V.st
 *
 * This uses the DMA hardware to drive the SPI output to two DACs,
 * one on SS0 and one on SS1.  The first two DACs are used for the
 * XY position, the third DAC for brightness and the fourth to generate
 * a 2.5V reference signal for the mid-point.
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
 */
#include <SPI.h>
#include <Time.h>
#include "DMAChannel.h"

#define CONFIG_FONT_HERSHEY

#ifdef CONFIG_FONT_HERSHEY
#include "hershey_font.h"
#else
#include "asteroids_font.h"
#endif

//#define CONFIG_VECTREX
#define CONFIG_VECTORSCOPE

// If you just want a scope clock,
// solder a 32.768 KHz crystal to the teensy and provide a backup
// battery on the BAT pin.
#undef CONFIG_CLOCK

// Sometimes the X and Y need to be flipped and/or swapped
#undef FLIP_X
#undef FLIP_Y
#undef SWAP_XY

// How often should a frame be drawn if we haven't receivded any serial
// data from MAME (in ms).
#define REFRESH_RATE 20000u


#if defined(CONFIG_VECTORSCOPE)
/** Vectorscope configuration.
 *
 * Vectorscopes and oscilloscopes have electrostatic beam deflection
 * and can steer the beam much faster, so there is no need to dwell or
 * wait for the beam to catch up during transits.
 *
 * Most of them do not have a Z input, so we move the beam to an extreme
 * during the blanking interval.
 *
 * If your vectorscope doesn't have a Z axis, undefine CONFIG_BRIGHTNESS
 */
#define BRIGHT_SHIFT	0	// larger numbers == dimmer lines
#define NORMAL_SHIFT	1	// no z-axis, so we must have a difference
#define OFF_JUMP		// don't wait for beam, just go!
#define REST_X		0	// wait off screen
#define REST_Y		0

#undef FULL_SCALE		// only use -1.25 to 1.25V range

// most vector scopes don't have brightness control, but set it anyway
#undef CONFIG_BRIGHTNESS
#define BRIGHT_OFF	2048	// "0 volts", relative to reference
#define BRIGHT_NORMAL	3800	// fairly bright
#define BRIGHT_BRIGHT	4095	// super bright


#elif defined(CONFIG_VECTREX)
/** Vectrex configuration.
 *
 * Vectrex monitors use magnetic steering and are much slower to respond
 * to changes.  As a result we must dwell on the end points and wait for
 * the beam to catch up during transits.
 *
 * It does have a Z input for brightness, which has three configurable
 * brightnesses (off, normal and bright).  These were experimentally
 * determined and might not be right for all monitors.
 */

#define BRIGHT_SHIFT	2	// larger numbers == dimmer lines
#define NORMAL_SHIFT	2	// but we can control with Z axis
#undef OFF_JUMP			// too slow, so we can't jump the beam

#define OFF_SHIFT	5	// smaller numbers == slower transits
#define OFF_DWELL0	10	// time to sit beam on before starting a transit
#define OFF_DWELL1	0	// time to sit before starting a transit
#define OFF_DWELL2	10	// time to sit after finishing a transit

#define REST_X		2048	// wait in the center of the screen
#define REST_Y		2048

#define CONFIG_BRIGHTNESS	// use the brightness DAC
#define BRIGHT_OFF	2048	// "0 volts", relative to reference
#define BRIGHT_NORMAL	3200	// fairly bright
#define BRIGHT_BRIGHT	4095	// super bright

#define FULL_SCALE		// use the full -2.5 to 2.5V range

#else
#error "One of CONFIG_VECTORSCOPE or CONFIG_VECTREX must be defined"
#endif


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



#undef LINE_BRIGHT_DOUBLE



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
rx_append(
	unsigned bright,
	int x,
	int y
)
{
	uint16_t * pt = points[rx_points++];
	pt[0] = x | bright;
	pt[1] = y;
}


void
moveto(int x, int y)
{
	rx_append(MOVETO, x, y);
}


void
lineto(int x, int y)
{
	rx_append(LINETO, x, y);
}


void
brightto(int x, int y)
{
	rx_append(BRIGHTTO, x, y);
}


int
draw_character(
	char c,
	int x,
	int y,
	int size
)
{
#ifdef CONFIG_FONT_HERSHEY
	const hershey_char_t * const f = &hershey_simplex[c - ' '];
	int next_moveto = 1;

	for(int i = 0 ; i < f->count ; i++)
	{
		unsigned dx = f->points[2*i+0];
		unsigned dy = f->points[2*i+1];
		if (dx == -1)
		{
			next_moveto = 1;
			continue;
		}

		dx = (dx * size) * 3 / 4;
		dy = (dy * size) * 3 / 4;

		if (next_moveto)
			moveto(x + dx, y + dy);
		else
			lineto(x + dx, y + dy);

		next_moveto = 0;
	}

	return (f->width * size) * 3 / 4;
#else
	// Asteroids font only has upper case
	if ('a' <= c && c <= 'z')
		c -= 'a' - 'A';

	const uint8_t * const pts = asteroids_font[c - ' '].points;
	int next_moveto = 1;

	for(int i = 0 ; i < 8 ; i++)
	{
		uint8_t delta = pts[i];
		if (delta == FONT_LAST)
			break;
		if (delta == FONT_UP)
		{
			next_moveto = 1;
			continue;
		}

		unsigned dx = ((delta >> 4) & 0xF) * size;
		unsigned dy = ((delta >> 0) & 0xF) * size;

		if (next_moveto)
			moveto(x + dx, y + dy);
		else
			lineto(x + dx, y + dy);

		next_moveto = 0;
	}

	return 12 * size;
#endif
}


void
draw_string(
	const char * s,
	int x,
	int y,
	int size
)
{
	while(*s)
	{
		char c = *s++;
		x += draw_character(c, x, y, size);
	}
}

static void
draw_test_pattern()
{
	// fill in some points for test and calibration
	moveto(0,0);
	lineto(512,0);
	lineto(512,512);
	lineto(0,512);
	lineto(0,0);

	// triangle
	moveto(2047, 0);
	lineto(2047-128, 0);
	lineto(2047-0, 128);
	lineto(2047,0);

	// cross
	moveto(2047,2047);
	lineto(2047-128,2047);
	lineto(2047-128,2047-128);
	lineto(2047,2047-128);
	lineto(2047,2047);

	moveto(0,2047);
	lineto(128,2047);
	lineto(0,2047-128);
	lineto(128, 2047-128);
	lineto(0,2047);

	moveto(1024,512);
	brightto(1024,1024+512);

	moveto(512,1024);
	brightto(1024+512,1024);

	// draw the sunburst pattern in the corner
	moveto(0,0);
	for(unsigned j = 0, i=0 ; j <= 512 ; j += 64, i++)
	{
		if (i & 1)
		{
			moveto(512,j);
			lineto(0,0);
		} else {
			lineto(512,j);
		}
	}

	moveto(0,0);
	for(unsigned j = 0, i=0 ; j < 512 ; j += 64, i++)
	{
		if (i & 1)
		{
			moveto(j,512);
			lineto(0,0);
		} else {
			lineto(j,512);
		}
	}

	draw_string("http://v.st/", 1024 - 450, 1024 + 600, 6);

	draw_string("Firmware built", 1100, 900, 3);
	draw_string(__DATE__, 1100, 830, 3);
	draw_string(__TIME__, 1100, 760, 3);

	int y = 1400;
	const int line_size = 70;

	//draw_string("Options:", 1100, y, 3); y -= line_size;
#ifdef CONFIG_VECTREX
	draw_string("VECTREX", 1100, y, 3); y -= line_size;
#else
	draw_string("Vectorscope", 1100, y, 3); y -= line_size;
#endif
#ifdef FLIP_X
	draw_string("FLIP_X", 1100, y, 3); y -= line_size;
#endif
#ifdef FLIP_Y
	draw_string("FLIP_Y", 1100, y, 3); y -= line_size;
#endif
#ifdef SWAP_XY
	draw_string("SWAP_XY", 1100, y, 3); y -= line_size;
#endif
#ifdef FULL_SCALE
	draw_string("Fullscale", 1100, y, 3); y -= line_size;
#endif

}


static time_t
teensy3_rtc()
{
	return Teensy3Clock.get();
}



void
setup()
{
	// set the Time library to use Teensy 3.0's RTC to keep time
	setSyncProvider(teensy3_rtc);

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

	rx_points = 0;

	draw_test_pattern();
	num_points = rx_points;
	rx_points = 0;
	

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

static inline void
brightness(
	uint16_t bright
)
{
#ifdef CONFIG_BRIGHTNESS
	static unsigned last_bright;
	if (last_bright == bright)
		return;
	last_bright = bright;

	dwell(OFF_DWELL0);
	spi_dma_cs = SPI_DMA_CS_BEAM_OFF;
	mpc4921_write(0, bright);
	spi_dma_cs = SPI_DMA_CS_BEAM_ON;
#else
	(void) bright;
#endif
}

static inline void
_draw_lineto(
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
draw_lineto(
	int x1,
	int y1
)
{
	brightness(BRIGHT_NORMAL);
	_draw_lineto(x1, y1, NORMAL_SHIFT);
}

void
draw_bright(
	int x1,
	int y1
)
{
	brightness(BRIGHT_BRIGHT);
	_draw_lineto(x1, y1, BRIGHT_SHIFT);
}



void
draw_moveto(
	int x1,
	int y1
)
{
	brightness(BRIGHT_OFF);

#ifdef OFF_JUMP
	goto_x(x1);
	goto_y(y1);
#else
	// hold the current position for a few clocks
	// with the beam off
	dwell(OFF_DWELL1);
	_draw_lineto(x1, y1, OFF_SHIFT);
	dwell(OFF_DWELL2);
#endif // OFF_JUMP
}


void
_circle(
	int cx,
	int cy,
	int r,
	int octant
)
{
	int x = r;
	int y = 0;
	int decision_over2 = 1 - x;

	//moveto(cx+x, cy+y);

	while(y <= x)
	{
		switch(octant)
		{
		case 0: lineto(cx+x, cy+y); break;
		case 1: lineto(cx+x, cy-y); break;
		case 2: lineto(cx+y, cy+x); break;
		default: break;
		}

		y++;
		if (decision_over2 <= 0)
		{
			decision_over2 += 2 * y + 1;
		} else
		{
			x--;
			decision_over2 += 2 * (y - x) + 1;
		}
	}
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

#ifndef CONFIG_CLOCK
	while(1)
	{
		now = micros();

		// make sure we flush the partial buffer
		// once the last one has completed
		if (spi_dma_tx_complete())
		{
			if (rx_points == 0 && now - frame_micros > REFRESH_RATE)
				break;
			spi_dma_tx();
		}

		// start redraw when read_data is done
		if (Serial.available() && read_data() == 1)
			break;
	}

	frame_micros = now;

	// if there are any DMAs currently in transit, wait for them
	// to complete.
	while (!spi_dma_tx_complete())
		;

	// now start any last buffered ones and wait for those
	// to complete.
	spi_dma_tx();
	while (!spi_dma_tx_complete())
		;

#else
	// if there are any DMAs currently in transit, wait for them
	// to complete.
	while (!spi_dma_tx_complete())
		;

	// now start any last buffered ones and wait for those
	// to complete.
	spi_dma_tx();
	while (!spi_dma_tx_complete())
		;

	// redraw the clock image
	scopeclock();
#endif


	// flag that we have started an output frame
	digitalWriteFast(DEBUG_PIN, 1);

	// force a reference voltage write on every cycle
	spi_dma_cs = SPI_DMA_CS_BEAM_OFF;
	mpc4921_write(1, 2048);
	spi_dma_cs = SPI_DMA_CS_BEAM_ON;

	for(unsigned n = 0 ; n < num_points ; n++)
	{
		const uint16_t * const pt = points[n];
		uint16_t x = pt[0];
		uint16_t y = pt[1];
		unsigned intensity = (x >> 11) & 0x3;
#ifdef FULL_SCALE
		x = (x & 0x7FF) << 1;
		y = (y & 0x7FF) << 1;
#else
		x = ((x & 0x7FF) >> 0) + 1024;
		y = ((y & 0x7FF) >> 0) + 1024;
#endif

		if (intensity == 1)
			draw_moveto(x,y);
		else
		if (intensity == 2)
			draw_lineto(x, y);
		else
			draw_bright(x, y);
	}

	// go to the center of the screen, turn the beam off
	brightness(BRIGHT_OFF);

	goto_x(REST_X);
	goto_y(REST_Y);

	// the USB loop above will flush eventually
	digitalWriteFast(DEBUG_PIN, 0);
}

