/** \file
 * V.st vector board interface.
 *
 * This handles storing the vectors, clipping them to the display,
 * mirroring the line segments on the real display and sending them
 * to the serial port.
 */
import processing.serial.*;

Serial vector_serial; 

static byte[] bytes = new byte[8192];
static int byte_count = 0;
static int last_x;
static int last_y;
Clipping clip;

// first 2 brightness, next 11 X-coord, last 11 Y-coord;
// 3 x 8 bit bytes

void
vector_setup()
{
	clip = new Clipping(
		new PVector(0,0),
		new PVector(width-1,height-1)
	);
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
	vector_line(bright, new PVector(x0,y0), new PVector(x1,y1));
}


void
vector_line(
  boolean bright,
  PVector p0_in,
  PVector p1_in
)
{
	if (p0_in == null || p1_in == null)
		return;

	// can we detect resize?
	clip.max.x = width-1;
	clip.max.y = height-1;

	stroke(bright ? 255 : 120);

	// clipping might modify the point, so we must copy
	PVector p0 = p0_in.copy();
	PVector p1 = p1_in.copy();

	if (!clip.clip(p0, p1))
		return;

	line(p0.x, p0.y, p1.x, p1.y);

	vector_point(1, p0.x, p0.y);
	vector_point(bright ? 3 : 2, p1.x, p1.y);
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


PVector random3(float min, float max)
{
	return new PVector(
		random(min,max),
		random(min,max),
		random(min,max)
	);
}

PVector limit(PVector x, float min, float max)
{
	PVector n = new PVector(x.x, x.y, x.z);
	if (n.x < min) n.x = min;
	if (n.y < min) n.y = min;
	if (n.z < min) n.z = min;

	if (n.x > max) n.x = max;
	if (n.y > max) n.y = max;
	if (n.z > max) n.z = max;

	return n;
}

PVector unit(PVector x)
{
	return PVector.mult(x, 1.0 / x.mag());
}


