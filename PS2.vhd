LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.numeric_std.all;

entity PS2 is
	port(
		clk 			: 	IN STD_LOGIC;
		reset			:	IN STD_LOGIC;
		start			: 	IN STD_LOGIC;
		data			: 	IN STD_LOGIC_VECTOR(7 downto 0);
		clkOut 		:	OUT STD_LOGIC;
		ready			:	OUT STD_LOGIC;
		test			:	OUT STD_LOGIC;
		dataOut		:	OUT STD_LOGIC
	);
end entity;

architecture default of PS2 is
	component Prescaler is
		port(off, clk, reset : STD_LOGIC;
				CS : IN STD_LOGIC_VECTOR(2 downto 0);
				clkout : OUT STD_LOGIC);
	end component Prescaler;
	
	component oddParity is
		port(
			data : IN STD_LOGIC_VECTOR(7 downto 0);
			output : OUT STD_LOGIC
		);
	end component;
	
	signal clkData : STD_LOGIC;
	signal parity : STD_LOGIC;
	
	begin	
		portmapPrescaler : Prescaler port map ('1', clk, reset, "010", clkData);
		portmapParity : oddParity port map (data, parity);
		
		process(clkData, reset, start)
			variable changeClock : INTEGER RANGE 0 TO 1;
			variable countBit		: INTEGER RANGE 0 TO 11;
			variable clkOutSignal : INTEGER RANGE 0 TO 1;
			variable sending : INTEGER RANGE 0 TO 1;
			
			begin
				if reset = '1' then
					countBit := 0;
					clkOutSignal := 0;
					changeClock := 0;
					ready <= '1';
					sending := 0;
				elsif start = '1' then
					countBit := 0;
					clkOutSignal := 0;
					changeClock := 0;
					ready <= '0';
					sending := 1;					
				elsif rising_edge(clkData) then
					if sending = 1 then
						if changeClock = 1 then
							changeClock := 0;
							-- UPDATE CLOCK
							if clkOutSignal = 1 then
								clkOutSignal := 0;
								clkOut <= '0';
							else
								clkOutSignal := 1;
								clkOut <= '1';
							end if;
						else
							changeClock := 1;
							-- UPDATA DATA
							case countBit is
								when 0 => dataOut <= '0';
								when 1 => dataOut <= data(0);
								when 2 => dataOut <= data(1);
								when 3 => dataOut <= data(2);
								when 4 => dataOut <= data(3);
								when 5 => dataOut <= data(4);
								when 6 => dataOut <= data(5);
								when 7 => dataOut <= data(6);
								when 8 => dataOut <= data(7);
								when 9 => dataOut <= parity;
								when 10 => dataOut <= '1';
								when others => null;
							end case;
							countBit := countBit + 1;
							if countBit = 11 then
								countBit := 0;
								sending := 0;
								ready <= '1';
							end if;
						end if;
					end if;
				end if;
		end process;
		
		test <= clkData;
end architecture;