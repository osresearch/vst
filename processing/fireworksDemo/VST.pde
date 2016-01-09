import processing.serial.*;

class Vst extends DisplayableBase {
  float brightnessNormal = 80;
  float brightnessBright = 255;
  private Clipping clip;
  private IntPoint lastPoint;
  VstBuffer buffer;  

  class IntPoint {
    int x = 0;
    int y = 0;

    IntPoint() {
    }

    IntPoint(PVector p) {
      x = (int) p.x;
      y = (int) p.y;
    }

    IntPoint(int x, int y) {
      this.x = x;
      this.y = y;
    }

    IntPoint copy() {
      return new IntPoint(x, y);
    }

    boolean equals(IntPoint p) {
      return p.x == x && p.y == y;
    }
  }

  Vst() {
    clip = new Clipping(new PVector(0, 0), new PVector(width - 1, height - 1));
    lastPoint = new IntPoint();
    buffer = new VstBuffer();
    buffer.reset();
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
    IntPoint p = new IntPoint(v);
    p.x = (int) (p.x * 2047 / width);
    p.y = (int) 2047 - (p.y * 2047 / height);

    if (p.equals(lastPoint)) {
      return;
    }

    lastPoint = p.copy();
    buffer.add(bright, p.x, p.y);
  }

  void displayBuffer() {
    PVector lastPoint = new PVector();
    Iterator iter = buffer.iterator();
    
    while (iter.hasNext()) {
     VstFrame f = (VstFrame) iter.next();
     PVector p = new PVector((float) (f.x / 2047.0) * width, (float) ((2047 - f.y) / 2047.0) * height);

     if (f.bright == 1) {
       // Transit
       lastPoint = p;
     } else if (f.bright == 2) {
       // Normal
       pushStyle();
       stroke(g.strokeColor, brightnessNormal);        
       line(p.x, p.y, lastPoint.x, lastPoint.y);
       popStyle();
       lastPoint = p;
     } else if (f.bright == 3) {
       // Bright
       pushStyle();
       stroke(g.strokeColor, brightnessBright);        
       line(p.x, p.y, lastPoint.x, lastPoint.y);
       popStyle();
       lastPoint = p;
     }
    }
  }
}