-- cristinel ababei; Jan.29.2015; CopyLeft (CL);
-- code name: "digital cam implementation #1";
-- project done using Quartus II 13.1 and tested on DE2-115;
--
-- this design basically connects a CMOS camera (OV7670 module) to
-- DE2-115 board; video frames are picked up from camera, buffered
-- on the FPGA (using embedded RAM), and displayed on the VGA monitor,
-- which is also connected to the board; clock signals generated
-- inside FPGA using ALTPLL's that take as input the board's 50MHz signal
-- from on-board oscillator; 
--
-- this whole project is an adaptation of Mike Field's original implementation 
-- that can be found here:
-- http://hamsterworks.co.nz/mediawiki/index.php/OV7670_camera

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity top_level is
  Port ( 
		clk_50 : in  STD_LOGIC;
		btn_resend          : in  STD_LOGIC;
		led_config_finished : out STD_LOGIC;
		ledr : out std_logic_vector(16 downto 0);

		vga_hsync : out  STD_LOGIC;
		vga_vsync : out  STD_LOGIC;
		vga_r     : out  STD_LOGIC_vector(7 downto 0);
		vga_g     : out  STD_LOGIC_vector(7 downto 0);
		vga_b     : out  STD_LOGIC_vector(7 downto 0);
		vga_blank_N : out  STD_LOGIC;
		vga_sync_N  : out  STD_LOGIC;
		vga_CLK     : out  STD_LOGIC;

		ov7670_pclk  : in  STD_LOGIC;
		ov7670_xclk  : out STD_LOGIC;
		ov7670_vsync : in  STD_LOGIC;
		ov7670_href  : in  STD_LOGIC;
		ov7670_data  : in  STD_LOGIC_vector(7 downto 0);
		ov7670_sioc  : out STD_LOGIC;
		ov7670_siod  : inout STD_LOGIC;
		ov7670_pwdn  : out STD_LOGIC;
		ov7670_reset : out STD_LOGIC;
		
		PS2_data		: INOUT STD_LOGIC;
		PS2_clock	: INOUT STD_LOGIC;
		PS2_reset	: IN STD_LOGIC;
		LEDG			: OUT STD_LOGIC_VECTOR(7 downto 0)
	);
end top_level;


