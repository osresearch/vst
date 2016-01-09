class VstFrame {
  int bright;
  int x;
  int y;

  VstFrame(int bright, int x, int y) {
    this.bright = bright;
    this.x = x;
    this.y = y;
  }
}


class VstBuffer implements Iterable<VstFrame> {
  private final static int LENGTH = 8192;
  private final static int HEADER_LENGTH = 4;
  private final static int TAIL_LENGTH = 3;
  private byte[] buffer = new byte[LENGTH];
  private int byte_count = 0;
  private Serial serial;

  VstBuffer() {
  }

  public Iterator<VstFrame> iterator() {
    Iterator<VstFrame> it = new Iterator<VstFrame>() {
      private int index = HEADER_LENGTH;

      @Override
        public boolean hasNext() {
        return index + 3 < byte_count;
      }

      @Override
        public VstFrame next() {
        int byte0 = buffer[index++] & 0xff;
        int byte1 = buffer[index++] & 0xff;
        int byte2 = buffer[index++] & 0xff;
        int frame = (byte0 << 16 | byte1 << 8 | byte2);
        return new VstFrame((frame >> 22) & 3, (frame >> 11) & 2047, frame & 2047);
      }

      @Override
        public void remove() {
        throw new UnsupportedOperationException();
      }
    };
    return it;
  }

  public void setSerial(Serial serial) {
    this.serial = serial;
  }

  public void add(int bright, int x, int y) {
    if (byte_count < LENGTH - TAIL_LENGTH) {
      int frame = (bright & 3) << 22 | (x & 2047) << 11 | (y & 2047) << 0;
      buffer[byte_count++] = (byte) ((frame >> 16) & 0xFF);
      buffer[byte_count++] = (byte) ((frame >>  8) & 0xFF);
      buffer[byte_count++] = (byte) (frame & 0xFF);
    }
  }

  public void send() {
    if (serial != null) {
      // Add end frame
      buffer[byte_count++] = 1;
      buffer[byte_count++] = 1;
      buffer[byte_count++] = 1;

      // Send via serial
      serial.write(subset(buffer, 0, byte_count));
    }

    reset();
  }

  private void reset() {
    byte_count = 0;
    buffer[byte_count++] = 0;
    buffer[byte_count++] = 0;
    buffer[byte_count++] = 0;
    buffer[byte_count++] = 0;
  }
}