
module nios (
	clk_clk,
	ps2_control_export,
	ps2_flags_export,
	ps2_receive_export,
	ps2_send_export,
	reset_reset_n,
	leds_export);	

	input		clk_clk;
	output	[1:0]	ps2_control_export;
	input	[1:0]	ps2_flags_export;
	input	[7:0]	ps2_receive_export;
	output	[7:0]	ps2_send_export;
	input		reset_reset_n;
	output	[17:0]	leds_export;
endmodule
