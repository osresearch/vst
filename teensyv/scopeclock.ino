/** \file
 * Clock for vector displays.
 *
 * More info: https://trmm.net/V.st
 *
 */

const int cx = 1024;
const int cy = 1024;

void
draw_hand(
	float a,
	int r,
	int hw
)
{
	const float sh = sin(a * M_PI/180);
	const float ch = cos(a * M_PI/180);

	if (hw == 0)
	{
		moveto(cx + r*sh*3/4,cy + r*ch*3/4);
		lineto(cx + r*sh, cy + r*ch);
	} else {
		//moveto(cx-hw*sh, cy-hw*ch);
		moveto(cx-hw*ch, cy+hw*sh);
		lineto(cx+r*sh, cy+r*ch);
		lineto(cx+hw*ch, cy-hw*sh);
		//lineto(cx-hw*sh, cy-hw*ch);
	}
}


void
draw_ymd(
	int year,
	int m,
	int d,
	int x,
	int y,
	int size
)
{
	char t[16];
	t[0] = '0' + (year / 1000) % 10;
	t[1] = '0' + (year / 100) % 10;
	t[2] = '0' + (year / 10) % 10;
	t[3] = '0' + (year / 1) % 10;
	t[4] = '/';
	t[5] = '0' + m / 10;
	t[6] = '0' + m % 10;
	t[7] = '/';
	t[8] = '0' + d / 10;
	t[9] = '0' + d % 10;
	t[10] = '\0';
	draw_string(t, x, y, size);
}


void
draw_hms(
	int h,
	int m,
	int s,
	int x,
	int y,
	int size
)
{
	char t[16];
	t[0] = '0' + h / 10;
	t[1] = '0' + h % 10;
	t[2] = ':';
	t[3] = '0' + m / 10;
	t[4] = '0' + m % 10;
	t[5] = ':';
	t[6] = '0' + s / 10;
	t[7] = '0' + s % 10;
	t[8] = '\0';

	draw_string(t, x, y, size);
}


void
scopeclock_analog()
{
	if (timeStatus()!= timeSet) {
		draw_string("time invalid: unable to sync", 0, 0, 8);
	}

	const int rh = 900;
	const int r1 = 950;
	const int r2 = 1000;

	for(int t = 0 ; t < 360 ; t += 6)
	{
		const float st = sin(t*M_PI/180);
		const float ct = cos(t*M_PI/180);

		if (t == 0)
		{
			// twelve o'clock
			moveto(cx + st*rh - 20, cy + ct*rh);
			lineto(cx + st*r2 - 20 , cy + ct*r2);
			lineto(cx + st*r2 + 20 , cy + ct*r2);
			lineto(cx + st*rh + 20, cy + ct*rh);
			lineto(cx + st*rh - 20, cy + ct*rh);
		} else
		if (t % 30 == 0)
		{
			// normal hour
			moveto(cx + st*rh, cy + ct*rh);
			lineto(cx + st*r2, cy + ct*r2);

			int h = t / 15;
			char t[3] = { '0' + h / 10, '0' + h % 10, '\0' };
			draw_string(t,
				cx + st*(r1-150) - 12*6,
				cy + ct*(r1-150) - 2*6,
				6);
		} else {
			// normal second/minute marker
			moveto(cx + st*r1, cy + ct*r1);
			lineto(cx + st*r2, cy + ct*r2);
		}
	}

	const int h = hour();
	const int m = minute();
	const int s = second();
	static int last_sec;
	static int last_millis;


	// track the millis of the rollover to the next second
	if (last_sec != s)
	{
		last_millis = millis();
		last_sec = s;
	}
	const int ms = (millis() - last_millis) % 1000;

	draw_hand((h*60 + m) * 15 / 60.0, rh/2, 50);
	draw_hand((m*60 + s) * 6 / 60.0, rh, 50);
	draw_hand((s*1000 + ms) * 6 / 1000.0, 1023, 0);

	const int y_off = 768-20 + (h*60 + m) * 512 / (24*60);
	//const int y_off = 768-20 + (s*1000 + ms) * 512 / (60000);

	draw_ymd(year(), month(), day(), 0, 0, 5);
	draw_hms(h,m,s, cx - 12*10*4, 700, 10);
	draw_string(dayStr(weekday()), 1500, 0, 5);
}


void
scopeclock_digital()
{
	if (timeStatus()!= timeSet) {
		draw_string("unable to sync", 0, 1024, 8);
		return;
	}

	char t[32];

	const int y_off = hour() * 60 + minute();

	draw_hms(hour(), minute(), second(), 16, 256+y_off, 21);
	draw_ymd(year(), month(), day(), 64, 0+y_off, 16);


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
	if (0)
		scopeclock_digital();
	else
		scopeclock_analog();

	num_points = rx_points;
	rx_points = 0;
}
