LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

entity oddParity is
	port(
		data : IN STD_LOGIC_VECTOR(7 downto 0);
		output : OUT STD_LOGIC
	);
end entity;

architecture default of oddParity is
	begin
		output <= NOT(data(0) XOR data(1) XOR data(2) XOR data(3) XOR data(4) XOR data(5) XOR data(6) XOR data(7));
end architecture;