import java.util.Iterator;
import processing.serial.*;

void line(float x0, float y0, float x1, float y1) {
  if (vst.overload) {
    vst.line(x0, y0, x1, y1);
  } else {
    super.line(x0, y0, x1, y1);
  }
}

void line(PVector p0, PVector p1) {
  if (vst.overload) {
    vst.line(p0, p1);
  } else {
    super.line(p0.x, p0.y, p1.x, p1.y);
  }
}

void ellipse(float x, float y, float w, float h) {
  vst.ellipse(x, y, w, h);
}

void ellipse(PVector p, float w, float h) {
  vst.ellipse(p, w, h);
}

void ellipse(float x, float y, float w, float h, int nSides) {
  vst.ellipse(x, y, w, h, nSides);
}

void rect(float x, float y, float w, float h) {
  vst.rect(x, y, w, h);
}

void rect(PVector p, float w, float h) {
  vst.rect(p.x, p.y, w, h);
}

void beginShape() {
  vst.beginShape();
}

void vertex(PVector p) {
  vst.vertex(p);
}

void vertex(float x, float y) {
  vst.vertex(x, y);
}

void vertex(float x, float y, float z) {
  vst.vertex(x, y, z);
}

void endShape() {
  vst.endShape();
}

void endShape(int mode) {
  vst.endShape(mode);
}

void triangle(float x0, float y0, float x1, float y1, float x2, float y2) {
  triangle(new PVector(x0, y0), new PVector(x1, y1), new PVector(x2, y2));
}

void triangle(PVector p0, PVector p1, PVector p2) {
  vst.beginShape();
  vst.vertex(p0);
  vst.vertex(p1);
  vst.vertex(p2);
  vst.endShape(CLOSE);
}

void quad(float x0, float y0, float x1, float y1, float x2, float y2, float x3, float y3) {
  quad(new PVector(x0, y0), new PVector(x1, y1), new PVector(x2, y2), new PVector(x3, y3));
}

void quad(PVector p0, PVector p1, PVector p2, PVector p3) {
  vst.beginShape();
  vst.vertex(p0);
  vst.vertex(p1);
  vst.vertex(p2);
  vst.vertex(p3);
  vst.endShape(CLOSE);
}

Serial createSerial() {
  // finding the right port requires picking it from the list
  // should look for one that matches "ttyACM*" or "tty.usbmodem*"
  for (String port : Serial.list()) {
    println(port);
    if (match(port, "usbmode|ACM") == null) {
      continue;
    }
    return new Serial(this, port, 9600);
  }

  println("No valid serial ports found?\n");
  return null;
}

class Vst {
  color colorStroke = color(255);
  color colorTransit = color(255, 0, 0, 80);
  boolean displayTransit = false;
  VstBuffer buffer;
  private PApplet parent;
  private Clipping clip;
  private VstPoint lastPoint;
  private PVector lastInsert;
  private ArrayList<ShapePoint> shapeList;  // For beginShape(), vertex(), endShape, etc..
  private final int shapeNSidesDefault = 32;
  private boolean overload = true;

  Vst(PApplet parent) {
    this.parent = parent;
    clip = new Clipping(new PVector(0, 0), new PVector(width - 1, height - 1));
    buffer = new VstBuffer();
    lastPoint = new VstPoint(-1, -1);
    lastInsert = new PVector();
  }

  Vst(PApplet parent, Serial serial) {
    this(parent);
    buffer.setSerial(serial);
  }

  void display() {
    buffer.update();
    displayBuffer();
    buffer.send();
    lastPoint = new VstPoint(-1, -1);        // TODO: Better choice for resetting lastPoint?
    lastInsert = new PVector(width / 2, height / 2);
    point(lastInsert, 0);
  }

  void line(float x0, float y0, float x1, float y1) {
    line(new PVector(x0, y0), new PVector(x1, y1));
  }

  void line(float x0, float y0, float z0, float x1, float y1, float z1) {
    line(new PVector(x0, y0, z0), new PVector(x1, y1, z1));
  }

  void line(PVector p0, PVector p1) {
    if (p0 == null || p1 == null) {
      return;
    }

    // can we detect resize?
    clip.max.x = width - 1;
    clip.max.y = height - 1;

    // Preserve original points
    p0 = p0.copy();
    p1 = p1.copy();

    // Create temp versions for modelXYZ()
    PVector pt0 = p0.copy();
    PVector pt1 = p1.copy();

    if (g.is2D()) {
      p0.x = screenX(pt0.x, pt0.y);
      p0.y = screenY(pt0.x, pt0.y);
      p1.x = screenX(pt1.x, pt1.y);
      p1.y = screenY(pt1.x, pt1.y);
    } else if (g.is3D()) {
      p0.x = screenX(pt0.x, pt0.y, pt0.z);
      p0.y = screenY(pt0.x, pt0.y, pt0.z);
      p1.x = screenX(pt1.x, pt1.y, pt1.z);
      p1.y = screenY(pt1.x, pt1.y, pt1.z);

      // Don't display if behind z-plane.
      // TODO: Doesn't compensate for camera translations
      float zClip0 = modelZ(pt0.x, pt0.y, pt0.z);
      float zClip1 = modelZ(pt1.x, pt1.y, pt1.z);
      if (zClip0 > 0 || zClip1 > 0) {
        return;
      }
    }

    if (!clip.clip(p0, p1)) {
      return;
    }

    // The clip above should ensure that this never happens
    // but just in case, we will discard those points
    if (vectorOffscreen(p0.x, p0.y) || vectorOffscreen(p1.x, p1.y)) {
      return;
    }


    // Handle transit
    if (!lastInsert.equals(p0)) {
      point(p0, 0);
    }

    int bright = (int) brightness(g.strokeColor);    
    point(p1, bright);
  }

