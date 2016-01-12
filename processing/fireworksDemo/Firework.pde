class FireworkManager extends DisplayableList {
  void trigger(PVector position, int nFrames) {
    this.add(new Firework(position, nFrames));
  }
}

class Firework extends DisplayableBase {
  DisplayableList sparks = new DisplayableList();
  int nFrames;
  int framesLeft;
  int nSparks = 50;
  float sparkSize = 10;

  class Spark extends DisplayableBase {
    PVector position;
    PVector velocity;

    Spark(PVector position, PVector velocity) {
      this.position = position;
      this.velocity = velocity;      
      position.add(velocity.copy().normalize().mult(sparkSize * 0.8));
    }

    void update() {
      velocity.add(gravity);
      position.add(velocity);

      if (position.x < -sparkSize || position.x >= width + sparkSize || position.y >= height + sparkSize) {
        complete();
      }
    }

    void display() {
      float r = framesLeft / (float) nFrames;
      PVector p2 = position.copy().sub(velocity.copy().mult(r * sparkSize));
      boolean bright = random(0.75) < r;
      vst.line(bright, position, p2);
    }
  }

  Firework(PVector position, int nFrames) {
    this.nFrames = nFrames;
    framesLeft = nFrames;

    for (int i = 0; i < nSparks; i++) {
      PVector velocity = PVector.fromAngle(random(TAU)).mult(random(2));
      sparks.add(new Spark(position.copy(), velocity));
    }
  }

  boolean updateFrame() {
    if (--framesLeft == 0) {
      complete();
      return true;
    }

    return false;
  }

  void update() {
    if (updateFrame()) {
      return;
    }
    sparks.update();
  }

  void display() {
    sparks.display();
  }
}