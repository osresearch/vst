/** \file
 * "Tennis for Two", for vector monitors.
 */

import net.java.games.input.*;
import org.gamecontrolplus.*;
import org.gamecontrolplus.gui.*;




int winner;
int bounces;
float bx;
float by;
float vx;
float vy;
final float dt = 1.0 / 25;
final float net_height = 2;
final float net_width = 10;
final float y_offset = 400;
final float scale = 20;
final float G = 9.81;
final float decay = 0.8;


void setup() {
	vector_setup();
  
	size(512, 512);
	surface.setResizable(true);

	frameRate(25);

	ball_reset();
}


void ball_angle(float a, float v)
{
	vx = cos(a * 3.14 / 180) * v;
	vy = sin(a * 3.14 / 180) * v;
}


void ball_reset()
{
	bx = -net_width + 0.1;
	by = 1;

	ball_angle(random(45,60), random(10,20));

	if (winner == 2)
	{
		bx = -bx;
		vx = -vx;
	}

	winner = 0;
	bounces = 0;
}

void ball_update()
{
	vx = vx; // no change
	vy = vy - G * dt; // gravity pulls us all down

	// check for hitting the net (at x position 0)
	if (by < net_height)
	{
		if ((bx < 0 && 0 < bx + vx*dt)
		||  (bx + vx*dt < 0 && 0 < bx))
		{
			// bounce backwards off the net
			// and select a winner
			vx = -vx;

			if (winner == 0)
				winner = bx > 0 ? 1 : 2;
		}
	}

	// check for bouncing off the ground (at y position 0)
	if (by + vy * dt < 0)
	{
		// we can ignore the first bounce; it will be caught
		// if out of bounds
		bounces++;

		// on the second bounce, if we haven't already assigned
		// a winner then we have a new winner (the side the ball
		// is not on)
		if (bounces > 1 && winner == 0)
		{
			winner = bx > 0 ? 1 : 2;
		}

		vy = -vy * decay; // lose some energy on each bounce
	}

	// if the ball goes out of bounds and we don't have a winner,
	// the winner depends on the number of bounces. one bounce ==
	// server was the winner.  no bounces == receiver was winner.
	if (bx < -net_width || net_width < bx)
	{
		if (winner != 0)
		{
			// we have already assigned the winner
		} else
		if (bounces == 0)
		{
			// no bounces, so this went high
			winner = bx > 0 ? 2 : 1;
		} else {
			// at least one bounce, so this was in bounds
			winner = bx > 0 ? 1 : 2;
		}
	}

	// update the location
	bx = bx + vx * dt;
	by = by + vy * dt;
}


void net_draw()
{
	vector_line(false,
		width/2 - net_width * scale, y_offset,
		width/2 + net_width * scale, y_offset);

	vector_line(false,
		width/2, y_offset,
		width/2, y_offset - net_height * scale);
}

void ball_draw()
{
	// remember that our Y axis is inverted (0 at the top)
	float x0 = width/2 + bx * scale;
	float y0 = y_offset - by * scale;
	float x1 = x0 + vx;
	float y1 = y0 - vy;

	vector_line(true, x0, y0, x1, y1);
}

void draw()
{
	net_draw();
	ball_update();
	ball_draw();

	if (winner == 1)
		vector_line(true,
			width/4, y_offset + 10,
			width/3, y_offset + 10);
	else
	if (winner == 2)
		vector_line(true,
			width - width/4, y_offset + 10,
			width - width/3, y_offset + 10);


	vector_send();
}

void mouseClicked()
{
	if (winner == 0)
		return;
	ball_reset();
}
