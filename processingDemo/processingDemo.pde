/** \file
 * Qix-like demo of drawing vectors with Processing.
 */

void setup() {
	vector_setup();

	size(512, 512);
	surface.setResizable(true);

	frameRate(25);
}

void draw() {
	//qix_draw();
	swarm_draw();
	vector_send();
}
