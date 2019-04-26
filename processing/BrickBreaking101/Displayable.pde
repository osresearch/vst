import java.util.Iterator;

interface Displayable {
  void update();
  void display();
  void complete();
  boolean hasCompleted();
}

abstract class DisplayableBase implements Displayable {
  boolean hasCompleted = false;

  void update() {
  };

  void display() {
  };

  boolean hasCompleted() {
    return hasCompleted;
  };

  void complete() {
    hasCompleted = true;
  }
}

class DisplayableList<T extends Displayable> extends ArrayList<T> implements Displayable {
  void update() {
    Iterator iter = this.iterator();

    while (iter.hasNext()) {
      T displayable = (T) iter.next();
      displayable.update();
      if (displayable.hasCompleted()) {
        iter.remove();
      }
    }
  }

  void display() {
    for (Displayable displayable : this) {
      displayable.display();
    }
  }

  void complete() {
  }

  boolean hasCompleted() {
    return false;
  }
}