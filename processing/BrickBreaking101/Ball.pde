class Ball extends DisplayableVst {
  PVector position;
  PVector lastPosition;
  PVector velocity;  
  float s = 12;

  Ball(Vst vst) {
    super(vst);
    position = new PVector(width / 2.5, 300);
    lastPosition = position.copy();
    velocity = PVector.fromAngle(-QUARTER_PI * random(1, 1.5)).mult(8);
  }

  void update() {
    lastPosition = position.copy();
    position.add(velocity);
  }

  void display() {
    pushMatrix();
    rectMode(CENTER);
    rect(true, position.x, position.y, s, s);
    popMatrix();
  }
}