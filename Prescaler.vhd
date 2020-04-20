LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity Prescaler is
	port(off, clk, reset : STD_LOGIC;
			CS : IN STD_LOGIC_VECTOR(2 downto 0);
			clkout : OUT STD_LOGIC);
end entity Prescaler;

architecture default of Prescaler is	
	signal output : STD_LOGIC;

	begin
		process(clk, reset)
			variable counter : INTEGER RANGE 0 TO 4095;
			begin
				if reset = '1' then
					counter := 0;
					output <= '0';
				elsif rising_edge(clk) then
					counter := counter + 1;
					if counter = 2 then
						counter := 0;
						output <= NOT output;
					end if;
				end if;
		end process;
		clkout <= output;
end architecture default;