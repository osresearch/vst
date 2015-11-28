/** \file
 * V.st vector board interface
 */
import processing.serial.*;

Serial vector_serial; 

static byte[] bytes = new byte[8192];
static int byte_count = 0;
static int last_x;
static int last_y;

// first 2 brightness, next 11 X-coord, last 11 Y-coord;
// 3 x 8 bit bytes

void
vector_setup()
{
	// finding the right port requires picking it from the list
	// should look for one that matches "ttyACM*" or "tty.usbmodem*"
	for(String port : Serial.list())
	{
		println(port);
		if (match(port, "usbmode|ACM") == null)
			continue;
		vector_serial = new Serial(this, port, 9600); 
		return;
	}
  
	println("No valid serial ports found?\n");
}


void
vector_line(
	boolean bright,
	float x0,
	float y0,
	float x1,
	float y1
)
{
	stroke(bright ? 255 : 120);
	line(x0, y0, x1, y1);

	// should compute point of crossing the boundary
	if (x0 < 0 || x0 > width
	||  x1 < 0 || x1 > width
	||  y0 < 0 || y0 > height
	||  y1 < 0 || y1 > height)
		return;

	vector_point(1, x0, y0);
	vector_point(bright ? 3 : 2, x1, y1);
}


void
vector_point(
	int bright,
	float xf,
	float yf
)
{
	// Vector axis is (0,0) in the bottom left corner;
	// this needs to flip the Y axis.
	int x = (int)(xf * 2047 / width);
	int y = 2047 - (int)(yf * 2047 / height);

	// skip the transit if we are going to the same point
	if (x == last_x && y == last_y)
		return;

	last_x = x;
	last_y = y;

	int cmd = (bright & 3) << 22 | (x & 2047) << 11 | (y & 2047) << 0;
	bytes[byte_count++] = (byte)((cmd >> 16) & 0xFF);
	bytes[byte_count++] = (byte)((cmd >>  8) & 0xFF);
	bytes[byte_count++] = (byte)((cmd >>  0) & 0xFF);
}


void vector_send()
{
	// add the "draw frame" command
	bytes[byte_count++] = 1;
	bytes[byte_count++] = 1;
	bytes[byte_count++] = 1;

	if (vector_serial != null)
		vector_serial.write(subset(bytes, 0, byte_count));

	// reset the output buffer
	byte_count = 0;

	bytes[byte_count++] = 0;
	bytes[byte_count++] = 0;
	bytes[byte_count++] = 0;
	bytes[byte_count++] = 0;
}
