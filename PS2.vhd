LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY PS2 IS
    PORT(
        PS2_CLK   			: INOUT STD_LOGIC;
        PS2_DATA   			: INOUT STD_LOGIC;
        clk 					: IN STD_LOGIC;
		  reset	 				: IN STD_LOGIC;
		  wrte					: IN STD_LOGIC; -- 0 = lezen, 1 = schrijven
		  start					: IN STD_LOGIC; -- Voor zenden
		  inputData				: IN STD_LOGIC_VECTOR(7 downto 0);
		  receivedData 		: OUT STD_LOGIC_VECTOR(7 downto 0);
		  interruptReceived 	: OUT STD_LOGIC; -- Er is data ontvangen
		  interruptSend		: OUT STD_LOGIC; -- De data is verzonden
		  test2	 				: OUT STD_LOGIC_VECTOR(3 downto 0));
END PS2;

ARCHITECTURE default OF PS2 IS
                                             -- value from input.
SIGNAL PS2_clk_received  : STD_LOGIC; 
SIGNAL PS2_clk_send  : STD_LOGIC := '0';  
SIGNAL PS2_data_received  : STD_LOGIC; 
SIGNAL PS2_data_send  : STD_LOGIC; 

SIGNAL PS2_CLK_OE : STD_LOGIC;
SIGNAL PS2_DATA_OE : STD_LOGIC;

SIGNAL temp : STD_LOGIC := '1';


-- Build an enumerated type for the state machine
type state_type is (receiving_rust, receiving_clockHost, receiving_startbit, receiving_1, receiving_2, receiving_3, receiving_4, receiving_5, receiving_6, receiving_7, receiving_8, receiving_parity, receiving_stop, receiving_ack, receiving_final);

-- Register to hold the current state
signal state   : state_type;

--SIGNAL  started : STD_LOGIC;
BEGIN        
	 -- feedback value.
    PROCESS(clk)
    BEGIN
    IF falling_edge(clk) THEN  -- Creates the flipflops
        PS2_clk_send <= NOT PS2_clk_send;   
        PS2_data_send <= '0';                        
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
	 
	 process(clk)
		begin
			if reset = '0' then
				state <= receiving_rust;
			elsif rising_edge(clk) then
				if temp = '1' then
					temp <= '0';
				else
					temp <= '1';
					case state is
						when receiving_rust =>
							if PS2_clk_received = '0' then -- Dus de klok is laag gemaakt
								state <= receiving_clockHost;
							else
								state <= receiving_rust;
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
						when receiving_ack =>
								state <= receiving_final;	
						when receiving_final => -- Geven tijd om data te lezen
							if start = '1' then
								state <= receiving_rust;							
							else
								state <= receiving_final;	
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
					test2 <= "0000";
					PS2_CLK_OE <= '0'; -- wij gaan lezen van de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					interruptReceived <= '0'; -- meld even dat je data heeft
				when receiving_clockHost =>
					test2 <= "0001";
					PS2_CLK_OE <= '0'; -- wij gaan lezen van de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
					receivedData <= "00000000"; -- Clear de oude data
				when receiving_startbit =>
					test2 <= "0010";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_1 =>
					test2 <= "0011";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					receivedData(0) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_2 =>
					test2 <= "0100";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					receivedData(1) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_3 =>
					test2 <= "0101";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					receivedData(2) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_4 =>
					test2 <= "0110";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					receivedData(3) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_5 =>
					test2 <= "0111";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					receivedData(4) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_6 =>
					test2 <= "1000";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					receivedData(5) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_7 =>
					test2 <= "1001";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					receivedData(6) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_8 =>
					test2 <= "1010";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					receivedData(7) <= PS2_data_received; --  Sla het bit op in de output
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_parity =>
					test2 <= "1011";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_stop =>
					test2 <= "1100";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan lezen van de data lijn
					interruptReceived <= '0'; -- zorg dat niemand de data gaat lezen
				when receiving_ack =>
					test2 <= "1101";
					PS2_CLK_OE <= '1'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '1'; -- Wij gaan schrijven op de data lijn
					interruptReceived <= '1'; -- meld even dat je data heeft
				when receiving_final =>
					test2 <= "1110";
					PS2_CLK_OE <= '0'; -- wij gaan schrijven op de clock lijn
					PS2_DATA_OE <= '0'; -- Wij gaan schrijven op de data lijn
					interruptReceived <= '1'; -- meld even dat je data heeft
			end case;
	end process;
END default;