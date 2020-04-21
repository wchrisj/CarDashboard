LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.numeric_std.all;

entity PS2 is
	port(
		clk 			: 	IN STD_LOGIC;
		reset			:	IN STD_LOGIC;
		start			: 	IN STD_LOGIC;
		data			: 	IN STD_LOGIC_VECTOR(7 downto 0);
		wrte			: 	IN STD_LOGIC;
		clkOut 		:	INOUT STD_LOGIC;
		dataOut		:	INOUT STD_LOGIC;
		sendReady	:	OUT STD_LOGIC;
		test			:	OUT STD_LOGIC;
		InterruptReceived : OUT STD_LOGIC;
		receivedData : OUT STD_LOGIC_VECTOR(7 downto 0)
	);
end entity;

architecture default of PS2 is
	component Prescaler is
		port(off, clk, reset : STD_LOGIC;
				CS : IN STD_LOGIC_VECTOR(2 downto 0);
				clkout : OUT STD_LOGIC);
	end component Prescaler;
	
	component PS2_clockdivider is
		port(
			clkIn : IN STD_LOGIC;
			reset : IN STD_LOGIC;
			clk1	: OUT STD_LOGIC;
			clk2	: OUT STD_LOGIC
		);
	end component;
	
	component PS2_send is
		port(
			clk 			: 	IN STD_LOGIC;
			reset			:	IN STD_LOGIC;
			start			: 	IN STD_LOGIC;
			enable		:	IN STD_LOGIC;
			data			: 	IN STD_LOGIC_VECTOR(7 downto 0);
			ready			:	OUT STD_LOGIC;
			dataOut		:	OUT STD_LOGIC
		);
	end component;
	
	component PS2_receive is
	port(
		data				: IN STD_LOGIC;
		enable			: IN STD_LOGIC;
		reset				: IN STD_LOGIC;
		clk				: IN STD_LOGIC;
		output			: OUT STD_LOGIC_VECTOR(7 downto 0);
		ready 			: OUT STD_LOGIC
	);
end component;
	
	signal clkData : STD_LOGIC;
	signal clkIn : STD_LOGIC;
	signal SENDER_enabled : STD_LOGIC;
	signal sendReady2 : STD_LOGIC;
	signal receivedInterrupt : STD_LOGIC;
	signal SENDER_data : STD_LOGIC;
	signal SENDER_clock : STD_LOGIC;
	signal RECEIVER_data : STD_LOGIC;
	signal RECEIVER_clock : STD_LOGIC;
	signal RECEIVER_enabled : STD_LOGIC;
	
	
	-- Build an enumerated type for the state machine
	type state_type is (sending, receiving, rust);

	-- Register to hold the current state
	signal state   : state_type;
	
	begin	
		portmapPrescaler : Prescaler port map ('1', clk, reset, "010", clkData);
		clockdivider : PS2_clockdivider port map (clkData, reset, SENDER_clock, clkIn);
		sender : PS2_send port map (clkIn, reset, start, SENDER_enabled, data, sendReady2, SENDER_data);
		receiver : PS2_receive port map (RECEIVER_data, RECEIVER_enabled, reset, clkIn, receivedData, receivedInterrupt);
		
		sendReady <= sendReady2;
		InterruptReceived <= receivedInterrupt;
		
		process(receivedInterrupt, sendReady2, reset, start)			
			begin
				if reset = '1' then
					state <= rust;
				elsif start = '1' then
					if wrte = '1' then
						state <= sending;	
					else 
						state <= receiving;
					end if;
				elsif sendReady2 = '1' then
					state <= rust;
				elsif receivedInterrupt = '1' then
					state <= rust;
				end if;
		end process;
		
		process (state)
		begin
			case state is
				when sending =>
					clkOut <= SENDER_clock;
					dataOut <= SENDER_data;
					SENDER_enabled <= '1';
					RECEIVER_enabled <= '0';
				when receiving =>
					clkOut <= SENDER_clock;
					RECEIVER_data <= dataOut;
					SENDER_enabled <= '0';
					RECEIVER_enabled <= '1';
				when rust =>
					clkOut <= 'Z';
					dataOut <= 'Z';
					SENDER_enabled <= '0';
					RECEIVER_enabled <= '0';
			end case;
		end process;
		
		test <= clkIn;
end architecture;