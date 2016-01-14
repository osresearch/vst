class Paddle extends DisplayableBase {
  PVector position;
  static final float w = 100;
  static final float h = 25;
  
  Paddle() {
    position = new PVector(0, 440);
  }
  
  void update() {
    //position.x = constrain(mouseX, w, (width - 1) - w);    
    position.x = mouseX;    
  }
  
  void display() {
    pushStyle();
    //rectMode(CENTER);
    rect(position.x, position.y, w, h);
    popStyle();
  }
}