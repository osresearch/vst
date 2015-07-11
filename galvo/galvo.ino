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
	Serial.begin(9600);
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



// x and y position are in 11-bit range
static uint16_t x_pos;
static uint16_t y_pos;

static inline void
goto_x(
	uint16_t x
)
{
	mpc4921_write(1, x << 1);
}

static inline void
goto_y(
	uint16_t y
)
{
	mpc4921_write(0, y << 1);
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

	Serial.print("----- read: ");
	Serial.println(c);

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

		Serial.print("*** fb");
		Serial.print(fb);
		Serial.print(" ");
		Serial.println(num_points);
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

	for(int n = 0 ; n < num_points ; n++)
	{
		if (Serial.available())
		{
			for (int j = 0 ; j < 32 ; j++)
			{
				int rc = read_data();
				if (rc < 0)
					break;

				// buffer switch!
				if (rc == 1)
					; //return;
			}
		}

		const uint16_t * const pt = points[fb][n];
		uint16_t x = pt[0];
		uint16_t y = pt[1];
		unsigned intensity = (x >> 11) & 0x3;
		x &= 0x7FF;
		y &= 0x7FF;

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

			goto_x(x);
			goto_y(y);
			x_pos = x;
			y_pos = y;
			continue;
		}

		digitalWrite(RED_PIN, 1);
		if (intensity == 2)
			lineto(x, y);
		else
			lineto_bright(x, y);
	}
}

