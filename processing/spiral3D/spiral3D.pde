Vst vst;
ArrayList<PVector> pvectors;

void settings() {
  size(500, 500, P3D);
  pixelDensity(displayDensity());
}

void setup() {
  vst = new Vst(this, createSerial());
  frameRate(50);
  pvectors = new ArrayList<PVector>();
  
  
  // Create List of Points
  int resolution = 128;
  float depth = 800;
  float rotations = 6;
  float radius = 50;
  
  for (int i = 0; i < resolution; i++) {
    float n = i / (float) resolution;
    PVector p = PVector.fromAngle(n * TAU * rotations);
    p.mult(radius);
    p.z = n * depth - depth * 0.5;
    pvectors.add(p);
  }
}

void draw() {
  background(255);
  stroke(127);

  // Draw spiral
  pushMatrix();
  translate(width / 2.0, height / 2.0 + sin(frameCount % 200 / 200.0 * TAU) * 200);
  rotateY((frameCount % 200) / 200.0 * TAU);
  vst.beginShape();
  for (PVector p : pvectors) {
    vst.vertex(p.x, p.y, p.z);
  }
  vst.endShape();  
  popMatrix();

  // Display();
  vst.display();
}