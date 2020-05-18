LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;

ENTITY PS2 IS
    PORT(
        PS2_CLK   			: INOUT STD_LOGIC;
        PS2_DATA   			: INOUT STD_LOGIC;
		  PS2_RESET				: IN STD_LOGIC;
        clk 					: IN STD_LOGIC;
		  reset	 				: IN STD_LOGIC;
		  wrte					: IN STD_LOGIC; -- 0 = lezen, 1 = schrijven
		  start					: IN STD_LOGIC; -- Voor zenden
		  inputData				: IN STD_LOGIC_VECTOR(7 downto 0);
		  receivedData 		: OUT STD_LOGIC_VECTOR(7 downto 0);
		  interruptReceived 	: OUT STD_LOGIC; -- Er is data ontvangen
		  sendReady				: OUT STD_LOGIC; -- De data is verzonden
		  test2	 				: OUT STD_LOGIC_VECTOR(5 downto 0));
END PS2;

ARCHITECTURE default OF PS2 IS
                                             -- value from input.
SIGNAL PS2_clk_received  : STD_LOGIC; 
SIGNAL PS2_clk_send  : STD_LOGIC := '0';  
SIGNAL PS2_data_received  : STD_LOGIC; 
SIGNAL PS2_data_send  : STD_LOGIC;

SIGNAL PS2_CLK_OE : STD_LOGIC;
SIGNAL PS2_DATA_OE : STD_LOGIC;

SIGNAL parity : STD_LOGIC;

SIGNAL temp : STD_LOGIC := '1';

SIGNAL sendACK : STD_LOGIC;

SIGNAL ackByte : STD_LOGIC_VECTOR(7 downto 0) := "11111010";

SIGNAL countWait : INTEGER RANGE 0 to 2047;
SIGNAL countSendWait : INTEGER RANGE 0 to 50;


-- Build an enumerated type for the state machine
type state_type is (receiving_rust, receiving_clockHost, receiving_startbit, receiving_1, receiving_2, receiving_3, receiving_4, receiving_5, receiving_6, receiving_7, receiving_8, receiving_parity, receiving_stop, receiving_ack, receiving_final,
sending_ackBytewait, sending_startbit, sending_1, sending_2, sending_3, sending_4, sending_5, sending_6, sending_7, sending_8, sending_parity, sending_stop, sending_wait);

-- Register to hold the current state
signal state   : state_type;

component oddParity is
	port(
		data : IN STD_LOGIC_VECTOR(7 downto 0);
		output : OUT STD_LOGIC
	);
end component;