architecture my_structural of top_level is

	component Nios is
		port (
			clk_50_clk          : in  std_logic                     := '0';             --       clk_50.clk
			led_a_center_export : in  std_logic_vector(16 downto 0) := (others => '0'); -- led_a_center.export
			led_b_center_export : in  std_logic_vector(16 downto 0) := (others => '0'); -- led_b_center.export
			led_c_center_export : in  std_logic_vector(16 downto 0) := (others => '0'); -- led_c_center.export
			leds_export         : out std_logic_vector(16 downto 0);                    --         leds.export
			ps2_location_export : out std_logic_vector(4 downto 0);                     -- ps2_location.export
			reset_50_reset_n    : in  std_logic                     := '0'              --     reset_50.reset_n
		);
	end component Nios;

	COMPONENT VGA
	PORT(
	 CLK25 : IN std_logic;    
	 Hsync : OUT std_logic;
	 Vsync : OUT std_logic;
	 Nblank : OUT std_logic;      
	 clkout : OUT std_logic;
	 activeArea : OUT std_logic;
	 Nsync : OUT std_logic
	 );
	END COMPONENT;

	COMPONENT ov7670_controller
	PORT(
	 clk : IN std_logic;
	 resend : IN std_logic;    
	 siod : INOUT std_logic;      
	 config_finished : OUT std_logic;
	 sioc : OUT std_logic;
	 reset : OUT std_logic;
	 pwdn : OUT std_logic;
	 xclk : OUT std_logic
	 );
	END COMPONENT;

	COMPONENT frame_buffer
	PORT(
	 data : IN std_logic_vector(11 downto 0);
	 rdaddress : IN std_logic_vector(16 downto 0);
	 rdclock : IN std_logic;
	 wraddress : IN std_logic_vector(16 downto 0);
	 wrclock : IN std_logic;
	 wren : IN std_logic;          
	 q : OUT std_logic_vector(11 downto 0)
	 );
	END COMPONENT;

	COMPONENT ov7670_capture
	PORT(
	 pclk : IN std_logic;
	 vsync : IN std_logic;
	 href : IN std_logic;
	 d : IN std_logic_vector(7 downto 0);          
	 addr : OUT std_logic_vector(16 downto 0);
	 dout : OUT std_logic_vector(11 downto 0);
	 we : OUT std_logic
	 );
	END COMPONENT;

	COMPONENT RGB
	PORT(
		Din : IN std_logic_vector(11 downto 0);
		Nblank : IN std_logic;          
		R : OUT std_logic_vector(7 downto 0);
		G : OUT std_logic_vector(7 downto 0);
		B : OUT std_logic_vector(7 downto 0);
		
		AddrIn : in std_logic_vector(16 downto 0);
		--LedA
		centerA : in std_logic_vector(16 downto 0);
		firstA : in std_logic_vector(16 downto 0);
		lastA : in std_logic_vector(16 downto 0);
		--LedB
		centerB : in std_logic_vector(16 downto 0);
		firstB : in std_logic_vector(16 downto 0);
		lastB : in std_logic_vector(16 downto 0);
		--LedC
		centerC : in std_logic_vector(16 downto 0);
		firstC : in std_logic_vector(16 downto 0);
		lastC : in std_logic_vector(16 downto 0)	
	);
	END COMPONENT;

	-- DE2-115 board has an Altera Cyclone V E, which has ALTPLL's'
	COMPONENT my_altpll
	PORT (
	 inclk0 : IN STD_LOGIC := '0';
	 c0     : OUT STD_LOGIC ;
	 c1     : OUT STD_LOGIC 
	 );
	END COMPONENT;

	COMPONENT Address_Generator
	PORT(
	 CLK25       : IN  std_logic;
	 enable      : IN  std_logic;       
	 vsync       : in  STD_LOGIC;
	 address     : OUT std_logic_vector(16 downto 0)
	 );
	END COMPONENT;

	COMPONENT Led_Detection IS
	Port ( 
		AddrIn : in STD_LOGIC_VECTOR(16 downto 0);
		Din   : in  STD_LOGIC_VECTOR (11 downto 0);
		isLedA : out	STD_LOGIC;
		isLedB : out	STD_LOGIC;
		isLedC : out	STD_LOGIC;
		Dout : out std_logic_vector(11 downto 0);
		wren : in std_logic
	);      
	END COMPONENT;

	COMPONENT led_center is
	Port ( 
		clk		:	in STD_LOGIC;
		reset		:	in STD_LOGIC;
		AddrIn 	:	in STD_LOGIC_VECTOR(16 downto 0);

		isLed		:	in	STD_LOGIC;
		center	:	out STD_LOGIC_VECTOR(16 downto 0);
		first : out STD_LOGIC_VECTOR(16 downto 0);
		last : out STD_LOGIC_VECTOR(16 downto 0)
	);      
	END COMPONENT led_center;
	
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


	signal clk_50_camera : std_logic;
	signal clk_25_vga    : std_logic;
	signal wren       : std_logic;
	signal resend     : std_logic;
	signal nBlank     : std_logic;
	signal vSync      : std_logic;

	signal wraddress  : std_logic_vector(16 downto 0);
	signal wrdata     : std_logic_vector(11 downto 0);   
	signal rdaddress  : std_logic_vector(16 downto 0);
	signal rddata     : std_logic_vector(11 downto 0);
	signal red,green,blue : std_logic_vector(7 downto 0);
	signal activeArea : std_logic;

	signal led_data_out : std_logic_vector(11 downto 0);

	--Led A
	signal isLedFoundA : std_logic;
	signal ledCenterA: std_logic_vector(16 downto 0);
	signal ledFirstA : std_logic_vector(16 downto 0);
	signal ledLastA : std_logic_vector(16 downto 0);
	--Led B
	signal isLedFoundB : std_logic;
	signal ledCenterB: std_logic_vector(16 downto 0);
	signal ledFirstB : std_logic_vector(16 downto 0);
	signal ledLastB : std_logic_vector(16 downto 0);
	--Led C
	signal isLedFoundC : std_logic;
	signal ledCenterC: std_logic_vector(16 downto 0);
	signal ledFirstC : std_logic_vector(16 downto 0);
	signal ledLastC : std_logic_vector(16 downto 0);

	SIGNAL ps2_loc : STD_LOGIC_VECTOR(4 downto 0);
	SIGNAL wrteSignal : STD_LOGIC;
	SIGNAL startSignal : STD_LOGIC;
	SIGNAL sendData : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL receiveData : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL receivedInterruptSignal : STD_LOGIC;
	SIGNAL sendReadySignal : STD_LOGIC;
	SIGNAL PS2_prescaledClk : STD_LOGIC;

	SIGNAL nextMoveSignal : STD_LOGIC_VECTOR(1 downto 0);
	
	-- Nog niet gebruikt PS2
	SIGNAL dataReporting : STD_LOGIC;
	SIGNAL resolution : STD_LOGIC_VECTOR(1 downto 0);
	SIGNAL scaling : STD_LOGIC;
	SIGNAL sampleRate : STD_LOGIC_VECTOR(2 downto 0);

