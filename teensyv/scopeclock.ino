/** \file
 * Clock for vector displays.
 *
 * More info: https://trmm.net/V.st
 *
 */

void
scopeclock_digital()
{
	if (timeStatus()!= timeSet) {
		draw_string("unable to sync", 0, 1024, 8);
		return;
	}

	char t[32];

	const int y_off = hour() * 60 + minute();
	{
		int h = hour();
		int m = minute();
		int s = second();
		t[0] = '0' + h / 10;
		t[1] = '0' + h % 10;
		t[2] = ':';
		t[3] = '0' + m / 10;
		t[4] = '0' + m % 10;
		t[5] = ':';
		t[6] = '0' + s / 10;
		t[7] = '0' + s % 10;
		t[8] = '\0';
		draw_string(t, 16, 256 + y_off, 21);
	}

	{
		int y = year();
		int m = month();
		int d = day();
		t[0] = '0' + (y / 1000) % 10;
		t[1] = '0' + (y / 100) % 10;
		t[2] = '0' + (y / 10) % 10;
		t[3] = '0' + (y / 1) % 10;
		t[4] = '/';
		t[5] = '0' + m / 10;
		t[6] = '0' + m % 10;
		t[7] = '/';
		t[8] = '0' + d / 10;
		t[9] = '0' + d % 10;
		t[10] = '\0';
		draw_string(t, 64, 0 + y_off, 16);
	}

	static int px = 0;
	static int py = 0;
	static int vx = 2;
	static int vy = 3;

	draw_string("http://v.st/", px, py, 8);

	px += vx;
	py += vy;
	if (px < 0)
	{
		px = 0;
		vx = -vx;
	} else
	if (px > 2048 - 8*12*12)
	{
		px = 2048 - 8*12*12;
		vx = -vx;
	}

	if (py < 0)
	{
		py = 0;
		vy = -vy;
	} else
	if (py > 2048 - 8*16)
	{
		py = 2048 - 8*16;
		vy = -vy;
	}

	//_circle(1024, 1024, 300, 0);
	//_circle(1024, 1024, 300, 1);
	//_circle(1024, 1024, 300, 2);
}


void
scopeclock()
{
	rx_points = 0;
	scopeclock_digital();
	num_points = rx_points;
	rx_points = 0;
}
