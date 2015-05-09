/** \file
 * RGB Laser projector driver.
 *
 * Drives two unipolar stepper motors and three PWM pulsed lasers.
 *
 * X pulse pattern: 0 1 2 3
 * Y pulse pattern: 4 5 7 6
 */


static uint16_t pos_x = 0;
static uint16_t pos_y = 0;

// Map the stepper phases to the pin outs
#define STEPPER_X(A1,B1,A2,B2) \
	( (A1 << 3) | (B1 << 4) | (A2 << 6) | (B2 << 7) )

#define STEPPER_Y(A1,B1,A2,B2) \
	( (A1 << 2) | (B1 << 3) | (A2 << 7) | (B2 << 4) )

static const uint8_t stepper_x_steps[] = {
	STEPPER_X(1,0,0,0),
	STEPPER_X(0,1,0,0),
	STEPPER_X(0,0,1,0),
	STEPPER_X(0,0,0,1),
};

static const uint8_t stepper_y_steps[] = {
	STEPPER_Y(1,0,0,0),
	STEPPER_Y(0,1,0,0),
	STEPPER_Y(0,0,1,0),
	STEPPER_Y(0,0,0,1),
};



static inline void
stepper_x(
	uint8_t x
)
{
	GPIOC_PDOR = stepper_x_steps[x];
}


static inline void
stepper_y(
	uint8_t y
)
{
	GPIOD_PDOR = stepper_y_steps[y];
}


static inline void
stepper_off(void)
{
	GPIOD_PDOR = 0;
	GPIOC_PDOR = 0;
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
}


static uint8_t bright = 10;

void
loop(void)
{
	if (Serial.available())
	{
		int x = Serial.read();
		if ('0' <= x && x <= '8')
		{
			x = x - '0';
			if (x < 5)
				stepper_x(x);
			else
				stepper_y(x - 5);

			delay(3);
			stepper_off();
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
