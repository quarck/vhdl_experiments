library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
 
use work.opcodes.all;

entity memory is
	generic (
		mem_size : integer := 16*1024 -- of 2-byte words, 32k in total. 
	);
	port
	(
		clk_i			: in std_logic;
		address_i		: in std_logic_vector(15 downto 0);
		data_i			: in std_logic_vector(15 downto 0);
		data_o			: out std_logic_vector(15 downto 0);
		mem_read_i		: in std_logic;
		mem_write_i		: in std_logic
	);
end memory;

architecture rtl of memory is

	type mem_type is array (0 to mem_size-1) of std_logic_vector(15 downto 0);

	signal mem: mem_type:= (
		--0: start:
		OP_LDC & R0 & x"01", -- A0 
		OP_LDC & R1 & x"00", -- A1
		
		OP_LDC & R2 & x"01", -- B0
		OP_LDC & R3 & x"00", -- B1
		
		OP_LDC & R4 & x"00", -- C0
		OP_LDC & R5 & x"00", -- C1

		OP_LDC & R6 & x"01", -- current X pos
		OP_LDC & R7 & x"4e", -- max X pos 
		OP_LDC & R8 & x"01", -- current Y pos
		OP_LDC & R9 & x"1C", -- max Y pos
		OP_LDC & R10 & x"03", -- current direction, XY, by two LSB bits 

--0x16: loop: 
		OP_MOVE_RR & R4 & R0,  -- C0 = A0
		OP_ADD & R4 & R2, -- C0 = A0 + B0
		OP_MOVE_RR & R5 & R1,  -- C1 = A1
		OP_ADDC & R5 & R3, -- C1 = A1 + B1 + carry

		OP_MOVE_RR & R0 & R2, 
		OP_MOVE_RR & R1 & R3,	 
		OP_MOVE_RR & R2 & R4, 
		OP_MOVE_RR & R3 & R5, 

		-- now - display the thing	
		OP_LDC & R15 & x"00",
		OP_OUT_GROUP & R15 & x"06",
		OP_MOVE_RR & R15 & R4,
		OP_SEVENSEGTRANSLATE & R15 & x"0",
		OP_OUT_GROUP & R15 & x"05",
		OP_LDC & R15 & x"01",
		OP_OUT_GROUP & R15 & x"06",
		OP_MOVE_RR & R15 & R4,
		OP_SEVENSEGTRANSLATE & R15 & x"4",
		OP_OUT_GROUP & R15 & x"05",
		OP_LDC & R15 & x"02",
		OP_OUT_GROUP & R15 & x"06",
		OP_MOVE_RR & R15 & R5,
		OP_SEVENSEGTRANSLATE & R15 & x"0",
		OP_OUT_GROUP & R15 & x"05",
	
		-- display a tiny dot on a VGA screen

		-- clear the old pos 
		
		OP_SETXY & R11 & R12,
		OP_LDC & R15 & x"00",
		OP_SETC & R15 & R15,
		
		OP_MOVE_RR & R11 & R6,
		OP_MOVE_RR & R12 & R8,
		
		-- now - increment the position 				
		OP_TEST_V & R10 & x"2", -- check the x direction 
		OP_JMP_REL_Z & x"0a", -- negative_vx
		
		OP_ADD_V & R6 & x"1",
		OP_CMP & R6 & R7, 
		OP_JMP_REL_NZ & x"02", -- non-eq 
		OP_XOR_V & R10 & x"2", -- invert x direction		
		OP_JMP_REL_UNCOND & x"06",	-- do_y

-- negative_vx:

		OP_SUB_V & R6 & x"1",
		OP_JMP_REL_NZ & x"02", 
		OP_XOR_V & R10 & x"2", -- invert x direction
-- do_y:

		OP_TEST_V & R10 & x"1", -- check the x direction 
		OP_JMP_REL_Z & x"0a", -- negative_vy
		
		OP_ADD_V & R8 & x"1",
		OP_CMP & R8 & R9, 
		OP_JMP_REL_NZ & x"02", -- non-eq 
		OP_XOR_V & R10 & x"1", -- invert x direction		
		OP_JMP_REL_UNCOND & x"06",	-- do_display

-- negative_vy:
		OP_SUB_V & R8 & x"1",
		OP_JMP_REL_NZ & x"02", 
		OP_XOR_V & R10 & x"1", -- invert x direction

-- do_display: 

		-- finally - dispay the new dot
		OP_SETXY & R6 & R8,
		OP_SETC & R4 & R5,

		-- sleep loop 
		 -- OP_IN_GROUP & R11, x"00", -- read DP sw
		 --OP_ADD, R11 & x"1",

		OP_WAIT & x"10",
		-- OP_JMP_REL_NZ, x"FA", -- minus 6 - back to wait instruction

		OP_JMP_A_UNCOND &	x"16",		-- go loop in all other cases	  

		others => x"0000"
	);
	
	attribute ram_style: string;
	attribute ram_style of mem : signal is "block";


	signal addr_cut : std_logic_vector(13 downto 0);
	
begin

	addr_cut <= address_i(13 downto 0);

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