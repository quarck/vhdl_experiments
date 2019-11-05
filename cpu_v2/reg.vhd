library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg is
	generic (
		nbits	: integer := 16
	);
	port (
		clk_i		: in std_logic;
		rst_i		: in std_logic;
		we_i		: in std_logic;
		data_o		: out std_logic_vector(nbits-1 downto 0);
		data_i 		: in std_logic_vector(nbits-1 downto 0)
	);
end reg;

architecture rtl of reg is
	signal data : std_logic_vector(nbits-1 downto 0);
begin

	data <= (others => '0') when rst_i = '1' 
			else data_i when rising_edge(clk_i) and we_i = '1';

	data_o <= data; -- always - async
end rtl;

