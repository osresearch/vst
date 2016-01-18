void line(float x, float y, float w, float h) {
  if (vst.overload) {
    vst.line(x, y, w, h);
  } else {
    super.line(x, y, w, h);
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