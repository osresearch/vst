import processing.serial.*;

class Vst extends DisplayableBase {
  float brightnessNormal = 80;
  float brightnessBright = 255;
  private Clipping clip;
  private Serial serial;
  private IntPoint lastPoint;
  private byte[] buffer = new byte[8192];
  private int byte_count = 0;

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
    resetBuffer();
  }

  Vst(Serial serial) {
    this();
    this.serial = serial;
  }

  void display() {
    displayBuffer();
    sendBuffer();
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
    // Don't exceend buffer length. Compensate for new cmd and draw frame command.
    if (byte_count >= buffer.length - 7) {
      return;
    }

    IntPoint p = new IntPoint(v);
    p.x = (int) (p.x * 2047 / width);
    p.y = (int) 2047 - (p.y * 2047 / height);

    if (p.equals(lastPoint)) {
      return;
    }

    lastPoint = p.copy();

    int cmd = (bright & 3) << 22 | (p.x & 2047) << 11 | (p.y & 2047) << 0;
    buffer[byte_count++] = (byte) ((cmd >> 16) & 0xFF);
    buffer[byte_count++] = (byte) ((cmd >>  8) & 0xFF);
    buffer[byte_count++] = (byte) (cmd & 0xFF);
  }

  private void resetBuffer() {
    byte_count = 0;
    buffer[byte_count++] = 0;
    buffer[byte_count++] = 0;
    buffer[byte_count++] = 0;
    buffer[byte_count++] = 0;
  }

  private void sendBuffer() {
    // add the "draw frame" command
    buffer[byte_count++] = 1;
    buffer[byte_count++] = 1;
    buffer[byte_count++] = 1;

    if (serial != null) {
      serial.write(subset(buffer, 0, byte_count));
    }

    resetBuffer();
  }

  void displayBuffer() {
    int counter = 4;                    // Compensate for frame header 
    PVector lastPoint = new PVector();

    while (counter < byte_count) {
      int byte0 = buffer[counter++] & 0xff;
      int byte1 = buffer[counter++] & 0xff;
      int byte2 = buffer[counter++] & 0xff;
      int frame = (byte0 << 16 | byte1 << 8 | byte2);
      int cmd = (frame >> 22) & 3;
      int x = (frame >> 11) & 2047;
      int y = frame & 2047;
      PVector p = vstPointToPVector(x, y);

      if (cmd == 1) {
        // Transit
        lastPoint = p;
      } else if (cmd == 2) {
        // Normal
        pushStyle();
        stroke(g.strokeColor, brightnessNormal);        
        line(p.x, p.y, lastPoint.x, lastPoint.y);
        popStyle();
        lastPoint = p;
      } else if (cmd == 3) {
        // Bright
        pushStyle();
        stroke(g.strokeColor, brightnessBright);        
        line(p.x, p.y, lastPoint.x, lastPoint.y);
        popStyle();
        lastPoint = p;
      }
    }
  }

  private PVector vstPointToPVector(int x, int y) {
    return new PVector((float) (x / 2047.0) * width, (float) ((2047 - y) / 2047.0) * height);
  }
}