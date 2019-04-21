`include "mpc4922.v"

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

	reg [11:0] value_x;
	reg [11:0] value_y;
	reg axis;
	reg dac_strobe;
	wire dac_ready;

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

		if (!dac_ready || dac_strobe)
		begin
			// do nothing
		end else //if (counter == 0)
		begin
			if (axis)
				value_x <= value_x - 3;
			else
				value_y <= value_y + 7;

			dac_strobe <= 1;
			axis <= !axis;
		end
	end
endmodule
