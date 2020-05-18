LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;

entity PS2_calculateMove is
	port(
		clk		: IN STD_LOGIC;
		reset		: IN STD_LOGIC;
		cLoc		: IN STD_LOGIC_VECTOR(4 downto 0);
		nextMove	: OUT STD_LOGIC_VECTOR(1 downto 0) -- 00 blijf waar je bent, 01 ga naar rechts, 10 ga naar links, 11 bestaat niet
	);
end entity;

architecture default of PS2_calculateMove is
	SIGNAL currentLoc : INTEGER RANGE -15 to 15;
	
	SIGNAL TEMP : INTEGER RANGE 0 to 10000;

	begin
		process(reset, clk)
			VARIABLE cLocVariable	: INTEGER RANGE -15 to 15;
			begin
				if reset = '0' then
					currentLoc <= 0;
					TEMP <= 0;
				elsif rising_edge(clk) then
					if TEMP = 10000 then
						TEMP <= 0;
						cLocVariable := to_integer(signed(cLoc));
						if currentLoc = cLocVariable then -- We zijn op de goede plek
							nextMove <= "00";
						elsif currentLoc < cLocVariable then -- We moeten naar rechts
							nextMove <= "01";
							currentLoc <= currentLoc + 1;
						elsif currentLoc > cLocVariable then -- We moeten naar links
							nextMove <= "10";
							currentLoc <= currentLoc - 1;
						end if;
					else
						TEMP <= TEMP + 1;
					end if;
				end if;
		end process;
end architecture;