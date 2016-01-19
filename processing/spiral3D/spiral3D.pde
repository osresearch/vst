Vst vst;
ArrayList<PVector> pvectors;

void settings() {
  size(500, 500, P3D);
  pixelDensity(displayDensity());
}

void setup() {
  frameRate(50);

  // Init Vst
  vst = new Vst(this, createSerial());
  vst.colorBright = color(220, 220, 255);
  vst.colorNormal = color(vst.colorBright, 96);
  blendMode(ADD);
  strokeWeight(1);
  stroke(255);

  // Create List of Points
  pvectors = new ArrayList<PVector>();
  int resolution = 128;
  float radius = 50;  
  float rotations = 6;
  float depth = 800;
  for (int i = 0; i < resolution; i++) {
    float n = i / (float) resolution;
    PVector p = PVector.fromAngle(n * TAU * rotations);
    p.mult(radius);
    p.z = n * depth - depth * 0.5;
    pvectors.add(p);
  }
}

void draw() {
  background(0);

  // Draw spiral
  pushMatrix();
  translate(width / 2.0, height / 2.0 + sin(frameCount % 200 / 200.0 * TAU) * 200);
  rotateY((frameCount % 200) / 200.0 * TAU);
  beginShape();
  for (PVector p : pvectors) {
    vertex(p.x, p.y, p.z);
  }
  endShape();  
  popMatrix();

  // Display();
  vst.display();
}