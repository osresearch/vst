Vst vst;
Qix qix;
PVector gravity;
FireworkManager fireworkManager;

void settings() {
  size(500, 500, P2D);
  pixelDensity(displayDensity());
}

void setup() {
  vst = new Vst(createSerial());
  qix = new Qix(vst);
  gravity = new PVector(0, 0.01);
  fireworkManager = new FireworkManager();
  fireworkManager.trigger(new PVector(random(width), random(height)), (int) random(100, 300));
  
  frameRate(50);
  blendMode(ADD);
  noFill();
  stroke(64, 255, 64);
  strokeWeight(2);
}

void draw() {
  background(0);
  //qix.update();
  //qix.display();
  //demo3d_draw();

  if (random(1.0) < 0.05) {
    fireworkManager.trigger(new PVector(random(width), random(height)), (int) random(50, 200));
  }
  fireworkManager.update();
  fireworkManager.display();

  vst.display();
}