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
Vst vst;

void setup() {
    vst = new Vst(this, createSerial());
    vst.displayTransit = true;

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

    vst.display();
}