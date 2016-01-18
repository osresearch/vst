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

void rect(float x, float y, float w, float h) {
  vst.rect(x, y, w, h);
}