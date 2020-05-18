LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

entity toplevel is
	port(
		CLOCK_50 : IN STD_LOGIC;
		KEY : IN STD_LOGIC_VECTOR(3 downto 0);
		GPIO : INOUT STD_LOGIC_VECTOR(35 downto 0);
		LEDR : OUT STD_LOGIC_VECTOR(17 downto 0);
		LEDG : OUT STD_LOGIC_VECTOR(7 downto 0)
	);
	
end entity;

architecture default of toplevel is
	component nios is
		port (
			clk_clk            : in  std_logic                     := '0';             --         clk.clk
			leds_export        : out std_logic_vector(17 downto 0);                    --        leds.export
			ps2_control_export : out std_logic_vector(1 downto 0);                     -- ps2_control.export
			ps2_flags_export   : in  std_logic_vector(1 downto 0)  := (others => '0'); --   ps2_flags.export
			ps2_receive_export : in  std_logic_vector(7 downto 0)  := (others => '0'); -- ps2_receive.export
			ps2_send_export    : out std_logic_vector(7 downto 0);                     --    ps2_send.export
			reset_reset_n      : in  std_logic                     := '0'              --       reset.reset_n
		);
	end component nios;
	
	component PS2 IS
		 PORT(
			  PS2_CLK   			: INOUT STD_LOGIC;
			  PS2_DATA   			: INOUT STD_LOGIC;
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
			testje			: OUT STD_LOGIC_VECTOR(1 downto 0)
		);
	end component;
	
	component Prescaler is
		port(clk, reset : STD_LOGIC;
				clkout : OUT STD_LOGIC);
	end component Prescaler;
	
	SIGNAL wrteSignal : STD_LOGIC;
	SIGNAL startSignal : STD_LOGIC;
	SIGNAL sendData : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL receiveData : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL receivedInterruptSignal : STD_LOGIC;
	SIGNAL sendReadySignal : STD_LOGIC;
	
	signal PS2wires : STD_LOGIC_VECTOR(19 downto 0);
	signal testWires : STD_LOGIC_VECTOR(8 downto 0);
	signal PS2_prescaledClk : STD_LOGIC; -- Dit is de prescaled clock die gebruikt word door PS2
	
	SIGNAL dataReporting : STD_LOGIC;
	SIGNAL scaling : STD_LOGIC;
	SIGNAL sampleRate : STD_LOGIC_VECTOR(2 downto 0);
	SIGNAL resolution : STD_LOGIC_VECTOR(1 downto 0);
	
	begin
		niosPM: nios PORT MAP (CLOCK_50, LEDR, PS2wires(19 downto 18), PS2wires(17 downto 16), PS2wires(15 downto 8), PS2wires(7 downto 0), KEY(0));
		ps2PrescalerPM : prescaler PORT MAP (
			clk					=> CLOCK_50,
			reset					=> KEY(0),
			clkout				=> PS2_prescaledClk
		);
		
		PS2_sendreceivePM : PS2 PORT MAP (
			PS2_CLK   			=> GPIO(25),
			PS2_DATA   			=> GPIO(23),
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
			testje				=> LEDG(7 downto 6)
		);
end architecture;