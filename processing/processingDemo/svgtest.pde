/*
 * Draw a vector line art based on an SVG file.
 */
class DemoSVG
{
	PShape s;
	final static float eps = 0.01;

	DemoSVG(String file)
	{
		s = loadShape(file);

		println(s.getChildCount());
		for(int i = 0 ; i < s.getChildCount() ; i++)
		{
			PShape c = s.getChild(i);
			print(i);
			print(" ");
			println(c.getChildCount());

			for (int j = 0; j < c.getVertexCount(); j++) {
				PVector v = c.getVertex(j);
				print("   ");
				print(v.x);
				print(" ");
				print(v.y);
				println();
			}
		}
	}
		
	void draw(PShape s)
	{
		if (s == null)
			return;

		for(int i = 0 ; i < s.getChildCount() ; i++)
		{
			PShape c = s.getChild(i);
			draw(c);
		}

		PVector p0 = null;
		PVector start = null;

		for (int j = 0; j < s.getVertexCount(); j++) {
			PVector p1 = s.getVertex(j);
			if (p0 != null && p1 != null)
			{
				PVector ps0 = PVector.mult(p0, 0.6);
				PVector ps1 = PVector.mult(p1, 0.6);
				ps0.add(new PVector(200,100));
				ps1.add(new PVector(200,100));
				line(ps0, ps1);
			}

			if(start == null)
			{
				// start a new line segment
				start = p1;
				p0 = p1;
			} else
			if (abs(p1.x - start.x) < eps
			&&  abs(p1.y - start.y) < eps)
			{
				// end of a line segment
				start = null;
				p0 = null;
			} else {
				// normal mid-point
				p0 = p1;
			}
		}
	}

	void draw()
	{
		background(20);
		//shape(s, 0, 0, 500, 500);

		draw(s);
	}
}
