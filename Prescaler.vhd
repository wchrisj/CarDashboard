LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity Prescaler is
	port(clk, reset : STD_LOGIC;
			clkout : OUT STD_LOGIC);
end entity Prescaler;

architecture default of Prescaler is	
	signal output : STD_LOGIC;

	begin
		process(clk, reset)
			variable counter : INTEGER RANGE 0 TO 2047;
			begin
				if reset = '0' then
					counter := 0;
					output <= '0';
				elsif rising_edge(clk) then
					counter := counter + 1;
					if counter = 2047 then
						counter := 0;
						output <= NOT output;
					end if;
				end if;
		end process;
		clkout <= output;
end architecture default;