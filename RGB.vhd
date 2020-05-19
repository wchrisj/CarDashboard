library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity RGB is
	Port ( 
		Din   : in  STD_LOGIC_VECTOR (11 downto 0);  -- niveau de gris du pixels sur 8 bits
		Nblank : in  STD_LOGIC;                      -- signal indique les zone d'affichage, hors la zone d'affichage
																 -- les trois couleurs prendre 0
		R,G,B   : out  STD_LOGIC_VECTOR (7 downto 0); -- les trois couleurs sur 10 bits
		
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
end RGB;

architecture Behavioral of RGB is
	signal debug : std_logic_vector(16 downto 0):="00111110101100100";
begin
	
	R <= 	"11111111" when AddrIn = centerA or AddrIn = centerB or AddrIn = centerC else
			"00000000" when AddrIn = firstA or AddrIn = firstB or AddrIn = firstC else
			"11111111" when AddrIn = lastA or AddrIn = lastB or AddrIn = lastC else
			Din(11 downto 8) & Din(11 downto 8) when Nblank='1' else
			"00000000";
			
	G <= 	"00000000" when AddrIn = centerA or AddrIn = centerB or AddrIn = centerC else
			"11111111" when AddrIn = firstA or AddrIn = firstB or AddrIn = firstC else
			"11111111" when AddrIn = lastA or AddrIn = lastB or AddrIn = lastC else
			Din(7 downto 4) & Din(7 downto 4) when Nblank='1' else
			"00000000";
			
	B <= 	"11111111" when AddrIn = centerA or AddrIn = centerB or AddrIn = centerC else
			"00000000" when AddrIn = firstA or AddrIn = firstB or AddrIn = firstC else
			"00000000" when AddrIn = lastA or AddrIn = lastB or AddrIn = lastC else
			Din(3 downto 0) & Din(3 downto 0) when Nblank='1' else
			"00000000";
	
--	R <= Din(11 downto 8) & Din(11 downto 8) when Nblank='1' else "00000000";
--	G <= Din(7 downto 4)  & Din(7 downto 4)  when Nblank='1' else "00000000";
--	B <= Din(3 downto 0)  & Din(3 downto 0)  when Nblank='1' else "00000000";
		
end Behavioral;
