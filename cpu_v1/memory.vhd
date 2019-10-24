library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
 
use work.opcodes.all;

entity memory is
	port
	(
		clk			: in std_logic; 
		address_bus	: in std_logic_vector(7 downto 0);
		data_write	: in std_logic_vector(7 downto 0);
		data_read	: out std_logic_vector(7 downto 0);
		mem_read	: in std_logic;
		mem_write	: in std_logic;
		rst			: in std_logic
	);
end memory;

architecture rtl of memory is

type mem_type is array (0 to 255) of std_logic_vector(7 downto 0);

signal mem: mem_type:= (
	others => x"00"
);

begin
	process (clk, rst, mem_write, address_bus, data_write)
	begin

		if rising_edge(clk) 
		then
			if mem_write = '1' 
			then 
				mem(to_integer(unsigned(address_bus))) <= data_write;
				data_read <= data_write;				
			elsif mem_read = '1' 
			then 			
				data_read <= mem(to_integer(unsigned(address_bus)));
			end if;			
		end if;
		
	end process;
end rtl;