begin

  vga_r <= red(7 downto 0);
  vga_g <= green(7 downto 0);
  vga_b <= blue(7 downto 0);
   

  Inst_vga_pll: my_altpll PORT MAP(
    inclk0 => clk_50,
    c0 => clk_50_camera,
    c1 => clk_25_vga
  );    
    
    
  -- take the inverted push button because KEY0 on DE2-115 board generates
  -- a signal 111000111; with 1 with not pressed and 0 when pressed/pushed;
  resend <= not btn_resend;
  vga_vsync <= vsync;
  vga_blank_N <= nBlank;
  
  --ledr <= ledCenterA;
  
  niosPM: Nios PORT MAP (
	clk_50_clk 				=> clk_50_camera,
	led_a_center_export 	=> ledCenterA,
	led_b_center_export 	=> ledCenterB,
	led_c_center_export 	=> ledCenterC,
	leds_export 			=> ledr,
	ps2_location_export 	=> ps2_loc,
	reset_50_reset_n 		=> btn_resend
  );

  Inst_VGA: VGA PORT MAP(
    CLK25      => clk_25_vga,
    clkout     => vga_CLK,
    Hsync      => vga_hsync,
    Vsync      => vsync,
    Nblank     => nBlank,
    Nsync      => vga_sync_N,
    activeArea => activeArea
  );

  Inst_ov7670_controller: ov7670_controller PORT MAP(
    clk             => clk_50_camera,
    resend          => resend,
    config_finished => led_config_finished,
    sioc            => ov7670_sioc,
    siod            => ov7670_siod,
    reset           => ov7670_reset,
    pwdn            => ov7670_pwdn,
    xclk            => ov7670_xclk
  );
   
  Inst_ov7670_capture: ov7670_capture PORT MAP(
    pclk  => ov7670_pclk,
    vsync => ov7670_vsync,
    href  => ov7670_href,
    d     => ov7670_data,
    addr  => wraddress,
    dout  => wrdata,
    we    => wren
  );

--  Inst_frame_buffer: frame_buffer PORT MAP(
--    rdaddress => rdaddress,
--    rdclock   => clk_25_vga,
--    q         => rddata,      
--    wrclock   => ov7670_pclk,
--    wraddress => wraddress(16 downto 0),
--    data      => wrdata,
--    wren      => wren
--  );
  
  Inst_RGB: RGB PORT MAP(
		Din => led_data_out,
		Nblank => activeArea,
		R => red,
		G => green,
		B => blue,
		AddrIn => rdaddress,
		centerA => ledCenterA,
		firstA => ledFirstA,
		lastA => ledLastA,
		centerB => ledCenterB,
		firstB => ledFirstB,
		lastB => ledLastB,
		centerC => ledCenterC,
		firstC => ledFirstC,
		lastC => ledLastC
);

  Inst_Address_Generator: Address_Generator PORT MAP(
    CLK25 => clk_25_vga,
    enable => activeArea,
    vsync => vsync,
    address => rdaddress
  );
  
  Led_Detector: Led_Detection PORT MAP(
	AddrIn => wraddress,
	Din => wrdata,
	isLedA => isLedFoundA,
	isLedB => isLedFoundB,
	isLedC => isLedFoundC,
	Dout => led_data_out,
	wren => wren
  );
  
  --LedA
  led_centeringA: led_center PORT MAP(
	clk => clk_25_vga,
	reset => '0',
	AddrIn => wraddress,
	
	isLed => isLedFoundA,
	center => ledCenterA,
	first => ledFirstA,
	last => ledLastA
  );
  
  --LedB
  led_centeringB: led_center PORT MAP(
	clk => clk_25_vga,
	reset => '0',
	AddrIn => wraddress,
	
	isLed => isLedFoundB,
	center => ledCenterB,
	first => ledFirstB,
	last => ledLastB
  );
  
  --LedC
  led_centeringC: led_center PORT MAP(
	clk => clk_25_vga,
	reset => '0',
	AddrIn => wraddress,
	
	isLed => isLedFoundC,
	center => ledCenterC,
	first => ledFirstC,
	last => ledLastC
  );
  
  PS2_sendreceivePM : PS2 PORT MAP (
			PS2_CLK   			=> PS2_clock,
			PS2_DATA   			=> PS2_data,
			PS2_RESET			=> PS2_reset,
			clk 					=> PS2_prescaledClk,
			reset	 				=> btn_resend,
			wrte					=> wrteSignal, -- 0 = lezen, 1 = schrijven
			start					=> startSignal, -- Voor zenden
			inputData			=> sendData,
			receivedData 		=> receiveData,
			interruptReceived => receivedInterruptSignal, -- Er is data ontvangen
			sendReady			=> sendReadySignal, -- De data is verzonden
			test2	 				=> LEDG(5 downto 0)				
		);
		
		PS2_decodePM : PS2_decode PORT MAP (
			PS2_RESET			=> PS2_reset,
			clk 					=> PS2_prescaledClk,
			reset	 				=> btn_resend,
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
			clk					=> clk_50,
			reset					=> btn_resend,
			clkout				=> PS2_prescaledClk
		);
		
		ps2_calculateMovePM : PS2_calculateMove PORT MAP (
			clk					=> PS2_prescaledClk,
			reset					=> PS2_reset,
			cLoc					=> ps2_loc,
			nextMove				=> nextMoveSignal
		);

end my_structural;
