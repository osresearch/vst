import processing.serial.*;

class Vst extends DisplayableBase {
  float brightnessNormal = 80;
  float brightnessBright = 255;
  VstBuffer buffer;  
  private Clipping clip;
  private int lastX;
  private int lastY;

  Vst() {
    clip = new Clipping(new PVector(0, 0), new PVector(width - 1, height - 1));
    buffer = new VstBuffer();
  }

  Vst(Serial serial) {
    this();
    buffer.setSerial(serial);
  }

  void display() {
    displayBuffer();
    buffer.send();
  }

  void vline(boolean bright, float x0, float y0, float x1, float y1) {
    vline(bright, new PVector(x0, y0), new PVector(x1, y1));
  }

  void vline(boolean bright, PVector p0, PVector p1) {
    if (p0 == null || p1 == null) {
      return;
    }

    // can we detect resize?
    clip.max.x = width - 1;
    clip.max.y = height - 1;

    // Preserve original points
    p0 = p0.copy();
    p1 = p1.copy();

    if (!clip.clip(p0, p1)) {
      return;
    }

    // The clip above should ensure that this never happens
    // but just in case, we will discard those points
    if (vectorOffscreen(p0.x, p0.y) || vectorOffscreen(p1.x, p1.y)) {
      return;
    }

    vpoint(1, p0);
    vpoint(bright ? 3 : 2, p1);
  }

  boolean vectorOffscreen(float x, float y) {
    return (x < 0 || x >= width || y < 0 || y >= height);
  }

  void vpoint(int bright, PVector v) {
    int x = (int) (v.x * 2047 / width);
    int y = (int) (2047 - (v.y * 2047 / height));

    if (x == lastX && y == lastY) {
      return;
    }

    lastX = x;
    lastY = y;
    buffer.add(x, y, bright);
  }

  void displayBuffer() {
    PVector lastPoint = new PVector();
    Iterator iter = buffer.iterator();
    float distance = 0;
    boolean printTotalPath = true;

    while (iter.hasNext()) {
      VstFrame f = (VstFrame) iter.next();
      PVector p = new PVector((float) (f.x / 2047.0) * width, (float) ((2047 - f.y) / 2047.0) * height);

      if (printTotalPath) {
        distance += p.dist(lastPoint);
      }

      if (f.z == 1) {
        // Transit
        lastPoint = p;
      } else if (f.z == 2) {
        // Normal
        pushStyle();
        stroke(g.strokeColor, brightnessNormal);        
        line(p.x, p.y, lastPoint.x, lastPoint.y);
        popStyle();
        lastPoint = p;
      } else if (f.z == 3) {
        // Bright
        pushStyle();
        stroke(g.strokeColor, brightnessBright);        
        line(p.x, p.y, lastPoint.x, lastPoint.y);
        popStyle();
        lastPoint = p;
      }
    }

    if (printTotalPath) {
      println(distance);
    }
  }
}