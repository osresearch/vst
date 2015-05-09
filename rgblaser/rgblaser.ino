/** \file
 * RGB Laser projector driver.
 *
 * Drives two unipolar stepper motors and three PWM pulsed lasers.
 */


static uint16_t pos_x = 0;
static uint16_t pos_y = 0;


static inline void
stepper_x(
	uint8_t x
)
{
	// shuffle the bits abcd -> 000ab0cd
	x = (x & 0x3) << 3 | (x & 0xC) << 4;
	GPIOC_PDOR = x;
}


static inline void
stepper_y(
	uint8_t y
)
{
	// shuffle the bits: abcd -> 00abc00d
	y = (y & 0x7) << 2 | (y & 0x8) << 4;
	GPIOD_PDOR = y;
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
}

#define RED_PIN 21
#define GREEN_PIN 20
#define BLUE_PIN 22


static void
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


static void
laser_setup(void)
{
	pinMode(RED_PIN, OUTPUT);
	pinMode(GREEN_PIN, OUTPUT);
	pinMode(BLUE_PIN, OUTPUT);

	laser_color(0,0,0);
}


void
setup(void)
{
	Serial.begin(115200);

	laser_setup();

	stepper_setup();
	stepper_x(0);
	stepper_x(1);
}


static uint8_t bright = 10;

void
loop(void)
{
	if (Serial.available())
	{
		int x = Serial.read();
		if ('0' <= x && x <= '7')
		{
			x = x - '0';
			if (x < 4)
				stepper_x(1 << x);
			else
				stepper_y(1 << (x-4));

			delay(2);
			stepper_x(0);
			stepper_y(0);
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
	Serial.print(pos_x);
	Serial.print(' ');
	Serial.print(pos_y);
	Serial.println();
	delay(10);
}
