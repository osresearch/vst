/** \file
 * Region clipping for 2D rectangles using Coehn-Sutherland.
 * https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
 */

class Clipping
{
    final PVector min;
    final PVector max;

    final static int INSIDE = 0;
    final static int LEFT = 1;
    final static int RIGHT = 2;
    final static int BOTTOM = 4;
    final static int TOP = 8;

    Clipping(PVector p0, PVector p1)
    {
        float x0, y0, x1, y1;

        // Find the minimum x
        if (p0.x < p1.x)
        {
            x0 = p0.x;
            x1 = p1.x;
        } else {
            x0 = p1.x;
            x1 = p0.x;
        }

	// Find the minimum y
        if (p0.y < p1.y)
        {
            y0 = p0.y;
            y1 = p1.y;
        } else {
            y0 = p1.y;
            y1 = p0.y;
        }

        min = new PVector(x0, y0);
        max = new PVector(x1, y1);
    }

    int compute_code(PVector p)
    {
        int code = INSIDE;
        if (p.x < min.x)
            code |= LEFT;
        if (p.x > max.x)
            code |= RIGHT;
        if (p.y < min.y)
            code |= BOTTOM;
        if (p.y > max.y)
            code |= TOP;

        return code;
    }

    float intercept(float y, float x0, float y0, float x1, float y1)
    {
        return x0 + (x1 - x0) * (y - y0) / (y1 - y0);
    }

    // Clip a line segment from p0 to p1 by the
    // rectangular clipping region min/max.
    // p0 and p1 will be modified to be in the region
    // returns true if the line segment is visible at all
    boolean clip(PVector p0, PVector p1)
    {
        int code0 = compute_code(p0);
        int code1 = compute_code(p1);

        while(true)
        {
            // both are inside the clipping region.
            // accept them as is.
            if((code0 | code1) == 0)
                return true;

            // both are outside the clipping region
            // and do not cross the visible area.
            // reject the point.
            if ((code0 & code1) != 0)
                return false;

            // At least one endpoint is outside
            // the region.
            int code = code0 != 0 ? code0 : code1;
            float x = 0, y = 0;

            if ((code & TOP) != 0)
            {
                // point is above the clip rectangle
                y = max.y;
                x = intercept(y, p0.x, p0.y, p1.x, p1.y);
            } else
            if ((code & BOTTOM) != 0)
            {
                // point is below the clip rectangle
                y = min.y;
                x = intercept(y, p0.x, p0.y, p1.x, p1.y);
            } else
            if ((code & RIGHT) != 0)
            {
                // point is to the right of clip rectangle
                x = max.x;
                y = intercept(x, p0.y, p0.x, p1.y, p1.x);
            } else
            if ((code & LEFT) != 0)
            {
                // point is to the left of clip rectangle
                x = min.x;
                y = intercept(x, p0.y, p0.x, p1.y, p1.x);
            }

            // Now we move outside point to intersection point to clip
            // and get ready for next pass.
            if (code == code0) {
                p0.x = x;
                p0.y = y;
                code0 = compute_code(p0);
            } else {
                p1.x = x;
                p1.y = y;
                code1 = compute_code(p1);
            }
        }
    }
}
