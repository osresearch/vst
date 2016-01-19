/** \file
 * MAME joystick built with a teensy 2.
 *
 * (Should redo this with a teensy3, maybe built it into the v.st board)
 *
 * Arrow keys
 * 5 
 * 1
 */

#define JOY_UP 2
#define JOY_DOWN 4
#define JOY_LEFT 3
#define JOY_RIGHT 1
#define FIRE 5
#define START 20
#define COIN 21

void setup()
{
	pinMode(JOY_UP, INPUT_PULLUP);
	pinMode(JOY_DOWN, INPUT_PULLUP);
	pinMode(JOY_LEFT, INPUT_PULLUP);
	pinMode(JOY_RIGHT, INPUT_PULLUP);
	pinMode(FIRE, INPUT_PULLUP);
	pinMode(START, INPUT_PULLUP);
	pinMode(COIN, INPUT_PULLUP);
}

void loop()
{
	int modifiers = 0;
	if (!digitalRead(JOY_UP))
		modifiers |= MODIFIERKEY_ALT;
	if (!digitalRead(FIRE))
		modifiers |= MODIFIERKEY_CTRL;
	Keyboard.set_modifier(modifiers);

	if (!digitalRead(JOY_DOWN))
		Keyboard.set_key1(KEY_SPACE);
	else
		Keyboard.set_key1(0);

	if (!digitalRead(JOY_LEFT))
		Keyboard.set_key2(KEY_LEFT);
	else
		Keyboard.set_key2(0);

	if (!digitalRead(JOY_RIGHT))
		Keyboard.set_key3(KEY_RIGHT);
	else
		Keyboard.set_key3(0);

	if (!digitalRead(START))
		Keyboard.set_key4(KEY_1);
	else
		Keyboard.set_key4(0);

	if (!digitalRead(COIN))
		Keyboard.set_key5(KEY_5);
	else
		Keyboard.set_key5(0);

	Keyboard.send_now();
}
