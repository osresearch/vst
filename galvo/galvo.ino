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

#define timING 

void
setup()
{
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
	spi4teensy3::init(1);
#endif
}


static void
mpc4921_write(
	int channel,
	uint16_t value
)
{
	// assert the slave select pin
	if (channel == 0)
	{
		digitalWrite(SS_X, 0);
	} else {
		digitalWrite(SS_Y, 0);
	}

	value &= 0x0FFF; // mask out just the 12 bits of data
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


void
loop()
{
	for(float t = 0 ; t < 2*M_PI ; t += 0.01)
	{
		mpc4921_write(0, (sin(t) + 1) * 2047);
		mpc4921_write(1, (cos(t) + 1) * 2047);
	}
}

