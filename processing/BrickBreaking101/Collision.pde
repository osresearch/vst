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
    //if (ball.position.y + ball.s >= paddle.position.y && ball.position.y + ball.s < paddle.position.y + paddle.h) {
    //  println("foo");
    //}

    float paddleHalfWidth = paddle.w / 2.0;
    float paddleHalfHeight = paddle.h / 2.0;
    float paddleLeft = paddle.position.x - paddleHalfWidth;
    float paddleRight = paddle.position.x + paddleHalfWidth;

    if (ball.velocity.y > 0 &&
      ball.position.x > paddleLeft &&
      ball.position.x < paddleRight &&
      ball.position.y > paddle.position.y - paddleHalfHeight &&
      ball.position.y < paddle.position.y + paddleHalfHeight) {
      ball.velocity.y *= -1;

      float angleOffset = PI / 8.0;
      float angle = map(ball.position.x, paddleLeft, paddleRight, -PI + angleOffset, -angleOffset);
      angle = constrain(angle, -PI + angleOffset, -angleOffset);  
      ball.velocity = PVector.fromAngle(angle);
      ball.velocity.mult(8);
    }
  }
}