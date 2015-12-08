/** \file
 * Qix-like demo of drawing vectors with Processing.
 */

void setup() {
	vector_setup();

	size(512, 512);
	surface.setResizable(true);

	frameRate(25);
}

float a = 0;
void draw() {
	//qix_draw();
	swarm_draw();
	//hershey[4].draw(50,50, 10, false);

	a += 0.1;
	vector_string("Hello, world!", 100, 100, 20, a, false);

	vector_send();
}
