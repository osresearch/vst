/** \file
 * Dual unipolar stepper driver for the teensy 3.
 *
 * Uses four contiguous pins mapped in port C and another four in port D.
 *
 * Implements half steps.
 */
#include "stepper.h"
#include "core_pins.h" // for teensy GPIO definitions

// Map the stepper phases to the pin outs
#define STEPPER_X(A1,B1,A2,B2) \
	( (A1 << 3) | (B1 << 4) | (A2 << 6) | (B2 << 7) )

#define STEPPER_Y(A1,B1,A2,B2) \
	( (A1 << 2) | (B1 << 3) | (A2 << 7) | (B2 << 4) )


stepper_t stepper_x = {
	0,
	0,
	{
		STEPPER_X(1,0,0,1),
		STEPPER_X(1,0,0,0),
		STEPPER_X(1,1,0,0),
		STEPPER_X(0,1,0,0),
		STEPPER_X(0,1,1,0),
		STEPPER_X(0,0,1,0),
		STEPPER_X(0,0,1,1),
		STEPPER_X(0,0,0,1),
	},
};


stepper_t stepper_y = {
	0,
	0,
	{
		STEPPER_Y(1,0,0,1),
		STEPPER_Y(1,0,0,0),
		STEPPER_Y(1,1,0,0),
		STEPPER_Y(0,1,0,0),
		STEPPER_Y(0,1,1,0),
		STEPPER_Y(0,0,1,0),
		STEPPER_Y(0,0,1,1),
		STEPPER_Y(0,0,0,1),
	},
};



static inline void
stepper_write(
	const stepper_t * const stepper,
	uint8_t x
)
{
	if (stepper == &stepper_x)
		GPIOC_PDOR = stepper->steps[x % 8];
	else
	if (stepper == &stepper_y)
		GPIOD_PDOR = stepper->steps[x % 8];
}


void
stepper_off(void)
{
	GPIOD_PDOR = 0;
	GPIOC_PDOR = 0;
}


void
stepper_dir(
	stepper_t * const stepper,
	int dir
)
{
	stepper_write(stepper, stepper->phase += dir);
	stepper->pos += dir;
}


void
stepper_home(void)
{
	for (int i = 0 ; i < 200 ; i++)
	{
		stepper_dir(&stepper_x, -1);
		stepper_dir(&stepper_y, -1);
		delay(5);
	}

	stepper_off();
	stepper_x.pos = 0;
	stepper_y.pos = 0;
}


void
stepper_setup(void)
{
	// the pins are mapped oddly, so we have an array of them.
	// these are contiguous in ports C and D and will be written
	// with a single instruction
	static const uint8_t pins[] = {
		5, 6, 7, 8, 9, 10, 11, 12
	};

	for(unsigned i = 0 ; i < sizeof(pins)/sizeof(*pins) ; i++)
	{
		pinMode(pins[i], OUTPUT);
		digitalWrite(pins[i], 0);
	}

	stepper_off();
}

