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
	//hershey[4].draw(50,50, 10, false);

	vector_string("Hello, world!", 0, 20, 8, false);

	vector_send();
}
