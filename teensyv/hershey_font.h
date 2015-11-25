#ifndef _hershey_h_
#define _hershey_h_

#include <stdint.h>

typedef struct
{
	uint8_t count;
	uint8_t width;
	int8_t points[62]; // up to 31 xy points
} hershey_char_t;

#ifdef __cplusplus
extern "C" {
#endif

extern const hershey_char_t hershey_simplex[];

#ifdef __cplusplus
}
#endif

#endif
