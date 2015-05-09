/** \file
 * RGB Laser projector driver.
 *
 * Drives two unipolar stepper motors and three PWM pulsed lasers.
 *
 * X pulse pattern: 0 1 2 3
 * Y pulse pattern: 4 5 7 6
 */

#include "stepper.h"
#include "laser.h"


void
lineto(
	int x1,
	int y1,
	uint8_t r,
	uint8_t g,
	uint8_t b
)
{
	laser_color(r,g,b);

	int x0 = stepper_x.pos;
	int y0 = stepper_y.pos;

	int dx;
	int dy;
	int sx;
	int sy;

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
			stepper_dir(&stepper_x, sx);
		}
		if (e2 < dx)
		{
			err = err + dx;
			y0 += sy;
			stepper_dir(&stepper_y, sy);
		}

		delayMicroseconds(600);

/*
		Serial.print(err);
		Serial.print(' ');
		Serial.print(stepper_x.pos);
		Serial.print(' ');
		Serial.print(stepper_y.pos);
		Serial.println();
*/
	}

	stepper_off();
	//laser_color(0,0,0);
}


void
setup(void)
{
	Serial.begin(115200);

	laser_setup();

	stepper_setup();
}



static void demo(void)
{
	lineto(16, 16, 0, 0, 0);

for(int i = 0 ; i < 30 ; i++)
{
	lineto(48, 16, 10, 0, 0);
	lineto(48, 48, 0, 10, 0);
	lineto(16, 16, 0, 0, 10);
}
	laser_color(0,0,0);
}

static uint8_t bright = 10;

void
loop(void)
{
	if (Serial.available())
	{
		int x = Serial.read();
		if (x == 'a')
			stepper_dir(&stepper_x, -1);
		else
		if (x == 'd')
			stepper_dir(&stepper_x, +1);
		else
		if (x == 's')
			stepper_dir(&stepper_y, -1);
		else
		if (x == 'w')
			stepper_dir(&stepper_y, +1);

		if (x == 'h')
		{
			stepper_home();
			return;
		}

		if (x == 'B')
		{
			demo();
			return;
		}

		if (x == 'r')
		{
			laser_color(bright, 0, 0);
			return;
		}
		if (x == 'g')
		{
			laser_color(0, bright, 0);
			return;
		}
		if (x == 'b')
		{
			laser_color(0, 0, bright);
			return;
		}
		if (x == ' ')
		{
			laser_color(0,0,0);
			return;
		} 
		if (x == '+')
		{
			bright++;
			return;
		}
		if (x == '-')
		{
			bright--;
			return;
		}
	}

	Serial.print(bright);
	Serial.print(' ');
	Serial.print(stepper_x.pos);
	Serial.print(' ');
	Serial.print(stepper_y.pos);
	Serial.println();
	delay(10);
	stepper_off();
}
