/** \file
 * Qix-like demo of drawing vectors with Processing.
 */

void setup() {
    vector_setup();

    blendMode(ADD);
    noFill();
    stroke(212, 128, 32, 128);

	size(1024, 1024);
	surface.setResizable(true);

	frameRate(25);
}

float a = 0;
void draw() {
	//qix_draw();
	//swarm_draw();
	//spiral_draw();
	demo3d_draw();

	//a += 0.1;
	//vector_string("Hello, world!", 100, 100, 20, a, true, false);

	vector_send();
}