--SIGNAL  started : STD_LOGIC;
BEGIN        
	 -- feedback value.
	 parityPM : oddParity PORT MAP (inputData, parity);
	 
    PROCESS(clk)
    BEGIN
    IF falling_edge(clk) THEN  -- Creates the flipflops
        PS2_clk_send <= NOT PS2_clk_send;                        
	 END IF;
    END PROCESS;    
    PROCESS (PS2_CLK_OE, PS2_CLK)          -- LEEST EN SCHRIJFT VAN DE CLK
        BEGIN                    -- of tri-states. -- LEZEN
        IF( PS2_CLK_OE = '0') THEN
            PS2_CLK <= 'Z';
				if PS2_CLK = '0' OR PS2_CLK = 'L' then
					PS2_clk_received <= '0';
				else
					PS2_clk_received <= '1';
				end if;
        ELSE -- SCHRIJVEN
            PS2_CLK <= PS2_clk_send;
				PS2_clk_received <= PS2_CLK;
        END IF;
    END PROCESS;
	 PROCESS (PS2_DATA_OE, PS2_DATA)          -- LEEST EN SCHRIJF DATA
        BEGIN                    -- of tri-states. -- LEZEN
        IF( PS2_DATA_OE = '0') THEN
            PS2_DATA <= 'Z';
				if PS2_DATA = '0' OR PS2_DATA = 'L' then
					PS2_data_received <= '0';
				else
					PS2_data_received <= '1';
				end if;
        ELSE -- SCHRIJVEN
            PS2_DATA <= PS2_data_send;
				PS2_data_received <= PS2_DATA;
        END IF;
    END PROCESS;
	 
	 process(reset, PS2_RESET, clk)
		begin
			if reset = '0' then
				state <= receiving_rust;
			elsif PS2_RESET = '0' then
				state <= receiving_rust;			
			elsif rising_edge(clk) then
				if temp = '1' then
					temp <= '0';
				else
					temp <= '1';
					case state is
						when receiving_rust =>
							if wrte = '0' then
								if PS2_clk_received = '0' then -- Dus de klok is laag gemaakt
									state <= receiving_clockHost;
								else
									state <= receiving_rust;
								end if;
							else
								if start = '1' then
									sendACK <= '0';
									state <= sending_startbit;								
								else
									state <= receiving_rust;								
								end if;
							end if;
						when receiving_clockHost =>  -- Clock is hoog geworden
							if PS2_clk_received = '1' then
								if PS2_data_received = '0' then
									state <= receiving_1;						
								else
									state <= receiving_startbit;
								end if;
							else
								state <= receiving_clockHost;						
							end if;
						when receiving_startbit =>
							if PS2_data_received = '0' then
								state <= receiving_1;						
							else
								state <= receiving_startbit;
							end if;
						when receiving_1 =>
								state <= receiving_2;
						when receiving_2 =>
								state <= receiving_3;
						when receiving_3 =>
								state <= receiving_4;
						when receiving_4 =>
								state <= receiving_5;
						when receiving_5 =>
								state <= receiving_6;
						when receiving_6 =>
								state <= receiving_7;
						when receiving_7 =>
								state <= receiving_8;
						when receiving_8 =>
								state <= receiving_parity;	
						when receiving_parity =>
								state <= receiving_stop;
						when receiving_stop =>
							if PS2_data_received = '1' then
								state <= receiving_ack;
							else
								state <= receiving_stop;
							end if;
						when receiving_final =>
							if start = '1' AND wrte = '1' then
								state <= sending_startbit;
							elsif start = '1' OR wrte = '1' then
								state <= receiving_rust;							
							else
								state <= receiving_final;	
							end if;				
						when receiving_ack => -- Geven tijd om data te lezen
							sendACK <= '1';
							countWait <= 0;
							state <= sending_ackBytewait;	
						when sending_ackBytewait =>
							if countWait = 4 then
								state <= sending_startbit;
							else
								countWait <= countWait + 1;
								state <= sending_ackBytewait;
							end if;
						when sending_startbit =>
							state <= sending_1;	
						when sending_1 =>
							state <= sending_2;
						when sending_2 =>
							state <= sending_3;
						when sending_3 =>
							state <= sending_4;
						when sending_4 =>
							state <= sending_5;
						when sending_5 =>
							state <= sending_6;
						when sending_6 =>
							state <= sending_7;
						when sending_7 =>
							state <= sending_8;
						when sending_8 =>
							state <= sending_parity;	
						when sending_parity =>
							state <= sending_stop;		
						when sending_stop =>
							state <= sending_wait;
						when sending_wait =>
							if countSendWait = 17 then
								if sendACK = '0' then
									state <= receiving_rust;							
								else
									sendACK <= '0';
									state <= receiving_final;	
								end if;		
							else
								countSendWait <= countSendWait + 1;
								state <= sending_wait;								
							end if;
						when others =>
							state <= receiving_rust;
					end case;
				end if;
			end if;
	end process;
	
	process(state)
		begin
			case state is
				when receiving_rust =>
					test2 <= "000000";
					PS2_CLK_OE <= '0'; -- wij gaan lezen van de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					interruptReceived <= '0'; -- meld even dat je data heeft
					sendReady <= '1'; -- We kunnen data gaan versturen
				when receiving_clockHost =>
					test2 <= "000001";
					PS2_CLK_OE <= '0'; -- wij gaan lezen van de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
        PS2_data_send <= '0';   
