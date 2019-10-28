library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
 
use work.opcodes.all;

entity memory is
	generic (
		mem_size : integer := 256
	);
	port
	(
		clk_i			: in std_logic; 
		rst_i			: in std_logic;
		address_i		: in std_logic_vector(7 downto 0);
		data_i			: in std_logic_vector(7 downto 0);
		data_o			: out std_logic_vector(7 downto 0);
		mem_read_i		: in std_logic;
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
			
--0x0c: loop: 
		OP_MOVE_RR, R4 & R0,  -- C0 = A0
		OP_AALU_RR & ALU_ADD, R4 & R2, -- C0 = A0 + B0
		OP_MOVE_RR, R5 & R1,  -- C1 = A1
		OP_AALU_RR & ALU_ADDC, R5 & R3, -- C1 = A1 + B1 + carry

		OP_MOVE_RR, R0 & R2, 
		OP_MOVE_RR, R1 & R3,	 
		OP_MOVE_RR, R2 & R4, 
		OP_MOVE_RR, R3 & R5, 

		OP_MOVE_RR, R6 & R0,
		OP_MOVE_RR, R7 & R1,
		OP_LDC & R8, x"7f",
		OP_AALU_RR & ALU_AND, R6 & R8,
		OP_AALU_RV & ALU_SHR, R6 & x"1",
		OP_LDC & R8, x"3f",
		OP_AALU_RR & ALU_AND, R7 & R8, 
		OP_AALU_RV & ALU_SHR, R7 & x"1",
		OP_SETXY, R6 & R7,
		OP_SETC, R2 & R3,

		-- now - display the thing	
		OP_LDC & R15, x"00",
		OP_OUT_GROUP & R15, x"06",
		OP_MOVE_RR, R15 & R4,
		OP_SEVENSEGTRANSLATE, R15 & x"0",
		OP_OUT_GROUP & R15, x"05",

		OP_LDC & R15, x"01",
		OP_OUT_GROUP & R15, x"06",
		OP_MOVE_RR, R15 & R4,
		OP_SEVENSEGTRANSLATE, R15 & x"4",
		OP_OUT_GROUP & R15, x"05",

		OP_LDC & R15, x"02",
		OP_OUT_GROUP & R15, x"06",
		OP_MOVE_RR, R15 & R5,
		OP_SEVENSEGTRANSLATE, R15 & x"0",
		OP_OUT_GROUP & R15, x"05",
			
			
		OP_IN_GROUP & R8, x"00", -- read DP sw
		
		OP_WAIT, x"01",
		OP_AALU_RV & ALU_SUB, R8 & x"1",
		OP_JMP_A_NZ, x"FC", -- minus 6 - back to wait instruction 
		
		-- OP_LDC & R14, x"F0",
		-- OP_AALU_RR & ALU_AND, R14 & R5,

		OP_JMP_A_UNCOND,	x"0c",		-- go loop in all other cases	  

		others => x"00"
	);
	
	attribute ram_style: string;
	attribute ram_style of mem : signal is "block";

begin
	process (clk_i)
	begin
		if rising_edge(clk_i) 
		then
			if mem_write_i = '1' 
			then 
				mem(to_integer(unsigned(address_i))) <= data_i;
				data_o <= data_i;
			elsif mem_read_i = '1' 
			then
				data_o <= mem(to_integer(unsigned(address_i)));
			end if;
		end if;

	end process;
end rtl;
