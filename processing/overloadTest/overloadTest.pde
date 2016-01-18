Vst vst;

void settings() {
  size(500, 500, P2D);
  pixelDensity(displayDensity());
}

void setup() {
  vst = new Vst(this, createSerial());
  vst.colorBright = color(64, 255, 64);
  vst.colorNormal = color(vst.colorBright, 80);
  vst.displayTransit = true;
  frameRate(50);
  blendMode(ADD);
  strokeWeight(2);
  //noLoop();
}

void draw() {
  background(0);
  
  // Lines
  stroke(127);
  line(0, 0, width - 1, height - 1);
  stroke(255);
  line(width - 1, 0, 0, height - 1);

  // Ellipse
  stroke(127);
  ellipse(250, 250, 200, 100);
  stroke(255);
  ellipse(250, 250, 100, 200);
  rectMode(CENTER);

  // Rect + Transforms
  pushMatrix();
  translate(width / 2.0, height / 2.0);
  rotate(QUARTER_PI);
  stroke(255);
  rect(0, 0, 240, 200);
  stroke(127);
  rect(0, 0, 250, 210);
  popMatrix();
 
  // Shape
  int nPoints = 24;
  beginShape();
  for (int i = 0; i < nPoints; i++) {
    PVector p = PVector.fromAngle(i / (float) nPoints * TAU);
    p.mult(i % 2 == 0 ? 50 : 25);
    p.add(100, 100);
    stroke(i % 2 == 0 ? 255 : 127);
    vertex(p);
  }
  endShape(CLOSE);
  
  vst.display();
}