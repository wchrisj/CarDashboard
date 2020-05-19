library ieee;
use ieee.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity led_center is
	Port ( 
		clk		:	in STD_LOGIC;
		reset		:	in STD_LOGIC;
		AddrIn 	:	in STD_LOGIC_VECTOR(16 downto 0);
		isLed		:	in	STD_LOGIC;
		center	:	out STD_LOGIC_VECTOR(16 downto 0);
		first : out STD_LOGIC_VECTOR(16 downto 0);
		last : out STD_LOGIC_VECTOR(16 downto 0)
	);      
end led_center;

architecture Behavioral of led_center is

signal top_left	: STD_LOGIC_VECTOR (16 downto 0);
signal bottom_right	: STD_LOGIC_VECTOR (16 downto 0);

signal done, finished : std_logic;

begin

	---- New Frame, reset and get data
	done <= '1' when AddrIn = "10010101011000000" else
			  '0' when finished = '1';
	
	top_left <= "00000000000000000" 	when AddrIn = "00000000000000000" else
					AddrIn					when top_left = "00000000000000000" and isLed = '1' else
					top_left;		
					
	bottom_right <= 	"00000000000000000" 	when AddrIn = "00000000000000000" else
							AddrIn 					when top_left /= "00000000000000000" and isLed = '1' else
							bottom_right;	
							
	process(clk)
	variable lelijke_fix, combined_x, combined_y : integer;
	variable top_left_x, top_left_y, bottom_right_x, bottom_right_y: integer;
	begin
		---- Calculate center (important, one frame behind camera)
		if done = '1' then
			finished <= '0';
			
			first <= top_left;
			top_left_x := to_integer(unsigned(top_left)) mod 320;
			top_left_y := (to_integer(unsigned(top_left))-top_left_x)/320;
			last <= bottom_right;
			bottom_right_x := to_integer(unsigned(bottom_right)) mod 320;
			bottom_right_y := (to_integer(unsigned(bottom_right))-bottom_right_x)/320;
			if ((bottom_right_y - top_left_y) > 5) then
				bottom_right_y := top_left_y + 5;
			end if;
			if ((bottom_right_x - top_left_x) > 5) then
				bottom_right_x := top_left_x + 5;
			end if;
			combined_x := (top_left_x+bottom_right_x)/2;
			combined_y := (top_left_y+bottom_right_y)/2;
			lelijke_fix := (combined_y*320)+combined_x;
			center <= std_logic_vector(to_unsigned(lelijke_fix, 34))(16 downto 0);		
			
			finished <= '1';
		end if;
	end process;
		
end Behavioral;
