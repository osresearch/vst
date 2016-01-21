class Demos extends DisplayableList {
  Displayable current;
  private int currentIndex = 0;
  int duration = 1000;
  int framesLeft;
  final static int RANDOM = 0;
  final static int SEQUENTIAL = 1;
  private int mode = RANDOM;

  Demos() {
    super();
    framesLeft = duration;
  }

  void setMode(int mode) {
    this.mode = mode;
  }

  void update() {
    if (current == null) {
      current = (Displayable) get(currentIndex);
    }

    framesLeft--;
    if (framesLeft == 0) {
      next();
    }

    current.update();
  }

  void display() {
    current.display();
  }

  void next() {
    framesLeft = duration;
    if (mode == SEQUENTIAL) {
      currentIndex += 1;
      currentIndex %= size();
    } else if (size() > 1) {
      // Ensure new demo is different
      int lastDemo = currentIndex;
      while (lastDemo == currentIndex) {
        currentIndex = (int) random(size());
      }
    }
    current = (Displayable) get(currentIndex);
  }
}