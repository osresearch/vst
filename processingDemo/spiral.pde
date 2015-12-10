/** \file
 * Draw a spiral that opens and closes in a rythmic fashion.
 *
 * This also demonstrates the RecShape library for generating
 * and duplicating/rotating shapes.
 *
 * (c) 2015 Jacob Joaquin.
 */
static int nPoints = 5;
static int nSpawns = 100;

static int nFrames = 100;
static float phase = 0.0;
static float phaseInc = 1 / (float) nFrames;

void spiral_draw()
{
  background(0);

  RecShape shape = new RecShape();
  for (int i = 0; i < nPoints; i++) {
    float n = i / (float) nPoints;
    PVector p = PVector.fromAngle(n * TAU);
    p.mult(500);
    p.add(width / 2.0, height / 2.0);
    shape.add(p);
  }

  shape.display(true);
  
  float nPhase = phase;
  for (int i = 0; i < nSpawns; i++) {
    RecShape shape2 = shape.spawn(nPhase);
    nPhase += 0.01;
    nPhase -= (int) nPhase;
    shape2.display();
    shape = shape2;
  }

  phase += phaseInc;
  phase -= (int) phase;
}
