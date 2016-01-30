Vst vst;

void settings() {
  size(500, 500, P2D);
  pixelDensity(displayDensity());
}

void setup() {
  //vst = new Vst(this, createSerial());
  vst = new Vst(this);
  vst.displayTransit = true;
  frameRate(50);
}

void draw() {
  background(255);

  stroke(255);
  line(0, 0, width - 1, height - 1);
  stroke(127);
  line(width - 1, 0, 0, height - 1);

  //// Ellipse
  stroke(64);
  ellipse(250, 250, 200, 100);
  stroke(255);
  ellipse(250, 250, 100, 200);

  //// Rect + Transforms
  pushMatrix();
  translate(width / 2.0, height / 2.0);
  rectMode(CENTER);
  rotate(QUARTER_PI);
  stroke(255);
  rect(0, 0, 240, 200);
  stroke(64);
  rect(0, 0, 250, 210);
  popMatrix();

  //// Shape
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

  //// Interactivity with mouse
  stroke(255);
  rectMode(CENTER);  
  rect(mouseX, mouseY, 20, 20);

  // Display();
  vst.display();
}