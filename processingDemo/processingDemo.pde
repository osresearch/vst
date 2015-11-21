/** \file
 * Qix-like demo of drawing vectors with Processing.
 */

import processing.serial.*;

Serial myPort; 

final int segments = 20;
final int xmax = 512;
final int ymax = 512;

float[] x0 = new float[segments];
float[] y0 = new float[segments];
float[] x1 = new float[segments];
float[] y1 = new float[segments];
float vx0 = random(10)+5;
float vy0 = random(10)+5;
float vx1 = random(10)+4;
float vy1 = random(10)+4;
int head = 0;

byte[] bytes = new byte[3+3*2*segments];
int byte_count = 0;

// first 2 brightness, next 11 X-coord, last 11 Y-coord;
// 3 x 8 bit bytes

void setup() {
  // finding the right port requires picking it from the list
  // seems to change sometimes?
  String portName = Serial.list()[0]; 
  for(String port : Serial.list())
  {
    println(port);
  }
  
  
  myPort = new Serial(this, portName, 9600); 

  size(xmax, ymax);
}

void draw() {
  background(255);
  stroke(110);
  strokeWeight(5);

  for(int i = 0 ; i < segments ; i++)
  {
    line(x0[i], y0[i], x1[i], y1[i]);

    // optimize slightly -- go from end of one segment to the other
    if (i % 2 == 0)
    {
	    add_point(1, x0[i], y0[i]);
	    add_point(i == head ? 3 : 2, x1[i], y1[i]);
    } else {
	    add_point(1, x1[i], y1[i]);
	    add_point(i == head ? 3 : 2, x0[i], y0[i]);
    }
  }

  send_points();

  // update the current point
  final int new_head = (head + 1) % segments;

  float nx = x0[head] + vx0;
  if (nx < 0)
  {
    vx0 = -vx0;
    nx = -nx;
  } else
  if (nx >= xmax)
  {
    vx0 = -vx0;
    nx = xmax - (nx - xmax) - 1;
  }

  x0[new_head] = nx;

  nx = x1[head] + vx1;
  if (nx < 0)
  {
    vx1 = -vx1;
    nx = -nx;
  } else
  if (nx >= xmax)
  {
    vx1 = -vx1;
    nx = xmax - (nx - xmax) - 1;
  }

  x1[new_head] = nx;

  float ny = y0[head] + vy0;
  if (ny < 0)
  {
    vy0 = -vy0;
    ny = -ny;
  } else
  if (ny >= ymax)
  {
    vy0 = -vy0;
    ny = ymax - (ny - ymax) - 1;
  }

  y0[new_head] = ny;

  ny = y1[head] + vy1;
  if (ny < 0)
  {
    vy1 = -vy1;
    ny = -ny;
  } else
  if (ny >= ymax)
  {
    vy1 = -vy1;
    ny = ymax - (ny - ymax) - 1;
  }

  y1[new_head] = ny;

  head = new_head;
}


void add_point(int bright, float xf, float yf)
{
  int x = (int)(xf * 2048 / xmax);
  int y = (int)(yf * 2048 / ymax);
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
