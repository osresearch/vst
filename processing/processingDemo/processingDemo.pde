/** \file
 * Several different drawing demos.
 *
 * (c) 2016 Trammell Hudson, Adelle Lin and Jacob Joaquin
 */
Vst vst;
Demos demos;

void settings() {
  size(450, 550, P2D);  // Vectrex dimensions
  pixelDensity(displayDensity());
}

void setup() {
  frameRate(25);
  vst = new Vst(this, createSerial());
  //vst.displayTransit = true;
  blendMode(ADD);

  demos = new Demos();
  demos.add(new Demo3D());
  demos.add(new SwarmDemo());
  demos.add(new QixDemo());
  demos.add(new SpiralDemo());
  //demos.add(new DemoSVG("32c3_knot.svg"));
}

void draw() {
  background(0);
  demos.update();
  demos.display();
  vst.display();
}