#ifndef _rgblaser_stepper_h_
#define _rgblaser_stepper_h_

#include <stdint.h>

struct stepper_t {
	int pos;
	uint8_t phase;
	uint8_t steps[8];
};

extern stepper_t stepper_x, stepper_y;


extern void
stepper_off(void);

extern void
stepper_dir(
	stepper_t * const stepper,
	int dir
);


extern void
stepper_home(void);


extern void
stepper_setup(void);


#endif
