
module Nios (
	clk_50_clk,
	led_a_center_export,
	led_b_center_export,
	led_c_center_export,
	leds_export,
	ps2_location_export,
	reset_50_reset_n);	

	input		clk_50_clk;
	input	[16:0]	led_a_center_export;
	input	[16:0]	led_b_center_export;
	input	[16:0]	led_c_center_export;
	output	[16:0]	leds_export;
	output	[4:0]	ps2_location_export;
	input		reset_50_reset_n;
endmodule
