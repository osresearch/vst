class VstFrame {
  int x;
  int y;
  int z;

  VstFrame(int x, int y, int z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
}

class VstBuffer extends ArrayList<VstFrame> {
  private final static int LENGTH = 8192;
  private final static int HEADER_LENGTH = 4;
  private final static int TAIL_LENGTH = 3;
  private final static int MAX_FRAMES = (LENGTH - HEADER_LENGTH - TAIL_LENGTH - 1) / 3;
  private byte[] buffer = new byte[LENGTH];
  private Serial serial;

  public void setSerial(Serial serial) {
    this.serial = serial;
  }

  @Override
    public boolean add(VstFrame frame) {
    if (this.size() > MAX_FRAMES) {
      throw new UnsupportedOperationException("VstBuffer at capacity. Vector discarded.");
    }
    return super.add(frame);
  }

  public boolean add(int x, int y, int z) {
    if (size() < LENGTH - HEADER_LENGTH - TAIL_LENGTH - 1) {
      add(new VstFrame(x, y, z));
      return true;
    }
    return false;
  }

  public void send() {
    if (serial != null) {
      
      int byte_count = 0;
      buffer[byte_count++] = 0;
      buffer[byte_count++] = 0;
      buffer[byte_count++] = 0;
      buffer[byte_count++] = 0;
      
      for (VstFrame frame : this) {
        int v = (frame.z & 3) << 22 | (frame.x & 2047) << 11 | (frame.y & 2047) << 0;
        buffer[byte_count++] = (byte) ((v >> 16) & 0xFF);
        buffer[byte_count++] = (byte) ((v >>  8) & 0xFF);
        buffer[byte_count++] = (byte) (v & 0xFF);
      }

      // Add end frame
      buffer[byte_count++] = 1;
      buffer[byte_count++] = 1;
      buffer[byte_count++] = 1;

      // Send via serial
      serial.write(subset(buffer, 0, byte_count));
    }

    clear();
  }
}