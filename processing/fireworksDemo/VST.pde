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

    while (iter.hasNext()) {
      VstFrame f = (VstFrame) iter.next();
      PVector p = new PVector((float) (f.x / 2047.0) * width, (float) ((2047 - f.y) / 2047.0) * height);

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
  }

  PVector vstToScreen(VstFrame f) {
    return new PVector((float) (f.x / 2047.0) * width, (float) ((2047 - f.y) / 2047.0) * height);
  }
}

/** \file
 * Region clipping for 2D rectangles using Coehn-Sutherland.
 * https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
 */

class Clipping {
  final PVector min;
  final PVector max;

  final static int INSIDE = 0;
  final static int LEFT = 1;
  final static int RIGHT = 2;
  final static int BOTTOM = 4;
  final static int TOP = 8;

  Clipping(PVector p0, PVector p1) {
    min = new PVector(min(p0.x, p1.x), min(p0.y, p1.y));
    max = new PVector(max(p0.x, p1.x), max(p0.y, p1.y));
  }

  int compute_code(PVector p) {
    int code = INSIDE;

    if (p.x < min.x)
      code |= LEFT;
    if (p.x > max.x)
      code |= RIGHT;
    if (p.y < min.y)
      code |= BOTTOM;
    if (p.y > max.y)
      code |= TOP;

    return code;
  }

  float intercept(float y, float x0, float y0, float x1, float y1) {
    return x0 + (x1 - x0) * (y - y0) / (y1 - y0);
  }

  // Clip a line segment from p0 to p1 by the
  // rectangular clipping region min/max.
  // p0 and p1 will be modified to be in the region
  // returns true if the line segment is visible at all
  boolean clip(PVector p0, PVector p1) {
    int code0 = compute_code(p0);
    int code1 = compute_code(p1);

    while (true) {
      // both are inside the clipping region.
      // accept them as is.
      if ((code0 | code1) == 0)
        return true;

      // both are outside the clipping region
      // and do not cross the visible area.
      // reject the point.
      if ((code0 & code1) != 0)
        return false;

      // At least one endpoint is outside
      // the region.
      int code = code0 != 0 ? code0 : code1;
      float x = 0, y = 0;

      if ((code & TOP) != 0) {
        // point is above the clip rectangle
        y = max.y;
        x = intercept(y, p0.x, p0.y, p1.x, p1.y);
      } else if ((code & BOTTOM) != 0) {
        // point is below the clip rectangle
        y = min.y;
        x = intercept(y, p0.x, p0.y, p1.x, p1.y);
      } else if ((code & RIGHT) != 0) {
        // point is to the right of clip rectangle
        x = max.x;
        y = intercept(x, p0.y, p0.x, p1.y, p1.x);
      } else if ((code & LEFT) != 0) {
        // point is to the left of clip rectangle
        x = min.x;
        y = intercept(x, p0.y, p0.x, p1.y, p1.x);
      }

      // Now we move outside point to intersection point to clip
      // and get ready for next pass.
      if (code == code0) {
        p0.x = x;
        p0.y = y;
        code0 = compute_code(p0);
      } else {
        p1.x = x;
        p1.y = y;
        code1 = compute_code(p1);
      }
    }
  }
}