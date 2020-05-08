	component nios is
		port (
			clk_clk            : in  std_logic                     := 'X';             -- clk
			ps2_control_export : out std_logic_vector(1 downto 0);                     -- export
			ps2_flags_export   : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
			ps2_receive_export : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- export
			ps2_send_export    : out std_logic_vector(7 downto 0);                     -- export
			reset_reset_n      : in  std_logic                     := 'X';             -- reset_n
			leds_export        : out std_logic_vector(17 downto 0)                     -- export
		);
	end component nios;

	u0 : component nios
		port map (
			clk_clk            => CONNECTED_TO_clk_clk,            --         clk.clk
			ps2_control_export => CONNECTED_TO_ps2_control_export, -- ps2_control.export
			ps2_flags_export   => CONNECTED_TO_ps2_flags_export,   --   ps2_flags.export
			ps2_receive_export => CONNECTED_TO_ps2_receive_export, -- ps2_receive.export
			ps2_send_export    => CONNECTED_TO_ps2_send_export,    --    ps2_send.export
			reset_reset_n      => CONNECTED_TO_reset_reset_n,      --       reset.reset_n
			leds_export        => CONNECTED_TO_leds_export         --        leds.export
		);

