LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;

entity PS2_decode is
	port(
		PS2_RESET		: IN STD_LOGIC;
		clk 				: IN STD_LOGIC;
		reset 			: IN STD_LOGIC;
		receivedData 	: IN STD_LOGIC_VECTOR(7 downto 0);
		sendReady		: IN STD_LOGIC;
		receiverReady	: IN STD_LOGIC;
		inputData		: OUT STD_LOGIC_VECTOR(7 downto 0);
		wrte				: OUT STD_LOGIC;
		start				: OUT STD_LOGIC;
		sampleRate		: OUT STD_LOGIC_VECTOR(2 downto 0);
		resolution		: OUT STD_LOGIC_VECTOR(1 downto 0);
		scaling			: OUT STD_LOGIC;
		dataReporting	: OUT STD_LOGIC;
		move				: IN STD_LOGIC_VECTOR(1 downto 0)
	);
end entity;

architecture default of PS2_decode is	
	SIGNAL sendBuffer1 : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL sendBuffer2 : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL sendBuffer3 : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL remainingBufferItems : INTEGER RANGE 0 to 3;
	SIGNAL nextItem : INTEGER RANGE 0 to 15;
	
	SIGNAL lastCommand : STD_LOGIC_VECTOR(7 downto 0);

	begin	
		process(reset, PS2_RESET, clk)
			begin
				if reset = '0' then
					remainingBufferItems <= 0;
					sendBuffer1 <= "00000000";
					sendBuffer2 <= "00000000";
					sendBuffer3 <= "00000000";
				elsif PS2_RESET = '0' then
					remainingBufferItems <= 0;	
					sendBuffer1 <= "00000000";
					sendBuffer2 <= "00000000";
					sendBuffer3 <= "00000000";
				elsif rising_edge(clk) then				
					if sendReady = '1' then
						if remainingBufferItems = 3 then
							inputData <= sendBuffer3;
							wrte <= '1';
							start <= '1';
							remainingBufferItems <= 2;
						elsif remainingBufferItems = 2 then
							inputData <= sendBuffer2;
							wrte <= '1';
							start <= '1';
							remainingBufferItems <= 1;
						elsif remainingBufferItems = 1 then
							inputData <= sendBuffer1;
							wrte <= '1';
							start <= '1';
							remainingBufferItems <= 0;
						else
							wrte <= '0';
							start <= '1';
						end if;
					end if;
					
					if receiverReady = '1' then
						if nextItem = 0 then
							case receivedData is
								when "11111111" => -- 0xFF Reset is ontvangen
									sendBuffer2 <= "10101010"; -- Stuur 0xAA (muis werkt)
									sendBuffer1 <= "00000000"; -- Stuur 0x00 (id = 0)
									remainingBufferItems <= 2; -- Er staan 2 items in het buffer
								when "11110011" => -- 0xF3 set Sample rate
									nextItem <= 1; -- volgende byte moet opgeslagen worden in sample rate
									lastCommand <= "11110011";
								when "11110101" => -- 0xF5 set data reporting false
									dataReporting <= '0';
								when "11110100" => -- 0xF4 set data reporting true
									dataReporting <= '1';
								when "11110010" => -- 0xF2 get device id
									sendBuffer1 <= "00000000"; -- Stuur 0x00 (id = 0)
									remainingBufferItems <= 1; -- Er staat 1 items in het buffer
								when "11101011" => -- 0xEB request data
									sendBuffer3 <= "00001000"; -- MOGEN WIJ NIET AANPASSEN???bit [0, 2] is voor muis knoppen dus 0 bit 3 is 1 voor een muis, bit 4 bepaald de richting van de x beweging, 5 is de richting van y = dus 0m 6 en 7 zijn overflow
									if move = "01" then
										sendBuffer2 <= "00000001"; -- Beweeg 1 naar rechts op de x as
									elsif move = "10" then
										sendBuffer2 <= "11111111"; -- Beweeg 1 naar links op de x as									
									else
										sendBuffer2 <= "00000000"; -- Beweeg niet op de x as									
									end if;
									sendBuffer1 <= "00000000"; -- beweeg niet op de y as
									remainingBufferItems <= 3; -- Er staan 3 items in het buffer	
								when "11101000" => -- 0xE8 set Resolution
									nextItem <= 2; -- volgende byte moet opgeslagen worden in resolutie
									lastCommand <= "11101000";
								when "11100111" => -- 0xE7 scaling 2:1
									scaling <= '1';
								when "11100110" => -- 0xE6 scaling 1:1
									scaling <= '0';
								when "11110000" => -- 0xF0 set remote mode
									-- remote mode
								when others =>
--										remainingBufferItems <= 0;
--										sendBuffer1 <= "00000000";
--										sendBuffer2 <= "00000000";
--										sendBuffer3 <= "00000000";
							end case;
						elsif lastCommand = receivedData then
						
						elsif nextItem = 1 then -- Sample rate
							nextItem <= 0;
							case receivedData is
								when "00001010" => -- 10
									sampleRate <= "000";
								when "00010100" => -- 20
									sampleRate <= "001";
								when "00101000" => -- 40
									sampleRate <= "010";
								when "01010000" => -- 80
									sampleRate <= "011";
								when "01100100" => -- 100
									sampleRate <= "100";
								when "11001000" => -- 200
									sampleRate <= "101";
								when others =>     -- Verkeerde input
									sampleRate <= "111";
							end case;
						elsif nextItem = 2 then -- Resolution
							nextItem <= 0;
							resolution <= receivedData(1 downto 0);
						end if;
						start <= '1'; -- Je mag weer verder..
					end if;
				end if;
		end process;
end architecture;