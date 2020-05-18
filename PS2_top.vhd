LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity PS2_top is
	port(
		GPIO					: INOUT STD_LOGIC_VECTOR(25 downto 23);
		CLOCK_50				: IN STD_LOGIC;
	   KEY	 				: IN STD_LOGIC_VECTOR(0 downto 0);
		moveUp				: IN STD_LOGIC;
		moveDown				: IN STD_LOGIC;
		moveLeft				: IN STD_LOGIC;
		moveRight			: IN STD_LOGIC;
		movementReceived	: OUT STD_LOGIC;
		sampleRate			: OUT STD_LOGIC_VECTOR(2 downto 0);
		resolution			: OUT STD_LOGIC_VECTOR(1 downto 0);
		scaling				: OUT STD_LOGIC;
		dataReporting		: OUT STD_LOGIC;
		LEDG					: OUT STD_LOGIC_VECTOR(7 downto 0);
		LEDR					: OUT STD_LOGIC_VECTOR(17 downto 0)
	);
end entity;

architecture default of PS2_top is
	component nios is
		port (
			clk_clk        : in  std_logic                    := '0'; --     clk.clk
			ps2_loc_export : out std_logic_vector(4 downto 0);        -- ps2_loc.export
			reset_reset_n  : in  std_logic                    := '0'  --   reset.reset_n
		);
	end component nios;

	component PS2 IS
		 PORT(
			  PS2_CLK   			: INOUT STD_LOGIC;
			  PS2_DATA   			: INOUT STD_LOGIC;
			  PS2_RESET				: IN STD_LOGIC;
			  clk 					: IN STD_LOGIC;
			  reset					: IN STD_LOGIC;
			  wrte					: IN STD_LOGIC; -- 0 = lezen, 1 = schrijven
			  start					: IN STD_LOGIC; -- Voor zenden
			  inputData				: IN STD_LOGIC_VECTOR(7 downto 0);
			  receivedData 		: OUT STD_LOGIC_VECTOR(7 downto 0);
			  interruptReceived 	: OUT STD_LOGIC; -- Er is data ontvangen
			  sendReady				: OUT STD_LOGIC; -- De data is verzonden
			  test2	 				: OUT STD_LOGIC_VECTOR(5 downto 0));
	end component PS2;
	
	component PS2_decode is
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
	end component;
	
	component Prescaler is
		port(clk, reset : STD_LOGIC;
				clkout : OUT STD_LOGIC);
	end component Prescaler;
	
	component PS2_calculateMove is
		port(
			clk		: IN STD_LOGIC;
			reset		: IN STD_LOGIC;
			cLoc		: IN STD_LOGIC_VECTOR(4 downto 0);
			nextMove	: OUT STD_LOGIC_VECTOR(1 downto 0) -- 00 blijf waar je bent, 01 ga naar rechts, 10 ga naar links, 11 bestaat niet
		);
	end component;
	
	SIGNAL wrteSignal : STD_LOGIC;
	SIGNAL startSignal : STD_LOGIC;
	SIGNAL sendData : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL receiveData : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL receivedInterruptSignal : STD_LOGIC;
	SIGNAL sendReadySignal : STD_LOGIC;
	SIGNAL PS2_prescaledClk : STD_LOGIC;
	
	SIGNAL cLocSignal : STD_LOGIC_VECTOR(4 downto 0);
	SIGNAL nextMoveSignal : STD_LOGIC_VECTOR(1 downto 0);
	
	begin	
		niosPM : nios PORT MAP (
			clk_clk       	 	=> CLOCK_50,
			ps2_loc_export		=> cLocSignal,
			reset_reset_n 		=> KEY(0)
		);
	
		PS2_sendreceivePM : PS2 PORT MAP (
			PS2_CLK   			=> GPIO(25),
			PS2_DATA   			=> GPIO(23),
			PS2_RESET			=> GPIO(24),
			clk 					=> PS2_prescaledClk,
			reset	 				=> KEY(0),
			wrte					=> wrteSignal, -- 0 = lezen, 1 = schrijven
			start					=> startSignal, -- Voor zenden
			inputData			=> sendData,
			receivedData 		=> receiveData,
			interruptReceived => receivedInterruptSignal, -- Er is data ontvangen
			sendReady			=> sendReadySignal, -- De data is verzonden
			test2	 				=> LEDG(5 downto 0)				
		);
		
		PS2_decodePM : PS2_decode PORT MAP (
			PS2_RESET			=> GPIO(24),
			clk 					=> PS2_prescaledClk,
			reset	 				=> KEY(0),
			receivedData 		=> receiveData,
			sendReady			=> sendReadySignal,
			receiverReady		=> receivedInterruptSignal,
			inputData			=> sendData,
			wrte					=> wrteSignal,
			start					=> startSignal,
			sampleRate			=> sampleRate,
			resolution			=> resolution,
			scaling				=> scaling,
			dataReporting		=> dataReporting,
			move					=> nextMoveSignal
		);
		
		ps2PrescalerPM : prescaler PORT MAP (
			clk					=> CLOCK_50,
			reset					=> KEY(0),
			clkout				=> PS2_prescaledClk
		);
		
		ps2_calculateMovePM : PS2_calculateMove PORT MAP (
			clk					=> PS2_prescaledClk,
			reset					=> GPIO(24),
			cLoc					=> cLocSignal,
			nextMove				=> nextMoveSignal
		);
 	
end architecture;