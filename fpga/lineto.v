`ifndef _lineto_v_
`define _lineto_v_

/**
 * Bresenham's Line Drawing algorithm.
 * Generate straight lines from the current point to the
 * destination.  x_in/y_in can be reset at any time with the strobe.
 */
module lineto(
	input clk,
	input reset,

	input strobe,
	input [BITS-1:0] x_in,
	input [BITS-1:0] y_in,

	output ready, // set when done
	output axis, // did the x or y value change
	output [BITS-1:0] x_out,
	output [BITS-1:0] y_out
);
	parameter BITS = 16;

	reg [BITS-1:0] err;

	reg [BITS-1:0] x_dst;
	reg [BITS-1:0] y_dst;

	reg [BITS-1:0] x_out;
	reg [BITS-1:0] y_out;

	// once the output reaches the dstination, it is ready
	// for a new point.
	assign ready = (x_dst == x_out) && (y_dst == y_out);

	reg axis;
	reg sx;
	reg sy;

	reg signed [BITS-1:0] dx;
	reg signed [BITS-1:0] dy;

	wire signed [BITS:0] err2 = err << 1;

	always @(posedge clk)
	begin
		//$monitor("%d %d %d %d %d", x_out, y_out, dx, dy, err);
		if (reset) begin
			// reset will latch the current inputs
			x_dst <= x_in;
			y_dst <= y_in;
			x_out <= x_in;
			y_out <= y_in;
			err <= 0;
			axis <= 0;
		end else
		if (strobe) begin
			x_dst <= x_in;
			y_dst <= y_in;
			axis <= 0;

			if (x_in > x_out) begin
				sx <= 1;
				dx <= x_in - x_out;
			end else begin
				sx <= 0;
				dx <= x_out - x_in;
			end

			if (y_in > y_out) begin
				sy <= 1;
				dy <= y_in - y_out;
			end else begin
				sy <= 0;
				dy <= y_out - y_in;
			end

			err <= ((x_in > x_out) ? (x_in - x_out) : (x_out - x_in))
				-
				((y_in > y_out) ? (y_in - y_out) : (y_out - y_in));

		end else
		if (!ready) begin
			// move towards the dstination point
			if (err2 > -dy)
			begin
				err <= err - dy;
				x_out <= x_out + (sx ? 1 : -1);
				axis <= 0;
			end else
			if (err2 < dx)
			begin
				err <= err + dx;
				y_out <= y_out + (sy ? 1 : -1);
				axis <= 1;
			end
		end
	end
endmodule


`ifdef IVERILOG
module lineto_test;
	reg clk = 0;
	reg reset = 1;
	parameter BITS = 16;

	reg strobe = 0;
	reg [BITS-1:0] x_in = 0;
	reg [BITS-1:0] y_in = 0;

	wire ready;
	wire [BITS-1:0] x_out;
	wire [BITS-1:0] y_out;

	always #5 clk = !clk;

	always begin
		# 50 reset <= 0;

		# 50 x_in <= 10000; y_in <= 3000; strobe <= 1;
		# 10 strobe <= 0;

		# 1000000 x_in <= 3000; y_in <= 10000; strobe <= 1;
		# 10 strobe <= 0;

		# 1000000 x_in <= 3000; y_in <= 3000; strobe <= 1;
		# 10 strobe <= 0;

		# 1000000 x_in <= 8000; y_in <= 3000; strobe <= 1;
		# 10 strobe <= 0;

		# 1000000 x_in <= 0; y_in <= 0; strobe <= 1;
		# 10 strobe <= 0;


		# 1000000 $finish;
	end

	lineto #(.BITS(BITS)) l_inst(
		.clk(clk),
		.reset(reset),

		.strobe(strobe),
		.x_in(x_in),
		.y_in(y_in),

		.ready(ready),
		.x_out(x_out),
		.y_out(y_out)
	);

	initial $monitor("%d %d %d %d", $time, x_out, y_out, ready);

endmodule
`endif

`endif
