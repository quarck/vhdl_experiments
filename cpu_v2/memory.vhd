library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
 
use work.opcodes.all;

entity memory is
	generic (
		mem_size : integer := 32*1024
	);
	port
	(
		clk_i			: in std_logic;
		address_i		: in std_logic_vector(19 downto 0);
		data_i			: in std_logic_vector(7 downto 0);
		data_o			: out std_logic_vector(7 downto 0);
		mem_write_i		: in std_logic
	);
end memory;

architecture rtl of memory is

	type mem_type is array (0 to mem_size-1) of std_logic_vector(7 downto 0);

	signal mem: mem_type:= (
		--0: start:
		OP_LDC & R0, x"01", -- A0 
		OP_LDC & R1, x"00", -- A1
		
		OP_LDC & R2, x"01", -- B0
		OP_LDC & R3, x"00", -- B1
		
		OP_LDC & R4, x"00", -- C0
		OP_LDC & R5, x"00", -- C1

		OP_LDC & R6, x"01", -- current X pos
		OP_LDC & R7, x"4e", -- max X pos 
		OP_LDC & R8, x"01", -- current Y pos
		OP_LDC & R9, x"1C", -- max Y pos
		OP_LDC & R10, x"03", -- current direction, XY, by two LSB bits 

--0x16: loop: 
		OP_MOVE_RR, R4 & R0,  -- C0 = A0
		OP_ADD, R4 & R2, -- C0 = A0 + B0
		OP_MOVE_RR, R5 & R1,  -- C1 = A1
		OP_ADDC, R5 & R3, -- C1 = A1 + B1 + carry

		OP_MOVE_RR, R0 & R2, 
		OP_MOVE_RR, R1 & R3,	 
		OP_MOVE_RR, R2 & R4, 
		OP_MOVE_RR, R3 & R5, 
	

		OP_JMP_A_UNCOND,	x"16",		-- go loop in all other cases	  

		others => x"00"
	);
	
	attribute ram_style: string;
	attribute ram_style of mem : signal is "block";


	signal addr_cut : std_logic_vector(14 downto 0);
	
begin

	addr_cut <= address_i(14 downto 0);

	process (clk_i)
	begin
		if rising_edge(clk_i)
		then
			if mem_write_i = '1' 
			then 
				mem(to_integer(unsigned(addr_cut))) <= data_i;
				data_o <= data_i;
			end if;

			data_o <= mem(to_integer(unsigned(addr_cut)));
		end if;
	end process;
end rtl;