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
setup(void)
{
	Serial.begin(115200);

	laser_setup();

	stepper_setup();
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
