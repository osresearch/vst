/** \file
 * xswarm like demo
 */

boolean offscreen(float x, float y)
{
	if (x < 0 || x >= width || y < 0 || y >= height)
		return true;
	return false;
}

float limit(float x, float min, float max)
{
	if (x < min)
		return min;
	if (x > max)
		return max;
	return x;
}


class Particle
{
	Particle() {}

	float x = random(width);
	float y = random(height);
	float vx = 0;
	float vy = 0;
	final static float dt = 1;
	final static float max_a = 5;
	final static float max_v = 29;
	final static float max_wasp_v = 15;

	void bee_move(float tx, float ty)
	{
		float dx = tx - x;
		float dy = ty - y;

		float dist = sqrt(dx*dx + dy*dy);
		if (dist == 0)
			dist = 1;

		// adjust the accelerations up to the maximum
		// add some random noise to ensure that they don't bunch
		float dvx = (dx * max_a) / dist;
		float dvy = (dy * max_a) / dist;
		vx = limit(vx + dvx, -max_v, max_v) + random(-1,1);
		vy = limit(vy + dvy, -max_v, max_v) + random(-1,1);

		x += vx;
		y += vy;
	}

	void wasp_move()
	{
		// wasp is not acceleration limited
		vx = limit(vx + random(-5,5), -max_wasp_v, max_wasp_v);
		vy = limit(vy + random(-5,5), -max_wasp_v, max_wasp_v);

		// nudge the wasp towards the center of the screen
		if (x < width/2)
			vx += random(2);
		else
			vx -= random(2);

		if (y < height/2)
			vy += random(2);
		else
			vy -= random(2);

		x += vx;
		y += vy;

		if (x < 0 || x > width)
		{
			vx = -vx;
			x += 2*vx;
		}

		if (y < 0 || y > height)
		{
			vy = -vy;
			y += 2*vy;
		}
	}

	void draw(boolean bright)
	{
		// don't draw if either piece is offscreen
		if (offscreen(x,y) || offscreen(x - vx, y - vy))
			return;

		vector_line(bright, x, y, x - vx, y - vy);
	}
};

final int num_bees = 50;
Particle wasp;
Particle[] bees;
boolean wasp_follows_mouse = false;


void swarm_draw() {
  if (wasp == null)
  {
	wasp = new Particle();
	wasp.vx = 3;
	wasp.vy = 5;
	bees = new Particle[num_bees];
	for(int i = 0 ; i < num_bees; i++)
		bees[i] = new Particle();
  }

  background(0);
  strokeWeight(10);
  
  
  if (mousePressed)
     wasp_follows_mouse = !wasp_follows_mouse;

  // update the wasp with the mouse
  if (wasp_follows_mouse)
  {
    wasp.vx = mouseX - wasp.x;
    wasp.vy = mouseY - wasp.y;
    wasp.x = mouseX;
    wasp.y = mouseY;
  } else {
    wasp.wasp_move();
  }
  
  wasp.draw(true);

  // update the bees
  strokeWeight(5);
  for(Particle bee : bees)
  {
	bee.bee_move(wasp.x, wasp.y);
	bee.draw(false);
  }
	
}
