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