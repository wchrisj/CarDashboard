library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity Led_Detection is
	Port ( 
		AddrIn : in STD_LOGIC_VECTOR(16 downto 0);
		Din   : in  STD_LOGIC_VECTOR (11 downto 0);
		isLedA : out	STD_LOGIC;
		isLedB : out	STD_LOGIC;
		isLedC : out	STD_LOGIC;
		Dout : out std_logic_vector(11 downto 0);
		wren : in std_logic
	);      
end Led_Detection;

architecture Behavioral of Led_Detection is

signal xPos : unsigned (8 downto 0);
signal yPos : unsigned (7 downto 0);

signal t_xPos : unsigned (16 downto 0);
signal t_yPos : unsigned (16 downto 0);


--Led A
signal colorA : std_logic_vector(11 downto 0) := "000000000000"; --"111100000000";
		
signal min_xPosA : unsigned(8 downto 0) := "000000000";
signal min_yPosA : unsigned(7 downto 0) := "00000000";
signal max_xPosA : unsigned(8 downto 0) := "101000000";
signal max_yPosA : unsigned(7 downto 0) := "01111000";

--Led B
signal colorB : std_logic_vector(11 downto 0) := "000000000000"; --"000011110000";
		
signal min_xPosB : unsigned(8 downto 0) := "000000000";
signal min_yPosB : unsigned(7 downto 0) := "01111000";
signal max_xPosB : unsigned(8 downto 0) := "010100000";
signal max_yPosB : unsigned(7 downto 0) := "11110000"; 

--Led C
signal colorC : std_logic_vector(11 downto 0) := "000000000000"; --"000000001111";
		
signal min_xPosC : unsigned(8 downto 0) := "010100000";
signal min_yPosC : unsigned(7 downto 0) := "01111000";
signal max_xPosC : unsigned(8 downto 0) := "101000000";
signal max_yPosC : unsigned(7 downto 0) := "11110000"; 

begin
		
		t_xPos <= unsigned(AddrIn) mod 320;
		xPos <= t_xPos(8 downto 0);
		
		t_yPos <= (unsigned(AddrIn) - xPos) / 320;
		yPos <= t_yPos(7 downto 0);
		

		Dout <= colorA when Din = "111111111111" and (t_xpos > 10) and (xPos > min_xPosA) and (xPos < max_xPosA) and (yPos > min_yPosA) and (yPos < max_yPosA) else 
				  colorB when Din = "111111111111" and (t_xpos > 10) and (xPos > min_xPosB) and (xPos < max_xPosB) and (yPos > min_yPosB) and (yPos < max_yPosB) else
				  colorC when Din = "111111111111" and (t_xpos > 10) and (xPos > min_xPosC) and (xPos < max_xPosC) and (yPos > min_yPosC) and (yPos < max_yPosC) else  
				  "000000000000";
				  
		isLedA <= '1' when Din = "111111111111" and (t_xpos > 10) and (xPos > min_xPosA) and (xPos < max_xPosA) and (yPos > min_yPosA) and (yPos < max_yPosA) else
					 '0';
		isLedB <= '1' when Din = "111111111111" and (t_xpos > 10) and (xPos > min_xPosB) and (xPos < max_xPosB) and (yPos > min_yPosB) and (yPos < max_yPosB) else
					 '0';		 
		isLedC <= '1' when Din = "111111111111" and (t_xpos > 10) and (xPos > min_xPosC) and (xPos < max_xPosC) and (yPos > min_yPosC) and (yPos < max_yPosC) else
					 '0';		
end Behavioral;
