BrickManager brickManager;
Ball ball;
Paddle paddle;
Collision collision;
PVector gravity;

void settings() {
  size(500, 500, P2D);
  int d = displayDensity();
  pixelDensity(d);
}

void setup() {
  brickManager = new BrickManager();
  ball = new Ball();
  paddle = new Paddle();
  collision = new Collision();
  gravity = new PVector(0, 0.05);
}

void draw() {
  background(0);

  // Update
  ball.update();
  paddle.update();
  brickManager.detectBallCollision();
  brickManager.update();
  collision.update();

  // Display
  paddle.display();
  brickManager.display();
  ball.display();
}