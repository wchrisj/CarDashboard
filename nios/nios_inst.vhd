	component Nios is
		port (
			clk_50_clk          : in  std_logic                     := 'X';             -- clk
			led_a_center_export : in  std_logic_vector(16 downto 0) := (others => 'X'); -- export
			led_b_center_export : in  std_logic_vector(16 downto 0) := (others => 'X'); -- export
			led_c_center_export : in  std_logic_vector(16 downto 0) := (others => 'X'); -- export
			leds_export         : out std_logic_vector(16 downto 0);                    -- export
			ps2_location_export : out std_logic_vector(4 downto 0);                     -- export
			reset_50_reset_n    : in  std_logic                     := 'X'              -- reset_n
		);
	end component Nios;

	u0 : component Nios
		port map (
			clk_50_clk          => CONNECTED_TO_clk_50_clk,          --       clk_50.clk
			led_a_center_export => CONNECTED_TO_led_a_center_export, -- led_a_center.export
			led_b_center_export => CONNECTED_TO_led_b_center_export, -- led_b_center.export
			led_c_center_export => CONNECTED_TO_led_c_center_export, -- led_c_center.export
			leds_export         => CONNECTED_TO_leds_export,         --         leds.export
			ps2_location_export => CONNECTED_TO_ps2_location_export, -- ps2_location.export
			reset_50_reset_n    => CONNECTED_TO_reset_50_reset_n     --     reset_50.reset_n
		);

