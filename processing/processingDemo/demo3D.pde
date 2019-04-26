/** \file
 * Demo "3D" projection into the wireframe space.
 *
 * It might be possible to hook Processing's native 3D support,
 * but until someone figures out how to make that work this does
 * the 3D to 2D projection directly.
 * 
 * Todo:
 * - Coplanar edge removal
 * - Hidden wireframe removal
 */
class Camera
{
  float eye_z;
  float[][] r;

  Camera()
  {
    this.r = new float[3][3];
    this.setup(100, 0, 0, 0);
  }

  void
    setup(
    float eye_z, 
    float phi, 
    float theta, 
    float psi
    ) {
    float sx = sin(phi);
    float cx = cos(phi);
    float sy = sin(theta);
    float cy = cos(theta);
    float sz = sin(psi);
    float cz = cos(psi);

    this.r[0][0] =   cy * cz;
    this.r[0][1] = (-cy * sz) + (sx * sy * cz);
    this.r[0][2] = ( sx * sz) + (cx * sy * cz);

    this.r[1][0] =   cx * sz;
    this.r[1][1] = ( cx * cz) + (sx * sy * sz);
    this.r[1][2] = (-sx * cz) + (cx * sy * sz);

    this.r[2][0] = -sy;
    this.r[2][1] =  sx * cy;
    this.r[2][2] =  cx * cy;

    this.eye_z = eye_z;
  }


  PVector
    project(
    PVector v3_in
    ) {
    float[] v = v3_in.array();
    float[] p = new float[]{ 0, 0, this.eye_z };

    for (int i = 0; i < 3; i++)
      for (int j = 0; j < 3; j++)
        p[i] += this.r[i][j] * v[j];

    if (p[2] <= 0)
    {
      // The point is behind us; do not display
      return null;
    }

    // Smaller == wider angle view
    float zoom = 1024;

    // Transform to screen coordinate frame,
    //float px = (p[1] * this.eye_z * zoom) / p[2] + width/2;
    //float py = (p[0] * this.eye_z * zoom) / p[2] + height/2;
    float px = (p[1] * zoom) / p[2] + width/2;
    float py = (p[0] * zoom) / p[2] + height/2;

    return new PVector(px, py);
  }
}


class Demo3D extends DisplayableBase
{
  Camera c;
  PVector[] walk;
  boolean[][][] used;
  final int bound = 10;

  Demo3D()
  {
    c = new Camera();
    count = generate_walk(max_count, new PVector(0, 0, 0));
  }

  int
    generate_walk(
    int max_count, 
    PVector start
    )
  {
    used = new boolean[bound*2][bound*2][bound*2];

    int x = int(start.x);
    int y = int(start.y);
    int z = int(start.z);

    int ox = x;
    int oy = y;
    int oz = z;


    walk = new PVector[max_count];
    walk[0] = new PVector(x, y, z);
    used[x+bound][y+bound][z+bound] = true;

    for (int i = 1; i < max_count; i++)
    {
      for (int j = 0; j < 20; j++)
      {
        // if we have tried too many times we are done
        if (j == 19)
          return i;

        int dir = int(random(9));
        int nx = x, ny = y, nz = z;

        if (dir == 0) nx -= 1; 
        else
          if (dir == 1) nx += 1; 
          else
            if (dir == 2) ny -= 1; 
            else
              if (dir == 3) ny += 1; 
              else
                if (dir == 4) nz -= 1; 
                else
                  if (dir == 5) nz += 1; 
                  else
                    if (dir == 6) { 
                      if (nx > 0) nx--; 
                      else nx++;
                    } else
                      if (dir == 7) { 
                        if (ny > 0) ny--; 
                        else ny++;
                      } else
                        if (dir == 8) { 
                          if (nz > 0) nz--; 
                          else nz++;
                        } else
                        {
                          // do nothing
                        }

        if (nx == ox && ny == oy && nz == oz)
          continue;

        if (nx >= bound || nx < -bound) continue;
        if (ny >= bound || ny < -bound) continue;
        if (nz >= bound || nz < -bound) continue;

        if (used[nx+bound][ny+bound][nz+bound])
          continue;

        ox = x;
        oy = y;
        oz = z;
        x = nx;
        y = ny;
        z = nz;
        break;
      }

      used[x+bound][y+bound][z+bound] = true;
      walk[i] = new PVector(x, y, z);
    }

    // if we made it here we have filled the array
    return max_count;
  }


  void
    draw_box()
  {
    final float b = bound - 0.5;

    PVector v0 = c.project(new PVector(-b, -b, -b));
    PVector v1 = c.project(new PVector(-b, -b, +b));
    PVector v2 = c.project(new PVector(-b, +b, -b));
    PVector v3 = c.project(new PVector(-b, +b, +b));
    PVector v4 = c.project(new PVector(+b, -b, -b));
    PVector v5 = c.project(new PVector(+b, -b, +b));
    PVector v6 = c.project(new PVector(+b, +b, -b));
    PVector v7 = c.project(new PVector(+b, +b, +b));

    pushStyle();
    stroke(128);
    line(v0, v1);
    line(v0, v2);
    line(v0, v4);
    line(v1, v3);
    line(v1, v5);
    line(v2, v3);
    line(v2, v6);
    line(v3, v7);
    line(v4, v5);
    line(v4, v6);
    line(v5, v7);
    line(v6, v7);
    popStyle();
  }


  float roll = 0.2, pitch = -0.3, yaw = -0.2;
  int frame_num;
  final int max_count = 500;
  int count;
  int dir = 1;

  void
    display()
  {


    c.setup(1.5*bound, roll, pitch, yaw);
    roll += 0.02;
    pitch += 0.00;
    yaw -= 0.0000;

    if (true)
      draw_box();

//<<<<<<< HEAD
//     stroke(bright ? 255 : (i * 256.0 / (end - start)) );
//     line(op, np);
//=======
    // draw lines for each of the random walks
    PVector op = null;
    int start = frame_num > count ? frame_num - count : 0;
    int end = frame_num < count ? frame_num : count;
//>>>>>>> otherDemos

    for (int i = start; i < end; i++)
    {
      PVector np = c.project(walk[i]);
      boolean bright = false;
      if (frame_num > count && i < start+2)
        bright = true;
      if (frame_num < count && i >= frame_num - 2)
        bright = true;

      // flash when all the frames have been drawn
      if (frame_num == count || frame_num == count + 1)
        bright = true;

      pushStyle();
      stroke(bright ? 255 : 127);
      line(op, np);
      popStyle();

      op = np;
    }

    frame_num++;

    if (frame_num == count * 2)
    {
      //exit();
      frame_num = 0;
      count = generate_walk(max_count, walk[count-1]);
    }

    /*
  if (frame_num % 2 == 0)
     saveFrame("png/f######.png");
     */
  }
}