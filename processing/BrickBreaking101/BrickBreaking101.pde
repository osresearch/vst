Vst vst;
BrickManager brickManager;
Ball ball;
Paddle paddle;
Collision collision;

void settings() {
  size(500, 500, P2D);
  int d = displayDensity();
  pixelDensity(d);
}

void setup() {  
  vst = new Vst(this, createSerial());
  vst.colorBright = color(64, 255, 64);
  vst.colorNormal = color(vst.colorBright, 80);
  brickManager = new BrickManager();
  ball = new Ball(vst);
  paddle = new Paddle(vst);
  collision = new Collision();
  frameRate(50);
  blendMode(ADD);
  strokeWeight(2);
}

void draw() {
  background(0, 24, 0);
  
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
  vst.display();
}