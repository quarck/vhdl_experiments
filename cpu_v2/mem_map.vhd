library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
 
use work.opcodes.all;

entity mem_map is
	generic (
		video_ram_pattern : std_logic_vector(19 downto 15) := "10111"  -- B8000 is the base for the video memory in text mode 
	);
	port
	(
		-- interface into the CPU
		address_i		: in std_logic_vector(19 downto 0);
		data_i			: in std_logic_vector(7 downto 0); 
		data_o			: out std_logic_vector(7 downto 0);
		write_i			: in std_logic;

		-- connecto this one to the main memory 
		mem_address_o	: out std_logic_vector(19 downto 0);
		mem_data_i		: in std_logic_vector(7 downto 0); 
		mem_data_o		: out std_logic_vector(7 downto 0);
		mem_write_o		: out std_logic;

		-- connecto this one to the video memory 
		vram_address_o	: out std_logic_vector(14 downto 0);
		vram_data_i		: in std_logic_vector(7 downto 0); 
		vram_data_o		: out std_logic_vector(7 downto 0);
		vram_write_o	: out std_logic
	);
end mem_map;

architecture rtl of mem_map is 
	signal vram_select : std_logic;	
begin
	vram_select <= '1' when address_i(19 downto 15) = video_ram_pattern  else '0';

	mem_address_o <= address_i;
	vram_address_o <= address_i(14 downto 0);
	
	data_o <= mem_data_i when vram_select = '0' else vram_data_i;
	mem_data_o <= data_i;
	vram_data_o <= data_i;
	
	mem_write_o <= write_i when vram_select = '0' else '0';
	vram_write_o <= write_i when vram_select = '1' else '0';	
end rtl;
