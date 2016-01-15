class Paddle extends DisplayableVst {
  PVector position;
  float w = 96;
  float h = 24;

  Paddle(Vst vst) {
    super(vst);
    position = new PVector(0, 440);
  }

  void update() {
    position.x = constrain(mouseX, w / 2.0, (width - 1) - w / 2.0);
  }

  void display() {
    pushMatrix();
    rectMode(CENTER);
    rect(false, position.x, position.y, w, h);
    popMatrix();
  }
}