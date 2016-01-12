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
  background(255);
  vst.line(false, 125, 125, 375, 375);
  vst.line(false, 125, 375, 375, 125);
  rectMode(CORNER);
  vst.rect(false, 0, 0, width - 1, height - 1);
  rectMode(CENTER);
  vst.rect(false, width / 2.0, height / 2.0, 250, 250);
  vst.rect(true, mouseX, mouseY, 20, 20);  
  vst.display();
}