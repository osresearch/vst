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
    this.setup(100, 0,0,0);
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

    this.r[0][0] =  cy * cz;
    this.r[0][1] = (-cy * sz) + (sx * sy * cz);
    this.r[0][2] = ( sx * sz) + (cx * sy * cz);

    this.r[1][0] =  cx * sz;
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

    for (int i = 0 ; i < 3 ; i++)
      for (int j = 0 ; j < 3 ; j++)
        p[i] += this.r[i][j] * v[j];

    if (p[2] <= 0)
    {
      // The point is behind us; do not display
      return null;
    }

    // Smaller == wider angle view
    float zoom = 50;

    // Transform to screen coordinate frame,
    float px = (p[1] * this.eye_z * zoom) / p[2] + width/2;
    float py = (p[0] * this.eye_z * zoom) / p[2] + height/2;

    return new PVector(px,py);
  }
}


static Camera c;
static PVector[] walk;
static boolean[][][] used;


int
generate_walk(
  int max_count
)
{
  int bound = 10;
  used = new boolean[bound*2][bound*2][bound*2];

  int x = 0;
  int y = 0;
  int z = 0;

  int ox = x;
  int oy = y;
  int oz = z;


  walk = new PVector[max_count];
  walk[0] = new PVector(x,y,z);

  for(int i = 1 ; i < max_count ; i++)
  {
    for(int j = 0 ; j < 20 ; j++)
    {
      // if we have tried too many times we are done
      if (j == 19)
         return i;

      int dir = int(random(6));
      int nx = x, ny = y, nz = z;
    
      if (dir == 0) nx -= 1; else
      if (dir == 1) nx += 1; else
      if (dir == 2) ny -= 1; else
      if (dir == 3) ny += 1; else
      if (dir == 4) nz -= 1; else
      if (dir == 5) nz += 1;

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


static float roll, pitch = 0.3, yaw = -0.2;
static int frame_num;
static int count;

void
demo3d_draw()
{
  background(0);
  strokeWeight(2);

  final int max_count = 500;

  if (c == null)
  {
    c = new Camera();
    count = generate_walk(max_count);
  }

  c.setup(frame_num/30.0 + 10, roll, pitch, yaw);
  roll += 0.02;
  pitch += 0.00051;
  yaw -= 0.0003;

  // draw lines for each of the random walks
  PVector op = null;
  for(int i = 0 ; i < frame_num ; i++)
  {
     PVector np = c.project(walk[i]);
     if (op != null && np != null)
       vector_line(i >= frame_num-2, op, np);
     op = np;
  }

  frame_num++;

  if (frame_num > count)
  {
    exit();
    frame_num = 0;
    count = generate_walk(max_count);
  }

  if (frame_num % 2 == 0)
    saveFrame("png/f######.png");
}
