/** \file
 * Qix-like demo of drawing vectors with Processing.
 */

final int segments = 20;

float[] x0 = new float[segments];
float[] y0 = new float[segments];
float[] x1 = new float[segments];
float[] y1 = new float[segments];
float vx0 = random(10)+5;
float vy0 = random(10)+5;
float vx1 = random(10)+4;
float vy1 = random(10)+4;
int head = 0;

void qix_draw() {
  background(0);
  strokeWeight(5);

  for(int i = 0 ; i < segments ; i++)
  {
    	vector_line(i == head, x0[i], y0[i], x1[i], y1[i]);
  }

  // update the current point
  final int new_head = (head + 1) % segments;

  float nx = x0[head] + vx0;
  if (nx < 0)
  {
    vx0 = -vx0;
    nx = -nx;
  } else
  if (nx >= width)
  {
    vx0 = -vx0;
    nx = width - (nx - width) - 1;
  }

  x0[new_head] = nx;

  nx = x1[head] + vx1;
  if (nx < 0)
  {
    vx1 = -vx1;
    nx = -nx;
  } else
  if (nx >= width)
  {
    vx1 = -vx1;
    nx = width - (nx - width) - 1;
  }

  x1[new_head] = nx;

  float ny = y0[head] + vy0;
  if (ny < 0)
  {
    vy0 = -vy0;
    ny = -ny;
  } else
  if (ny >= height)
  {
    vy0 = -vy0;
    ny = height - (ny - height) - 1;
  }

  y0[new_head] = ny;

  ny = y1[head] + vy1;
  if (ny < 0)
  {
    vy1 = -vy1;
    ny = -ny;
  } else
  if (ny >= height)
  {
    vy1 = -vy1;
    ny = height - (ny - height) - 1;
  }

  y1[new_head] = ny;

  head = new_head;
}
