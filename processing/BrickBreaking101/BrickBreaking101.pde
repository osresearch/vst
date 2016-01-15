Vst vst;
BrickManager brickManager;
Ball ball;
Paddle paddle;
Collision collision;

void settings() {
  size(500, 500, P2D);
  pixelDensity(displayDensity());
}

void setup() {  
  frameRate(50);

  // Init Vst
  vst = new Vst(this, createSerial());
  vst.colorBright = color(64, 255, 64);
  vst.colorNormal = color(vst.colorBright, 80);
  vst.displayTransit = true;
  blendMode(ADD);
  strokeWeight(2);

  // Init Game Objects
  brickManager = new BrickManager();
  ball = new Ball(vst);
  paddle = new Paddle(vst);
  collision = new Collision();
}

void draw() {
  background(0, 24, 0);

  // Update Game Objects
  ball.update();
  paddle.update();
  brickManager.detectBallCollision();
  brickManager.update();
  collision.update();

  // Display Game Objects
  paddle.display();
  brickManager.display();
  ball.display();

  // Send to vector display
  vst.display();
}