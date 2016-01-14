class Collision extends DisplayableBase {
  void update() {
    float halfWidth = ball.s / 2.0;

    // Boundary Collisions
    if (ball.position.x < halfWidth) {
      ball.position.x = halfWidth;
      ball.velocity.x *= -1;
    } else if (ball.position.x >= width - halfWidth) {
      ball.position.x = width - 1 - halfWidth;
      ball.velocity.x *= -1;
    }
    // TODO: Handle falling though wall
    if (ball.position.y < halfWidth) {
      ball.position.y = halfWidth;
      ball.velocity.y *= -1;
    } else if (ball.position.y >= height - halfWidth) {
      ball.position.y = height - 1 - halfWidth;
      ball.velocity.y *= -1;
    }

    // Paddle
    if (ball.position.y + ball.s >= paddle.position.y && ball.position.y + ball.s < paddle.position.y + paddle.h) {
      println("foo");
    }
  }
}