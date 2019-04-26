Vst vst;
PVector gravity;
FireworkManager fireworkManager;

void settings() {
  size(500, 500, P2D);
  pixelDensity(displayDensity());
}

void setup() {
  vst = new Vst(this, createSerial());
  vst.colorStroke = color(64, 255, 64);
  //vst.displayTransit = true;
  gravity = new PVector(0, 0.01);
  fireworkManager = new FireworkManager();
  fireworkManager.trigger(new PVector(random(width), random(height)), (int) random(100, 300));
  frameRate(50);
  blendMode(ADD);
  strokeWeight(2);
}

void draw() {
  background(0, 24, 0);
  if (random(1.0) < 0.0125) {
    fireworkManager.trigger(new PVector(random(width), random(height)), (int) random(50, 200));
  }
  fireworkManager.update();
  fireworkManager.display();
  vst.display();
}