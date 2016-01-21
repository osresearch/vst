/** \file
 * Several different drawing demos.
 *
 * (c) 2016 Trammell Hudson, Adelle Lin and Jacob Joaquin
 */

Vst vst;
DemoList demos;

void settings() {
  size(450, 550, P2D);  // Vectrex dimensions
  //size(500, 500, P2D);  // Square
  pixelDensity(displayDensity());
}

void setup() {
  frameRate(25);
  vst = new Vst(this, createSerial());
  vst.colorBright = color(220, 220, 255);
  vst.colorNormal = color(vst.colorBright, 96);
  vst.colorTransit = color(255, 0, 0, 180);
  vst.displayTransit = true;
  blendMode(ADD);

  demos = new DemoList();
  demos.add(new Demo3D());
  demos.add(new SwarmDemo());
  demos.add(new QixDemo());
  demos.add(new SpiralDemo());
}

void draw() {
  background(0);
  demos.update();
  demos.display();
  vst.display();
}