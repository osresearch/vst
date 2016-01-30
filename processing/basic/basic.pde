Vst vst;

void settings() {
  size(500, 500, P2D);
  pixelDensity(displayDensity());
}

void setup() {
  vst = new Vst(this, createSerial());
  frameRate(50);
}

void draw() {
  background(0);
  vst.line(128, 125, 125, 375, 375);
  vst.line(128, 125, 375, 375, 125);
  rectMode(CORNER);
  vst.rect(128, 0, 0, width - 1, height - 1);
  rectMode(CENTER);
  vst.rect(128, width / 2.0, height / 2.0, 250, 250);
  vst.rect(255, mouseX, mouseY, 20, 20);  
  vst.display();
}
