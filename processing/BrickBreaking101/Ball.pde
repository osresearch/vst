class Ball extends DisplayableBase {
  PVector position;
  PVector lastPosition;
  PVector velocity;  
  float s = 20;

  Ball() {
    position = new PVector(width / 2.5, height * 0.1);
    lastPosition = position.copy();
    velocity = PVector.fromAngle(-QUARTER_PI * random(1, 1.5)).mult(12);
  }

  void update() {
    lastPosition = position.copy();
    position.add(velocity);
  }

  void display() {
    pushStyle();
    stroke(255);
    fill(0);
    rectMode(CENTER);
    rect(position.x, position.y, s, s);
    popStyle();
  }
}