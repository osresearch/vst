/** \file
 * Draw a spiral that opens and closes in a rythmic fashion.
 *
 * This also demonstrates the RecShape library for generating
 * and duplicating/rotating shapes.
 *
 * (c) 2015 Jacob Joaquin.
 */

/** \file
 * Recursive shape generator.
 *
 * Records a list of vectors and sends them to the
 * vector output device.
 *
 * (c) 2015 Jacob Joaquin.
 */
class RecShape extends DisplayableBase {
  ArrayList<PVector> points;

  RecShape() {
    points = new ArrayList<PVector>();
  }

  RecShape(ArrayList<PVector> copiedPoints) {
    points = new ArrayList<PVector>();

    for (PVector p : copiedPoints) {
      points.add(p.get());
    }
  }

  void add(float x, float y) {
    add(new PVector(x, y));
  }

  void add(PVector p) {
    points.add(p);
  }

  void display() {
    beginShape();
    for (PVector p : points) {
      vertex(p.x, p.y);
    }
    endShape(CLOSE);
  }

  RecShape spawn(float offset) {
    RecShape shape = new RecShape();

    int s = points.size();
    for (int i = 0; i < s; i++) {
      PVector p0 = points.get(i);
      PVector p1 = points.get((i + 1) % s);
      shape.add(lerp(p0.x, p1.x, offset), lerp(p0.y, p1.y, offset));
    }

    return shape;
  }
}


class SpiralDemo extends DisplayableBase {
  int nPoints = 5;
  int nSpawns = 32;
  float theSize;
  int scale = 1;

  int nFrames = 100;
  float phase = 0.0;
  float phaseInc = 1 / (float) nFrames;
  RecShape shape;
  DisplayableList shapes;
  
  SpiralDemo() {
    super();
    shapes = new DisplayableList();
  }

  void update() {
    shape = new RecShape();
    shapes.clear();
    
    for (int i = 0; i < nPoints; i++) {
      float n = i / (float) nPoints;
      PVector p = PVector.fromAngle(n * TAU);
      p.mult(500);
      p.add(width / 2.0, height / 2.0);
      shape.add(p);
    }
    float nPhase = phase;
    shapes.add(shape);
    
    for (int i = 0; i < nSpawns; i++) {
      RecShape shape2 = shape.spawn(nPhase);
      nPhase += 0.01;
      nPhase -= (int) nPhase;
      shapes.add(shape2);
      shape = shape2;
    }

    phase += phaseInc;
    phase -= (int) phase;
  }
  
  void display() {
    pushStyle();
    stroke(127);
    shapes.display();
    popStyle();
  }
}