--					receivedData <= "00000000"; -- Clear de oude data
				when receiving_startbit =>
					test2 <= "000010";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_1 =>
					test2 <= "000011";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					receivedData(0) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_2 =>
					test2 <= "000100";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					receivedData(1) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_3 =>
					test2 <= "000101";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					receivedData(2) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_4 =>
					test2 <= "000110";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					receivedData(3) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_5 =>
					test2 <= "000111";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					receivedData(4) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_6 =>
					test2 <= "001000";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					receivedData(5) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_7 =>
					test2 <= "001001";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					receivedData(6) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_8 =>
					test2 <= "001010";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					receivedData(7) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_parity =>
					test2 <= "001011";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_stop =>
					test2 <= "001100";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_ack =>
					test2 <= "001101";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
        PS2_data_send <= '0';   
					interruptReceived <= '1'; -- meld even dat je data heeft
					sendReady <= '0'; -- We gaan zo bezig met versturen van data
				when receiving_final =>
					test2 <= "001110";
					PS2_CLK_OE <= '0'; -- wij gaan lezen van de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
        PS2_data_send <= '0';   
					interruptReceived <= '1'; -- meld even dat je data heeft
				when sending_ackBytewait =>
					test2 <= "100000";
					PS2_CLK_OE <= '0'; -- wij gaan lezen van de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					PS2_data_send <= '0';   
					interruptReceived <= '1'; -- meld even dat je data heeft
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_startbit =>
					test2 <= "001111";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					PS2_data_send <= '0'; -- Stuur een startbit
					if sendAck = '1' then
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_1 =>
					test2 <= "010000";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					if sendACK = '1' then -- sturen wij normale data of het acknowledge byte?
						PS2_data_send <= ackByte(0); -- stuur een acknowlegde bit
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						PS2_data_send <= inputData(0); -- Stuur een databit
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_2 =>
					test2 <= "010001";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					if sendACK = '1' then -- sturen wij normale data of het acknowledge byte?
						PS2_data_send <= ackByte(1); -- stuur een acknowlegde bit
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						PS2_data_send <= inputData(1); -- Stuur een databit
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_3 =>
					test2 <= "010010";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					if sendACK = '1' then -- sturen wij normale data of het acknowledge byte?
						PS2_data_send <= ackByte(2); -- stuur een acknowlegde bit
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						PS2_data_send <= inputData(2); -- Stuur een databit
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_4 =>
					test2 <= "010011";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					if sendACK = '1' then -- sturen wij normale data of het acknowledge byte?
						PS2_data_send <= ackByte(3); -- stuur een acknowlegde bit
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						PS2_data_send <= inputData(3); -- Stuur een databit
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_5 =>
					test2 <= "010100";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					if sendACK = '1' then -- sturen wij normale data of het acknowledge byte?
						PS2_data_send <= ackByte(4); -- stuur een acknowlegde bit
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						PS2_data_send <= inputData(4); -- Stuur een databit
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_6 =>
					test2 <= "010101";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					if sendACK = '1' then -- sturen wij normale data of het acknowledge byte?
						PS2_data_send <= ackByte(5); -- stuur een acknowlegde bit
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						PS2_data_send <= inputData(5); -- Stuur een databit
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_7 =>
					test2 <= "010110";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					if sendACK = '1' then -- sturen wij normale data of het acknowledge byte?
						PS2_data_send <= ackByte(6); -- stuur een acknowlegde bit
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						PS2_data_send <= inputData(6); -- Stuur een databit
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_8 =>
					test2 <= "010111";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					if sendACK = '1' then -- sturen wij normale data of het acknowledge byte?
						PS2_data_send <= ackByte(7); -- stuur een acknowlegde bit
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						PS2_data_send <= inputData(7); -- Stuur een databit
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_parity =>
					test2 <= "011000";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					if sendACK = '1' then -- sturen wij normale data of het acknowledge byte?
						PS2_data_send <= '1'; -- stuur een acknowlegde paritybit
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						PS2_data_send <= parity; -- Stuur een paritybit
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_stop =>
					test2 <= "011001";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					PS2_data_send <= '1'; -- Stuur een stopbit
					if sendAck = '1' then
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
				when sending_wait =>
					test2 <= "111111";
					PS2_CLK_OE <= '0'; -- wij gaan lezen van de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					PS2_data_send <= '0'; -- Stuur niks
					if sendAck = '1' then
						interruptReceived <= '1'; -- meld even dat je data heeft
					else
						interruptReceived <= '0'; -- meld even dat je data heeft
					end if;
					sendReady <= '0'; -- We zijn bezig met versturen van data
			end case;
	end process;
END default;