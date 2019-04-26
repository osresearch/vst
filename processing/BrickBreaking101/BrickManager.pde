class Brick extends DisplayableVst { //<>// //<>//
  PVector position;

  Brick(Vst vst, PVector position) {
    super(vst);
    this.position = position;
  }

  void display() {
    pushStyle();
    stroke(127);
    rectMode(CORNER);
    rect(position.x + 1, position.y + 1, brickManager.w - 2, brickManager.h - 2);
    popStyle();
  }

  void complete() {
    super.complete();
    pushStyle();
    stroke(255);
    rectMode(CORNER);
    rect(position.x, position.y, brickManager.w, brickManager.h);
    popStyle();
  }
}

class BrickManager extends DisplayableList<Brick> {
  int nColumns = 10;
  int nRows = 6;
  float w;
  float h;

  BrickManager() {
    w = (width - 1) / (float) nColumns;
    h = 24;
    initBricks();
  }

  void update() {
    super.update();
    if (this.size() == 0) {
      initBricks();
    }
  }

  void initBricks() {
    for (int y = 0; y < nRows; y++) {
      for (int x = 0; x < nColumns; x++) {
        Brick brick = new Brick(vst, new PVector(x * w, y * h + 3 * h));
        this.add(brick);
      }
    }
  }

  void detectBallCollision() {
    int nCollisionsX = 0;
    int nCollisionsY = 0;
    float radius = ball.s / 2.0;
    float ballLeft = ball.position.x - radius;
    float ballRight = ball.position.x + radius;
    float ballTop = ball.position.y - radius;
    float ballBottom = ball.position.y + radius;

    for (Brick brick : this) {
      float brickLeft = brick.position.x;
      float brickRight = brick.position.x + brickManager.w;
      float brickTop = brick.position.y;
      float brickBottom = brick.position.y + brickManager.h;

      if (
        ballLeft < brickRight &&
        ballRight >= brickLeft &&
        ballTop < brickBottom &&
        ballBottom >= brickTop
        ) {
        brick.complete();

        if (
          ball.lastPosition.x + radius < brickLeft && ballRight > brickLeft ||
          ball.lastPosition.x - radius > brickRight && ballLeft < brickRight
          ) {
          nCollisionsX++;
        }

        if (
          ball.lastPosition.y + radius < brickTop && ballBottom > brickTop ||
          ball.lastPosition.y - radius > brickBottom && ballTop < brickBottom
          ) {
          nCollisionsY++;
        }
      }
    }

    if (nCollisionsX > nCollisionsY) {
      ball.velocity.x *= -1;
    } else if (nCollisionsX < nCollisionsY) {
      ball.velocity.y *= -1;
    } else if (nCollisionsX != 0) {
      ball.velocity.x *= -1;
      ball.velocity.y *= -1;
    }
  }
}