/** \file
 * Qix-like demo of drawing vectors with Processing.
 */

void setup() {
    size(1024, 1024);
    surface.setResizable(true);

    vector_setup();

    blendMode(ADD);
    noFill();
    stroke(212, 128, 32, 128);

    frameRate(25);
}

float a = 0;

void draw() {
    //qix_draw();
    swarm_draw();
    //spiral_draw();
    //demo3d_draw();

    vector_send();
}