  boolean vectorOffscreen(float x, float y) {
    return x < 0 || x >= width || y < 0 || y >= height;
  }


  void point(PVector v, int bright) {
    VstPoint point = new VstPoint((int) (v.x * 4095 / width), (int) (4095 - (v.y * 4095 / height)), bright);

    if (!point.equals(lastPoint)) {
      buffer.add(point.clone());
    }
    lastInsert = v;
  }

  class ShapePoint {
    float x;
    float y;
    float z;
    color c;

    ShapePoint(float x, float y, float z) {
      this.x = x;
      this.y = y;
      this.z = z;
      c = g.strokeColor;
      //println(brightness(c));
    }

    ShapePoint(float x, float y, float z, color c) {
      this.x = x;
      this.y = y;
      this.z = z;
      this.c = c;
    }

    ShapePoint copy() {
      return new ShapePoint(x, y, z, c);
    }
  }

  void beginShape() {
    shapeList = new ArrayList<ShapePoint>();
  }

  void vertex(PVector p) {
    shapeList.add(new ShapePoint(p.x, p.y, p.z));
  }

  void vertex(float x, float y) {
    vertex(new PVector(x, y, 0));
  }

  void vertex(float x, float y, float z) {
    vertex(new PVector(x, y, z));
  }

  void endShape() {
    endShape(-1);
  }

  void endShape(int mode) {
    int size = shapeList.size();
    if (size <= 1) {
      return;
    }
    ShapePoint p0 = shapeList.get(0);
    pushStyle();
    if (mode == CLOSE && size > 2) {
      ShapePoint p1 = shapeList.get(size - 1).copy();
      stroke(g.strokeColor);
      line(p1.x, p1.y, p1.z, p0.x, p0.y, p0.z);
    }
    for (int i = 1; i < size; i++) {
      ShapePoint p1 = shapeList.get(i);

      stroke(p0.c);
      line(p0.x, p0.y, p0.z, p1.x, p1.y, p1.z);

      p0 = p1;
    }
    popStyle();
    shapeList.clear();
  }

  void ellipse(PVector p, float w, float h) {
    ellipse(p.x, p.y, w, h, shapeNSidesDefault);
  }

  void ellipse(float x, float y, float w, float h) {
    ellipse(x, y, w, h, shapeNSidesDefault);
  }

  void ellipse(float x, float y, float w, float h, int nSides) {
    w *= 0.5;
    h *= 0.5;
    // Default is CENTER mode
    if (g.ellipseMode == CORNER) {
      x += w;
      y += h;
    }
    pushStyle();
    stroke(g.strokeColor);
    beginShape();
    for (int i = 0; i < nSides; i++) {
      float a = i / (float) nSides * TAU;
      vertex(x + cos(a) * w, y + sin(a) * h);
    }
    endShape(CLOSE);
    popStyle();
  }

  void rect(float x, float y, float w, float h) {
    pushMatrix();
    translate(x, y);    
    // Default is CORNER mode
    if (g.rectMode == CENTER) {
      translate(-w / 2.0, -h / 2.0);
    }
    line(0, 0, w, 0);
    line(w, 0, w, h);
    line(w, h, 0, h);
    line(0, h, 0, 0);
    popMatrix();
  }

  void displayBuffer() {
    PVector lastPoint = new PVector(width / 2.0, height / 2.0);  // Assumes V.st re-centers

    pushStyle();
    Iterator it = buffer.iterator();
    overload = false;
    while (it.hasNext()) {
      VstPoint v = (VstPoint) it.next();
      PVector p = new PVector((float) (v.x / 4095.0) * width, (float) ((4095 - v.y) / 4095.0) * height);

      if (v.z == 0 && displayTransit) {
        stroke(colorTransit);
        parent.line(lastPoint.x, lastPoint.y, p.x, p.y);
        parent.line(p.x - 3, p.y - 3, p.x + 3, p.y + 3);
        parent.line(p.x + 3, p.y - 3, p.x - 3, p.y + 3);
      } else {
        stroke(colorStroke, v.z);
        parent.line(lastPoint.x, lastPoint.y, p.x, p.y);
      }

      lastPoint = p;
    }

    popStyle();
    overload = true;
  }

  PVector vstToScreen(VstPoint f) {
    return new PVector((float) (f.x / 4095.0) * width, (float) ((4095 - f.y) / 4095.0) * height);
  }
}

