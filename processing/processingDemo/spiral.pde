/** \file
 * Draw a spiral that opens and closes in a rythmic fashion.
 *
 * This also demonstrates the RecShape library for generating
 * and duplicating/rotating shapes.
 *
 * (c) 2015 Jacob Joaquin.
 */
class SpiralDemo extends Demo
{
static final int nPoints = 5;
static final int nSpawns = 25;

static final int nFrames = 100;
static final float phaseInc = 1.0 / nFrames;
float phase = 0.0;

void draw()
{
  background(0);

  RecShape shape = new RecShape();
  for (int i = 0; i < nPoints; i++) {
    float n = i / (float) nPoints;
    PVector p = PVector.fromAngle(n * TAU);
    p.mult(width);
    p.add(width / 2.0, height / 2.0);
    shape.add(p);
  }

  shape.display(false);
  
  float nPhase = phase;
  for (int i = 0; i < nSpawns; i++) {
    RecShape shape2 = shape.spawn(nPhase);
    nPhase += 0.01;
    nPhase -= (int) nPhase;
    shape2.display(i == nSpawns-3);
    shape = shape2;
  }

  phase += phaseInc;
  phase -= (int) phase;
}
}
