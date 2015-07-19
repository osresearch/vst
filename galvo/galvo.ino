/** \file
 * Vector display using the MCP4921 DAC.
 *
 * format of commands is 3-bytes per command.
 * 2 bits
 *  00 == number of lines to be sent
 *  01 == "pen up" move to new X,Y
 *  10 == normal line to X,Y
 *  11 == bright line to X,Y
 * 11 bits of X (or number of lines)
 * 11 bits of Y
 */
#include <SPI.h>
//#include "DmaSpi.h"
#include "DMAChannel.h"

#define SS_PIN	10
#define SS2_PIN	9
#define SDI	11
#define SCK	13

#define RED_PIN	3
#define DEBUG_PIN	4

static DMAChannel spi_dma;

static void
spi_setup()
{
	spi_dma.disable();
	spi_dma.destination((volatile uint32_t&) SPI0_PUSHR);
	spi_dma.disableOnCompletion();
	spi_dma.triggerAtHardwareEvent(DMAMUX_SOURCE_SPI0_TX);
	spi_dma.transferSize(4);

	SPI.beginTransaction(SPISettings(20000000, MSBFIRST, SPI_MODE0));

	// configure the output for SS0 pin
	//SPI0_PUSHR = (SPI0_PUSHR & ~0x801F0000) | (SPI.setCS(SS_PIN) << 16);
	CORE_PIN10_CONFIG = PORT_PCR_DSE | PORT_PCR_MUX(2);

	// configure the frame size for 16-bit transfers
	SPI0_CTAR0 |= 0xF << 27;
}


static void
spi_tx(
	const uint32_t * const buf,
	const unsigned len
)
{
	spi_dma.clearComplete();
	spi_dma.clearError();
	spi_dma.sourceBuffer(buf, len);

	SPI0_SR = 0xFF0F0000;
	SPI0_RSER = 0
		| SPI_RSER_RFDF_RE
		| SPI_RSER_RFDF_DIRS
		| SPI_RSER_TFFF_RE
		| SPI_RSER_TFFF_DIRS;

	spi_dma.enable();
}


static int
spi_tx_complete()
{
	if (!spi_dma.complete())
		return 0;

	spi_dma.clearComplete();

	// we are done!
	SPI0_RSER = 0;
	SPI0_SR = 0xFF0F0000;
	return 1;
}


void
setup()
{
	Serial.begin(9600);
	pinMode(RED_PIN, OUTPUT);
	pinMode(DEBUG_PIN, OUTPUT);
	digitalWrite(RED_PIN, 0);
	digitalWrite(DEBUG_PIN, 0);

	//pinMode(SS_PIN, OUTPUT);
	pinMode(SS2_PIN, OUTPUT);
	pinMode(SDI, OUTPUT);
	pinMode(SCK, OUTPUT);

	// slave select pins are high
	digitalWrite(SS2_PIN, 1);
	//digitalWrite(SS_PIN, 1);

#ifdef SLOW_SPI
	SPI.begin();
	SPI.setClockDivider(SPI_CLOCK_DIV2);
#else
	//spi4teensy3::init(0);
	SPI.begin();
	SPI.setClockDivider(SPI_CLOCK_DIV2);

	//DMASPI0.begin();
	//DMASPI0.start();
	spi_setup();

#endif
}


static inline uint32_t
spi_data(
	uint16_t value
)
{
	// enable the chip select line
	return 0
		| ((uint32_t) value)
		| (1 << 16)
		;
}


static void
mpc4921_write(
	int channel,
	uint16_t value
)
{
	value &= 0x0FFF; // mask out just the 12 bits of data

	// select the output channel, buffered, no gain
	if (channel == 1)
		value |= 0x7000;
	else
		value |= 0xF000;

#ifdef SLOW_SPI
	SPI.transfer((value >> 8) & 0xFF);
	SPI.transfer((value >> 0) & 0xFF);
#else
	static uint32_t buf[3];

	buf[0] = spi_data(value);
	buf[1] = spi_data(value);
	buf[2] = spi_data(value) | (1 << 27); // eoq

	//buf[0] = (value >> 8) & 0xFF;
	//buf[1] = (value >> 0) & 0xFF;

	// assert the slave select pin
	digitalWrite(SS2_PIN, 0);

	spi_tx(buf, sizeof(buf));

	while(!spi_tx_complete())
		;

	// de-assert the slave select pin
	digitalWrite(SS2_PIN, 1);
	//spi4teensy3::send(buf, sizeof(buf));
#endif
}




// x and y position are in 11-bit range
static uint16_t x_pos;
static uint16_t y_pos;

static inline void
goto_x(
	uint16_t x
)
{
	mpc4921_write(1, x);
}

static inline void
goto_y(
	uint16_t y
)
{
	mpc4921_write(0, y);
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

	int x_off = x1 & ((1 << bright_shift) - 1);
	int y_off = y1 & ((1 << bright_shift) - 1);
	x1 >>= bright_shift;
	y1 >>= bright_shift;
	int x0 = x_pos >> bright_shift;
	int y0 = y_pos >> bright_shift;

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
	}

	x_pos = x0 << bright_shift;
	y_pos = y0 << bright_shift;
}


void
lineto(
	int x1,
	int y1
)
{
	_lineto(x1, y1, 1);
}


void
lineto_bright(
	int x1,
	int y1
)
{
	_lineto(x1, y1, 0);
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


#define MAX_PTS 1024
static unsigned rx_points;
static unsigned num_points;
static unsigned fb;
static uint16_t points[2][MAX_PTS][2];
static unsigned do_resync;


static int
read_data()
{
	static uint32_t cmd;
	static unsigned offset;

	int c = Serial.read();
	if (c < 0)
		return -1;

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
		fb = !fb;
		num_points = rx_points;
		rx_points = 0;

		//Serial.print("*** fb");
		//Serial.print(fb);
		//Serial.print(" ");
		//Serial.println(num_points);
		return 1;
	}

	uint16_t * pt = points[!fb][rx_points++];
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

	read_data();

	digitalWrite(DEBUG_PIN, 1);

	for(unsigned n = 0 ; n < num_points ; n++)
	{
		if (Serial.available())
		{
			for (int j = 0 ; j < 8 ; j++)
			{
				int rc = read_data();
				if (rc < 0)
					break;

				// buffer switch!
				if (rc == 1)
				{
					digitalWrite(RED_PIN, 0);
					n = 0;
					;return;
				}
			}
		}

		const uint16_t * const pt = points[fb][n];
		uint16_t x = pt[0];
		uint16_t y = pt[1];
		unsigned intensity = (x >> 11) & 0x3;
		x = (x & 0x7FF) << 1;
		y = (y & 0x7FF) << 1;

#if 0
		Serial.print(x);
		Serial.print(' ');
		Serial.print(y);
		Serial.print(' ');
		Serial.println(intensity);
#endif

		if (intensity == 1)
		{
			digitalWrite(RED_PIN, 0);

			if (x == x_pos && y == y_pos)
				continue;

			int dx = x - x_pos;
			int dy = y - y_pos;
			int dist = dx*dx + dy*dy;

			//delayMicroseconds(10);
			goto_x(x);
			goto_y(y);
			//delayMicroseconds(sqrtf(dist) / 400);

			x_pos = x;
			y_pos = y;
			continue;
		}

		digitalWrite(RED_PIN, 1);
		if (intensity == 2)
			lineto(x, y);
		else
			lineto_bright(x, y);

		digitalWrite(DEBUG_PIN, 0);
	}
}

