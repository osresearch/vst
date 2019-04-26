class Ball extends DisplayableVst {
  PVector position;
  PVector lastPosition;
  PVector velocity;  
  float s = 12;
  float speed = 8;

  Ball(Vst vst) {
    super(vst);
    position = new PVector(50, 250);
    lastPosition = position.copy();
    velocity = PVector.fromAngle(QUARTER_PI * random(1, 1.5)).mult(speed);
  }

  void update() {
    lastPosition = position.copy();
    position.add(velocity);
  }

  void display() {
    pushStyle();
    stroke(255);
    rectMode(CENTER);
    rect(position.x, position.y, s, s);
    popStyle();
  }
}