/** \file
 * Galvo based driver using the MCP4921 DAC.
 *
 * Interrupt driven SPI from a buffer to continuous line drawing.
 */
#ifdef SLOW_SPI
#include <SPI.h>
#else
#include "spi4teensy3.h"
#endif

#define SS_X	9
#define SS_Y	10
#define SDI	11
#define SCK	13

#define RED_PIN	3

void
setup()
{
	pinMode(RED_PIN, OUTPUT);
	digitalWrite(RED_PIN, 0);

	pinMode(SS_X, OUTPUT);
	pinMode(SS_Y, OUTPUT);
	pinMode(SDI, OUTPUT);
	pinMode(SCK, OUTPUT);

	// slave select pins are high
	digitalWrite(SS_X, 1);
	digitalWrite(SS_Y, 1);

#ifdef SLOW_SPI
	SPI.begin();
	SPI.setClockDivider(SPI_CLOCK_DIV2);
#else
	spi4teensy3::init(0);
	//spi4teensy3::init(1);
#endif
}


static void
mpc4921_write(
	int channel,
	uint16_t value
)
{
	value &= 0x0FFF; // mask out just the 12 bits of data

	// assert the slave select pin
	if (channel == 0)
	{
		digitalWrite(SS_X, 0);
	} else {
		digitalWrite(SS_Y, 0);
	}

	value |= 3 << 12; // disable shutdown
#ifdef SLOW_SPI
	SPI.transfer((value >> 8) & 0xFF);
	SPI.transfer((value >> 0) & 0xFF);
#else
	uint8_t buf[2] = { value >> 8, value >> 0 };
	spi4teensy3::send(buf, sizeof(buf));
#endif

	// de-assert the slave select pin
	if (channel == 0)
	{
		digitalWrite(SS_X, 1);
	} else {
		digitalWrite(SS_Y, 1);
	}
}



static uint16_t x_pos;
static uint16_t y_pos;

static inline void
goto_x(
	uint16_t x
)
{
	mpc4921_write(0, x<<2);
}

static inline void
goto_y(
	uint16_t y
)
{
	mpc4921_write(1, y<<2);
}

void
lineto(
	int x1,
	int y1
)
{
	int dx;
	int dy;
	int sx;
	int sy;

	int x0 = x_pos;
	int y0 = y_pos;

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
			goto_x(x0);
		}
		if (e2 < dx)
		{
			err = err + dx;
			y0 += sy;
			mpc4921_write(1, y0<<2);
		}
	}

	x_pos = x0;
	y_pos = y0;
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
read_point(
	uint16_t * x_ptr,
	uint16_t * y_ptr
)
{
	if (!Serial.available())
		return -1;

	uint16_t x_hi = read_blocking();
	uint16_t x_lo = read_blocking();
	uint16_t y_hi = read_blocking();
	uint16_t y_lo = read_blocking();

	uint16_t x = ((x_hi << 8) | x_lo) & 0xFFF;
	uint16_t y = ((y_hi << 8) | y_lo) & 0xFFF;
	*x_ptr = x;
	*y_ptr = y;

	// return the top four bits of the x coord for the intensity
	return x_hi >> 4;
}


void
loop()
{
	while(1)
	{
		uint16_t x, y;
		int intensity = read_point(&x,&y);
		if (intensity < 0)
			continue;

		if (intensity == 0)
		{
			goto_x(x);
			goto_y(y);
			x_pos = x;
			y_pos = y;
			continue;
		}

		digitalWrite(RED_PIN, 1);
		lineto(x, y);
		digitalWrite(RED_PIN, 0);
	}
}

