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
		  reset	 				: IN STD_LOGIC;
		  wrte					: IN STD_LOGIC; -- 0 = lezen, 1 = schrijven
		  start					: IN STD_LOGIC; -- Voor zenden
		  inputData				: IN STD_LOGIC_VECTOR(7 downto 0);
		  receivedData 		: OUT STD_LOGIC_VECTOR(7 downto 0);
		  interruptReceived 	: OUT STD_LOGIC; -- Er is data ontvangen
		  interruptSend		: OUT STD_LOGIC; -- De data is verzonden
		  test2	 				: OUT STD_LOGIC_VECTOR(3 downto 0));
	end component PS2;
	component Prescaler is
		port(clk, reset : STD_LOGIC;
				clkout : OUT STD_LOGIC);
	end component Prescaler;
	
	signal PS2wires : STD_LOGIC_VECTOR(19 downto 0);
	signal testWires : STD_LOGIC_VECTOR(8 downto 0);
	signal PS2_prescaledClk : STD_LOGIC; -- Dit is de prescaled clock die gebruikt word door PS2
	
	begin
		niosPM: nios PORT MAP (CLOCK_50, LEDR, PS2wires(19 downto 18), PS2wires(17 downto 16), PS2wires(15 downto 8), PS2wires(7 downto 0), KEY(0));
		ps2PM: PS2 PORT MAP(
			PS2_CLK 				=> GPIO(25),
			PS2_DATA 			=> GPIO(23),
			clk 					=> PS2_prescaledClk, 
			reset 				=> KEY(0), 
			wrte					=> PS2wires(18),
			start					=> PS2wires(19), 
			inputData			=> PS2wires(7 downto 0), 
			receivedData		=> PS2wires(15 downto 8),
			interruptReceived	=> PS2wires(16),
			interruptSend		=> PS2wires(17),
			test2					=> testWires(3 downto 0)
		);
		ps2PrescalerPM : prescaler PORT MAP (
			clk					=> CLOCK_50,
			reset					=> KEY(0),
			clkout				=> PS2_prescaledClk
		);

--		LEDG(7 downto 5) <= testWires(8 downto 6);
		LEDG(3 downto 0) <= testWires(3 downto 0); 
end architecture;