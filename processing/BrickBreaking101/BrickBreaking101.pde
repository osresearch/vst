Vst vst;
BrickManager brickManager;
Ball ball;
Paddle paddle;
Collision collision;

void settings() {
  size(450, 550, P2D);
  pixelDensity(displayDensity());
}

void setup() {  
  frameRate(50);

  // Init Vst
  vst = new Vst(this, createSerial());
  vst.colorBright = color(220, 220, 255);
  vst.colorNormal = color(vst.colorBright, 96);
  blendMode(ADD);
  strokeWeight(1);

  // Init Game Objects
  brickManager = new BrickManager();
  ball = new Ball(vst);
  paddle = new Paddle(vst);
  collision = new Collision();
}

void draw() {
  background(0);
  stroke(127);
  vst.line(0, height - 1, 0, 0);
  vst.line(0, 0, width - 1, 0);
  vst.line(width - 1, 0, width - 1, height - 1);

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