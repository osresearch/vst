/** \file
 * "Tennis for Two", for vector monitors.
 */

import net.java.games.input.*;
import org.gamecontrolplus.*;
//import org.gamecontrolplus.gui.*;

ControlIO control;
Configuration config;
ControlDevice joystick;
ControlSlider angle_1;
ControlSlider angle_2;
ControlButton serve_1;
ControlButton serve_2;

int winner;
int server; // who has the return
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
final float decay = 0.9;

void setup() {
	vector_setup();
  
	size(512, 512);
	surface.setResizable(true);

	frameRate(25);

	ball_reset(random(45,60), random(10,20));

	control = ControlIO.getInstance(this);
	println(control.deviceListToText(""));
	//println(control.devicesToText(""));
	joystick = control.getDevice(3);
	println(joystick.toText(""));

	if (joystick != null)
	{
		angle_1 = joystick.getSlider("y");
		angle_2 = joystick.getSlider("rz");
		serve_1 = joystick.getButton(8);
		serve_2 = joystick.getButton(9);
	}

}


void ball_angle(float a, float v)
{
	vx = cos(a * 3.14 / 180) * v;
	vy = sin(a * 3.14 / 180) * v;
}


float joy2angle(ControlSlider s)
{
	float v = s == null ? 0 : s.getValue();

	// v goes from -1 to 1.
	// we want -15 to 60
	return v * 45 + 30;
}


void ball_reset(float a, float v)
{
	bx = -net_width + 0.1;
	by = 1;

	ball_angle(a, v);
	server = 2;

	if (winner == 2)
	{
		server = 1;
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
	// bounce backwards off the net
	// and select a winner.
	if (by < net_height)
	{
		if ((bx < 0 && 0 < bx + vx*dt)
		||  (bx + vx*dt < 0 && 0 < bx))
		{
			vx = -vx;

			if (winner == 0)
				winner = bx > 0 ? 1 : 2;
		}
	}

	// check for bouncing off the ground (at y position 0)
	if (by + vy * dt < 0)
	{
		bounces++;

		// first bounce on the same side as the server?
		// they loose.  Server says whose turn it is to
		// return, so they will be the one to win.
		if (bounces == 1 && winner == 0)
		{
			if (bx < 0 && server == 2)
				winner = 2;
			else
			if (bx > 0 && server == 1)
				winner = 1;
		}

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
	{
		float a = joy2angle(angle_1) * 3.14/180;;
		vector_line(true,
			width/2 - net_width * scale, y_offset - scale,
			width/2 - net_width * scale + cos(a) * 20, y_offset - scale - sin(a) * 20
		);
	} else
	if (winner == 2)
	{
		float a = joy2angle(angle_2) * 3.14/180;;
		vector_line(true,
			width/2 + net_width * scale, y_offset - scale,
			width/2 + net_width * scale - cos(a) * 20, y_offset - scale- sin(a) * 20
		);
	}

	float v = sqrt(vx*vx+vy*vy);

	// check for a button press when the ball is on the correct side
	// and we don't already have a winner.
	if (server == 1 && serve_1 != null && serve_1.pressed())
	{
		// this is only valid if the ball has reached our side
		if (winner == 0 && bx < 0)
		{
			float a = joy2angle(angle_1);
			ball_angle(a, v);
			server = 2;
			bounces = 0;
		}
	}

	if (server == 2 && serve_2 != null && serve_2.pressed())
	{
		if (winner == 0 && bx > 0)
		{
			float a = joy2angle(angle_2);
			ball_angle(a, v);
			vx = -vx;
			server = 1;
			bounces = 0;
		}
	} 

	// check for the winner to send a new serve
	if (winner == 1 && serve_1 != null && serve_1.pressed())
	{
		float a = joy2angle(angle_1);
		ball_reset(a, random(10,20));
	}

	if (winner == 2 && serve_2 != null && serve_2.pressed())
	{
		float a = joy2angle(angle_2);
		ball_reset(a, random(10,20)); // flip will be done
	}


	vector_send();
}
