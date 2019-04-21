/*
 * SPI input timing:
 * CS is active low
 * CLK is rising edge
 *
 * The clk_pin is clk/2.
 * TODO: generated clk_pin with a DDR output so that it is one bit per cycle.
 */
module mpc4922(
	input clk,
	input reset,

	// physical interface
	output cs_pin,
	output clk_pin,
	output data_pin,

	// logical interface
	input [11:0] value,
	input axis,
	input strobe,
	output ready
);
	parameter GAIN = 1'b1; // Normal gain
	parameter BUFFERED = 1'b1; // buffered
	parameter SHUTDOWN = 1'b1; // not shutdown

	reg [15:0] cmd;
	reg [4:0] bits;
	assign ready = !reset && bits == 0;
	assign cs_pin = ready; // negative logic
	assign data_pin = cmd[15];

	always @(posedge clk)
	begin
		if (reset) begin
			bits <= 0;
			clk_pin <= 0;
		end else
		if (strobe) begin
			cmd <= { axis, BUFFERED, GAIN, SHUTDOWN, value };
			bits <= 16;
			clk_pin <= 0;
		end else
		if (bits != 0) begin
			if (clk_pin) begin
				// change when it is currently high
				cmd <= { cmd[14:0], 1'b0 };
				clk_pin <= 0;
				bits <= bits - 1;
			end else begin
				// rising edge clocks the data
				clk_pin <= 1;
			end
		end else begin
			clk_pin <= 0;
		end
	end

endmodule
