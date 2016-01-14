/** \file
 * xswarm like demo
 */

class Particle
{
	Particle() {}
	PVector p = new PVector(random(width), random(height));
	PVector v = new PVector(0,0);

	final static float dt = 1;
	final static float max_a = 5;
	final static float max_v = 29;
	final static float max_wasp_v = 15;

	void bee_move(PVector t)
	{
		PVector d = PVector.sub(t, p);

		float dist = d.mag();
		if (dist == 0)
			dist = 1;

		// adjust the accelerations up to the maximum
		// add some random noise to ensure that they don't bunch
		PVector dv = PVector.mult(d, max_a / dist);
		dv.x += random(-2,2);
		dv.y += random(-2,2);
		dv.z += random(-2,2);
		v.add(dv);
		v.limit(max_v);
		p.add(v);
	}

	void wasp_move()
	{
		// wasp is not acceleration limited
		v.x += random(-5,5);
		v.y += random(-5,5);
		v.z += random(-5,5);
		v.limit(max_wasp_v);

		// nudge the wasp towards the center of the screen
		if (p.x < width/2)
			v.x += random(2);
		else
			v.x -= random(2);

		if (p.y < height/2)
			v.y += random(2);
		else
			v.y -= random(2);

		if (p.z < height/2)
			v.z += random(2);
		else
			v.z -= random(2);

		p.add(v);

		// bounce the wasp off the corner of the screen
		if (p.x < 0 || p.x > width)
			v.x = -v.x;

		if (p.y < 0 || p.y > height)
			v.y = -v.y;

		if (p.z < 0 || p.z > height)
			v.z = -v.z;
	}

	void draw(boolean bright)
	{
		PVector p2 = PVector.sub(p,v);
		stroke(bright ? 255 : 100);
		line(p, p2);
	}
};


class SwarmDemo extends Demo
{
final int num_bees = 50;
Particle wasp;
Particle[] bees;
boolean wasp_follows_mouse = false;


SwarmDemo()
{
	wasp = new Particle();
	bees = new Particle[num_bees];
	for(int i = 0 ; i < num_bees; i++)
		bees[i] = new Particle();
}

void draw() {
  background(0);
  strokeWeight(10);
  
  
  if (mousePressed)
     wasp_follows_mouse = !wasp_follows_mouse;

  // update the wasp with the mouse
  if (wasp_follows_mouse)
  {
    wasp.v.x = mouseX - wasp.p.x;
    wasp.v.y = mouseY - wasp.p.y;
    wasp.p.x = mouseX;
    wasp.p.y = mouseY;
  } else {
    wasp.wasp_move();
  }
  
  wasp.draw(true);

  // update the bees
  strokeWeight(5);
  for(Particle bee : bees)
  {
	bee.bee_move(wasp.p);
	bee.draw(false);
  }

}
}
