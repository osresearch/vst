class DisplayableVst extends DisplayableBase {
  Vst vst;

  DisplayableVst(Vst vst) {
    this.vst = vst;
  }

  void rect(float x, float y, float w, float h) {
    vst.rect(x, y, w, h);
  }
}