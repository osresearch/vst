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
    pushStyle();
    stroke(127);
    rectMode(CENTER);
    rect(position.x, position.y, w, h);
    popStyle();
  }
}