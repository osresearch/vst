import processing.serial.*;

//get the message coming in from Arduino 
Serial myPort; 

float origX = random(1024);
float origY = random(1024);
float destX = random(1024);
float destY = random(1024);
float oVx = random(10);
float oVy = random(10);
float dVx = random(20);
float dVy = random(20);
byte[] bytes = new byte[3+3*2*10];
int byte_count = 0;

// first 2 brightness, next 11 X-coord, last 11 Y-coord;
// 3 x 8 bit bytes

void setup() {
  // get the port you have coming in - this is usually 7.... we will run some sample code 
  String portName = Serial.list()[0]; 
  for(String port : Serial.list())
  {
    println(port);
  }
  
  
  myPort = new Serial(this, portName, 9600); 

  size(1024, 1024);
}

void draw() {
  background(255);
  stroke(110);
  strokeWeight(5);
  float dist = 10;
  for (int i = 0; i < 10; i++, dist += 20) { 
    line(
       origX + dist, origY + dist,
       destX + dist, destY);
       
    add_point(1, (int) origX + dist, (int) origY + dist);
    add_point(i == 0 ? 3 : 2, (int) destX + dist, (int) destY);
  }

  //add_point(1, (int) origX, (int) origY);
  //add_point(2, (int) destX, (int) destY);
  
  send_points();

  origX += oVx;
  origY += oVy;
  destX += dVx;
  destY += dVy;
  bounce1();
  bounce2();
}

void bounce1() {
  if (origY > height) {
    oVy = -oVy;
  }
  if (origY < 0) {
    oVy = -oVy;
  }
  if (origX > width) {
    oVx = -oVx;
  }
  if (origX < 0) {
    oVx = -oVx;
  }
}

void bounce2() {
  if (destY > height) {
    dVy = -dVy;
  }
  if (destY < 0) {
    dVy = -dVy;
  }
  if (destX > width) {
    dVx = -dVx;
  }
  if (destX < 0) {
    dVx = -dVx;
  }
}

void add_point(int bright, float xf, float yf)
{
  int x = 512 + (int) xf;
  int y = 512 + (int) yf;
  int cmd = (bright & 3) << 22 | (x & 2047) << 11 | (y & 2047) << 0;
  bytes[byte_count++] = (byte)((cmd >> 16) & 0xFF);
  bytes[byte_count++] = (byte)((cmd >>  8) & 0xFF);
  bytes[byte_count++] = (byte)((cmd >>  0) & 0xFF);
}

void send_points()
{
  bytes[byte_count++] = 1;
  bytes[byte_count++] = 1;
  bytes[byte_count++] = 1;
  myPort.write(bytes);
  byte_count = 0;
}
