LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.numeric_std.all;

entity PS2_receive is
	port(
		data				: IN STD_LOGIC;
		enable			: IN STD_LOGIC;
		reset				: IN STD_LOGIC;
		clk				: IN STD_LOGIC;
		output			: OUT STD_LOGIC_VECTOR(7 downto 0);
		ready 			: OUT STD_LOGIC
	);
end entity;

architecture default of PS2_receive is
	begin		
		process(clk, reset)
			variable step : INTEGER RANGE 0 TO 15;
			
			begin
				if reset = '1' then
					step := 0;
					ready <= '0';
					output <= "00000000";
				elsif rising_edge(clk) then
					if step = 0 then
						if enable = '1' then
							step := 1;
						end if;
					elsif step = 1 then
						if data = '0' then
							step := 2;
						end if;
					
					elsif step = 2 then
						step := 3;
						output(0) <= data;
					
					elsif step = 3 then
						step := 4;
						output(1) <= data;
					
					elsif step = 4 then
						step := 5;
						output(2) <= data;
					
					elsif step = 5 then
						step := 6;
						output(3) <= data;
					
					elsif step = 6 then
						step := 7;
						output(4) <= data;
					
					elsif step = 7 then 
						step := 8;
						output(5) <= data;
					
					elsif step = 8 then
						step := 9;
						output(6) <= data;
					
					elsif step = 9 then
						step := 10;
						output(7) <= data;
					
					else
						ready <= '1';
					end if;
				end if;
		end process;
end architecture;