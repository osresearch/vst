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
  private final byte[] buffer = new byte[LENGTH];
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
    int size = size();
    if (size() < LENGTH - HEADER_LENGTH - TAIL_LENGTH - 1) {
      // If consecutive z values are zero, replace last to avoid transit redundancy
      if (z == 0 && size > 0 && get(size - 1).z == 0) {
        this.set(size() - 1, new VstFrame(x, y, z));
      } else {
        add(new VstFrame(x, y, z));
      }
      return true;
    }
    return false;
  }

  public void send() {
    if (isEmpty()) {
      return;
    }

    if (serial != null) {
      int byte_count = 0;
      
      // Header
      buffer[byte_count++] = 0;
      buffer[byte_count++] = 0;
      buffer[byte_count++] = 0;
      buffer[byte_count++] = 0;

      // Data
      VstBuffer sorted = sort();
      for (VstFrame frame : sorted) {
        int v = (frame.z & 3) << 22 | (frame.x & 2047) << 11 | (frame.y & 2047) << 0;
        buffer[byte_count++] = (byte) ((v >> 16) & 0xFF);
        buffer[byte_count++] = (byte) ((v >>  8) & 0xFF);
        buffer[byte_count++] = (byte) (v & 0xFF);
      }

      // Tail
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

    VstFrame lastFrame = new VstFrame(1024, 1024, 0);
    VstFrame nearestFrame = lastFrame;

    while (!src.isEmpty()) {
      int startIndex = 0;
      int endIndex = 0;
      float nearestDistance = 100000;
      int i = 0;
      boolean reverseOrder = false;

      while (i < src.size()) { 
        int j = i;
        while (j < src.size() - 1 && src.get(j + 1).z > 1) {
          j++;
        }

        VstFrame startFrame = src.get(i);
        VstFrame endFrame = src.get(j);    // j = index of inclusive right boundary
        float startDistance = dist(lastFrame.x, lastFrame.y, startFrame.x, startFrame.y);
        float endDistance = dist(lastFrame.x, lastFrame.y, endFrame.x, endFrame.y);

        if (startDistance < nearestDistance) {
          startIndex = i;
          endIndex = j;
          nearestDistance = startDistance;
          nearestFrame = startFrame;
        }
        if (!startFrame.equals(endFrame) && endDistance < nearestDistance) {
          startIndex = i;
          endIndex = j;
          nearestDistance = endDistance;
          nearestFrame = endFrame;
          reverseOrder = true;
        }        
        i = j + 1;
      }

      VstFrame startFrame = src.get(startIndex);
      VstFrame endFrame = src.get(endIndex);

      if (reverseOrder) {
        lastFrame = startFrame;
        for (int index = endIndex; index >= startIndex; index--) {
          destination.add(src.get(index));
        }
      } else {
        lastFrame = endFrame;
        for (int index = startIndex; index <= endIndex; index++) {
          destination.add(src.get(index));
        }
      }

      src.removeRange(startIndex, endIndex + 1);
    }

    return destination;
  }

  float measureTransitDistance(ArrayList<VstFrame> fList) {
    float distance = 0.0;
    VstFrame last = new VstFrame(1024, 1024, 0);
    for (VstFrame f : fList) {
      distance += dist(f.x, f.y, last.x, last.y);
      last = f;
    }
    return distance;
  }
}