class VstPoint {
  Integer x;
  Integer y;
  Integer z;

  VstPoint(Integer x, Integer y) {
    this.x = x;
    this.y = y;
    z = 0;
  }

  VstPoint(Integer x, Integer y, Integer z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  VstPoint clone() {
    return new VstPoint(x, y, z);
  }

  boolean equals(VstPoint point) {
    return this.x == point.x && this.y == point.y && this.z == point.z;
  }
}

class VstBuffer extends ArrayList<VstPoint> {
  private final static int LENGTH = 8192;
  private final static int HEADER_LENGTH = 4;
  private final static int TAIL_LENGTH = 4;
  private final static int MAX_POINTS = (LENGTH - HEADER_LENGTH - TAIL_LENGTH - 1) / 4;
  private final byte[] buffer = new byte[LENGTH];
  private Serial serial;

  public void update() {
    VstBuffer temp = sort();
    clear();
    addAll(temp);
  }

  public void setSerial(Serial serial) {
    this.serial = serial;
  }

  @Override
    public boolean add(VstPoint point) {
    if (this.size() > MAX_POINTS) {
      //throw new UnsupportedOperationException("VstBuffer at capacity. Vector discarded.");
      return false;
    } else if (point.z == 0 && size() > 0 && get(size() - 1).z == 0) {
      // If consecutive z values are zero, replace last to avoid transit redundancy
      // TODO: Maybe this should be done during sorting / cleanup phase instead of pre-optimizing?
      this.set(size() - 1, point);
    } else {
      super.add(point);
    }    
    return true;
  }

  public void send() {
    if (!isEmpty() && serial != null) {
      int byte_count = 0;

      // Header
      buffer[byte_count++] = 0;
      buffer[byte_count++] = 0;
      buffer[byte_count++] = 0;
      buffer[byte_count++] = 0;

      // Data
      for (VstPoint point : this) {
        int v = 2 << 30 | (((int) (point.z / 4)) & 63) << 24 | (point.x & 4095) << 12 | (point.y & 4095) << 0;
        buffer[byte_count++] = (byte) ((v >> 24) & 0xFF);
        buffer[byte_count++] = (byte) ((v >> 16) & 0xFF);
        buffer[byte_count++] = (byte) ((v >> 8) & 0xFF);
        buffer[byte_count++] = (byte) (v & 0xFF);
      }

      // Tail
      buffer[byte_count++] = 1;
      buffer[byte_count++] = 1;
      buffer[byte_count++] = 1;
      buffer[byte_count++] = 1;

      // Send via serial
      serial.write(subset(buffer, 0, byte_count));
    }

    clear();
  }

  private VstBuffer sort() {
    VstBuffer destination = new VstBuffer();      
    VstBuffer src = (VstBuffer) clone();

    VstPoint lastPoint = new VstPoint(2048, 2048, 0);
    VstPoint nearestPoint = lastPoint;

    while (!src.isEmpty()) {
      int startIndex = 0;
      int endIndex = 0;
      float nearestDistance = Integer.MAX_VALUE;
      int i = 0;
      boolean reverseOrder = false;

      while (i < src.size()) { 
        int j = i;
        while (j < src.size() - 1 && src.get(j + 1).z > 0) {
          j++;
        }

        VstPoint startPoint = src.get(i);
        VstPoint endPoint = src.get(j);    // j = index of inclusive right boundary
        float startDistance = dist(lastPoint.x, lastPoint.y, startPoint.x, startPoint.y);
        float endDistance = dist(lastPoint.x, lastPoint.y, endPoint.x, endPoint.y);

        if (startDistance < nearestDistance) {
          startIndex = i;
          endIndex = j;
          nearestDistance = startDistance;
          nearestPoint = startPoint;
        }
        if (!startPoint.equals(endPoint) && endDistance < nearestDistance) {
          startIndex = i;
          endIndex = j;
          nearestDistance = endDistance;
          nearestPoint = endPoint;
          reverseOrder = true;
        }        
        i = j + 1;
      }

      VstPoint startPoint = src.get(startIndex);
      VstPoint endPoint = src.get(endIndex);

      if (reverseOrder) {
        lastPoint = startPoint;
        for (int index = endIndex; index >= startIndex; index--) {
          // Re-arrange transit command
          VstPoint f0 = src.get(index);
          int nextIndex = index + 1;
          nextIndex = nextIndex >= endIndex ? startIndex : nextIndex;
          VstPoint f1 = src.get(nextIndex);
          int temp = f0.z;
          f0.z = f1.z;
          f1.z = temp;

          destination.add(src.get(index));
        }
      } else {
        lastPoint = endPoint;
        for (int index = startIndex; index <= endIndex; index++) {
          destination.add(src.get(index));
        }
      }

      src.removeRange(startIndex, endIndex + 1);
    }

    return destination;
  }

  float measureTransitDistance(ArrayList<VstPoint> fList) {
    float distance = 0.0;
    VstPoint last = new VstPoint(2048, 2048, 0);
    for (VstPoint f : fList) {
      distance += dist(f.x, f.y, last.x, last.y);
      last = f;
    }
    return distance;
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