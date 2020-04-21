LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.numeric_std.all;

entity PS2_clockdivider is
	port(
		clkIn : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		clk1	: OUT STD_LOGIC;
		clk2	: OUT STD_LOGIC
	);
end entity;

architecture default of PS2_clockdivider is
	begin
		process(clkIn, reset)
			variable changeClock : INTEGER RANGE 0 TO 1;
			variable clk1Value : INTEGER RANGE 0 TO 1;
			variable clk2Value : INTEGER RANGE 0 TO 1;
			
			begin
				if reset = '1' then
					changeClock := 0;
					clk1Value := 0;
					clk2Value := 0;
				elsif rising_edge(clkIn) then
					if changeClock = 1 then
						changeClock := 0;
						if clk1Value = 1 then
							clk1Value := 0;
							clk1 <= '0';
						else
							clk1Value := 1;
							clk1 <= '1';
						end if;
					else
						changeClock := 1;
						if clk2Value = 1 then
							clk2Value := 0;
							clk2 <= '0';
						else
							clk2Value := 1;
							clk2 <= '1';
						end if;							
					end if;
				end if;
		end process;
end architecture;