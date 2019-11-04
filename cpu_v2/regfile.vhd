library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile is
    generic (
        nreg    : integer := 4; -- 2**nreg is the number of registers generated 
        bits    : integer := 8
    );
    port ( 
        clk_i                   : in std_logic;
        rst_i                   : in std_logic;
        read_select_a_i         : in std_logic_vector(nreg-1 downto 0); 
        read_select_b_i         : in std_logic_vector(nreg-1 downto 0); 
        
        write_select_i          : in std_logic_vector(nreg-1 downto 0);
        write_enable_i          : in std_logic;
        
        port_a_data_read_o      : out std_logic_vector (bits-1 downto 0); 
        port_b_data_read_o      : out std_logic_vector (bits-1 downto 0); 

        write_data_i            : in  std_logic_vector (bits-1 downto 0)
    );
end regfile;

architecture rtl of regfile is
    type regfile_type is array (2**nreg-1 downto 0) of std_logic_vector(bits-1 downto 0);
    signal regfile : regfile_type := (others => (others => '0'));
begin
    port_a_data_read_o <= regfile(to_integer(unsigned(read_select_a_i)));
    port_b_data_read_o <= regfile(to_integer(unsigned(read_select_b_i)));
    
write_process: 
	process (clk_i, write_enable_i)
	begin
		if rising_edge(clk_i) and write_enable_i = '1'
		then 
			regfile(to_integer(unsigned(write_select_i))) <= write_data_i;
		end if;
	end process;    
end rtl;

