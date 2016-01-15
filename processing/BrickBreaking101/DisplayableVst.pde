class DisplayableVst extends DisplayableBase {
  Vst vst;

  DisplayableVst(Vst vst) {
    this.vst = vst;
  }

  void rect(boolean bright, float x, float y, float w, float h) {
    vst.rect(bright, x, y, w, h);
  }
}