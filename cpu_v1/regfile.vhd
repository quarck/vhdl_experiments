library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile is
    port ( 
		clk_i 					: in std_logic;
		rst_i 					: in std_logic;
		read_select_a_i 		: in std_logic_vector(4 downto 0);
		read_select_b_i 		: in std_logic_vector(4 downto 0);
		write_select_i 		: in std_logic_vector(4 downto 0);
		write_enable_i 		: in std_logic;
		port_a_data_read_o 	: out std_logic_vector (7 downto 0);
		port_b_data_read_o 	: out std_logic_vector (7 downto 0);
		
		write_data_i 			: in  std_logic_vector (7 downto 0)
	);
end regfile;

architecture rtl of regfile is
	type regfile_type is array (15 downto 0) of std_logic_vector(7 downto 0);
	signal regfile : regfile_type := (others => (others => '0'));
begin
	port_a_adata_read_i <= regfile(to_integer(unsigned(read_select_a_i)));
	port_b_adata_read_i <= regfile(to_integer(unsigned(read_select_b_i)));

	regfile(to_integer(unsigned(write_select_i))) 
		<= write_data_i when write_enable = '1' and rising_edge(clk);

end rtl;

