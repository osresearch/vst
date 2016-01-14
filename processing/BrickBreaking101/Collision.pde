class Collision extends DisplayableBase {
  void update() {
    float radius = ball.s / 2.0;
    if (ball.position.x < radius) {
      ball.position.x = radius;
      ball.velocity.x *= -1;
    } else if (ball.position.x >= width - radius) {
      ball.position.x = width - 1 - radius;
      ball.velocity.x *= -1;
    } 
    if (ball.position.y < radius) {
      ball.position.y = radius;
      ball.velocity.y *= -1;
    } else if (ball.position.y >= height - radius) {
      ball.position.y = height - 1 - radius;
      ball.velocity.y *= -1;
    }
  }
}