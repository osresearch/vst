/** \file
 * Interface to the RGB laser PWM circuit.
 */
#include "laser.h"

#define RED_PIN 21
#define GREEN_PIN 20
#define BLUE_PIN 22


void
laser_color(
	uint8_t r,
	uint8_t g,
	uint8_t b
)
{
	analogWrite(RED_PIN, r);
	analogWrite(GREEN_PIN, g);
	analogWrite(BLUE_PIN, b);
}


void
laser_setup(void)
{
	pinMode(RED_PIN, OUTPUT);
	pinMode(GREEN_PIN, OUTPUT);
	pinMode(BLUE_PIN, OUTPUT);

	laser_color(0,0,0);
}
