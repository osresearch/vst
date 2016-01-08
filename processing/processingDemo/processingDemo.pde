/** \file
 * Qix-like demo of drawing vectors with Processing.
 */
DemoSVG d;

void setup() {
    size(1024, 1200);
    surface.setResizable(true);

    vector_setup();

    blendMode(ADD);
    noFill();
    stroke(212, 128, 32, 128);

    frameRate(25);
    //d = new DemoSVG("32c3_knot.svg");
}

float a = 0;

void draw() {
    //qix_draw();
    //swarm_draw();
    //spiral_draw();
    demo3d_draw();
    //d.draw();

    vector_send();
}
