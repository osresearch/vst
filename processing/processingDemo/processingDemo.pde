/** \file
 * Several different drawing demos.
 *
 * (c) 2016 Trammell Hudson, Adelle Lin and Jacob Joaquin
 */

class Demo
{
	void draw() {}
}


ArrayList<Demo> demos;
int frame_count = 0;
Demo d;
Vst v;

void setup() {
    v = new Vst(this, createSerial());
    v.displayTransit = true;

    size(1024, 1200, P2D);
    surface.setResizable(true);

    blendMode(ADD);
    noFill();
    stroke(212, 128, 32, 128);

    frameRate(25);

    demos = new ArrayList<Demo>();
   
    demos.add(new Demo3D());
    demos.add(new SwarmDemo());
    demos.add(new QixDemo());
    //demos.add(new SpiralDemo());

    d = demos.get(0);
}


void draw() {
    if (frame_count++ > 1000)
    {
        frame_count = 0;
        d = demos.get((int) random(demos.size()));
    }
    
    d.draw();

    v.display();
}


void line(PVector p0, PVector p1)
{
	if (p0 == null || p1 == null)
		return;

	line(p0.x, p0.y, p1.x, p1.y);
}

void line(float x0, float y0, float x1, float y1)
{
        if (v.send_to_display)
	{
		super.line(x0, y0, x1, y1);
		return;
	}

	int s = g.strokeColor;
	boolean bright = red(s) == 255 && green(s) == 255 && blue(s) == 255;
	v.line(bright, x0, y0, x1, y1);
}


void ellipse(float x, float y, float rx, float ry)
{
	// Deduce how long r is in real pixels
        float r = abs(modelX(0,0,0) - modelX((rx+ry),0,0));
	int steps = (int)(r / 5);
	float dtheta = 2 * PI / steps;
	float theta = dtheta;
	float x0 = rx;
	float y0 = 0;

	for(int i = 0 ; i < steps ; i++, theta += dtheta)
	{
		float x1 = rx * cos(theta);
		float y1 = ry * sin(theta);
		line(x + x0, y + y0, x + x1, y + y1);
		x0 = x1;
		y0 = y1;
	}
}
