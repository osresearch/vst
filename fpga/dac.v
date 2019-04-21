`include "mpc4922.v"
`include "lineto.v"

module top(
	output led_r,
	output led_b,
	output gpio_2, // cs
	output gpio_46, // clk
	output gpio_47  // do
);
	wire reset = 0;
	wire clk_48mhz, clk = clk_48mhz;
	SB_HFOSC osc(1,1,clk_48mhz);

	reg [11:0] lineto_x;
	reg [11:0] lineto_y;
	reg lineto_strobe;

	wire lineto_ready;
	wire axis;
	wire [11:0] value_x;
	wire [11:0] value_y;
	reg dac_strobe;
	wire dac_ready;

	lineto #(.BITS(12)) drawer(
		.clk(clk),
		.reset(reset),
		.strobe(lineto_strobe),
		.x_in(lineto_x),
		.y_in(lineto_y),

		.ready(lineto_ready),
		.x_out(value_x),
		.y_out(value_y),
		.axis(axis)
	);

	mpc4922 dac(
		.clk(clk),
		.reset(reset),
		.cs_pin(gpio_2),
		.clk_pin(gpio_46),
		.data_pin(gpio_47),
		.value(axis ? value_x : value_y),
		.axis(axis),
		.strobe(dac_strobe),
		.ready(dac_ready)
	);

	reg [15:0] counter;
	always @(posedge clk) begin
		counter <= counter + 1;
		led_r = !(counter < value_x);
		led_b = 1; //!dac_strobe; //!(counter < value_y);
	end

	always @(posedge clk)
	begin
		dac_strobe <= 0;
		lineto_strobe <= 0;

		if (!dac_ready || dac_strobe)
		begin
			// do nothing
		end else //if (counter == 0)
		begin
			dac_strobe <= 1;
			lineto_x <= lineto_x + 3;
			lineto_y <= lineto_y + 2;

		end

		if (lineto_ready)
			lineto_strobe <= 1;
	end
endmodule
