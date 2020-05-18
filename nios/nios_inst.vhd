	component nios is
		port (
			clk_clk        : in  std_logic                    := 'X'; -- clk
			ps2_loc_export : out std_logic_vector(4 downto 0);        -- export
			reset_reset_n  : in  std_logic                    := 'X'  -- reset_n
		);
	end component nios;

	u0 : component nios
		port map (
			clk_clk        => CONNECTED_TO_clk_clk,        --     clk.clk
			ps2_loc_export => CONNECTED_TO_ps2_loc_export, -- ps2_loc.export
			reset_reset_n  => CONNECTED_TO_reset_reset_n   --   reset.reset_n
		);

