/** \file
 * Qix-like demo of drawing vectors with Processing.
 */

import processing.serial.*;

Serial myPort; 

byte[] bytes = new byte[8192];
int byte_count = 0;

// first 2 brightness, next 11 X-coord, last 11 Y-coord;
// 3 x 8 bit bytes

void setup() {
  // finding the right port requires picking it from the list
  // seems to change sometimes?
  // should look for one that matches "ttyACM*" or "tty.usbmodem*"
  String portName = Serial.list()[0]; 
  for(String port : Serial.list())
  {
    println(port);
  }
  
  
  myPort = new Serial(this, portName, 9600); 

  size(512, 512);
  frame.setResizable(true);

  frameRate(25);
}

void draw() {
  //qix_draw();
  swarm_draw();
  send_points();
}


void add_point(int bright, float xf, float yf)
{
  // Vector axis is (0,0) in the bottom left corner;
  // this needs to flip the Y axis.
  int x = (int)(xf * 2048 / width);
  int y = 2047 - (int)(yf * 2048 / height);

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

  myPort.write(subset(bytes, 0, byte_count));
  byte_count = 0;

  bytes[byte_count++] = 0;
  bytes[byte_count++] = 0;
  bytes[byte_count++] = 0;
  bytes[byte_count++] = 0;
}
