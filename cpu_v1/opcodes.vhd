library ieee ;
use ieee.std_logic_1164.all ;


package opcodes is

	type alu_opcode_type is (
			ALU_ADD, 		-- add
			ALU_SUB,		-- sub Left-Right
			-- ALU_NEG,		-- negative 

			ALU_OR, 		-- bitwise OR
			ALU_AND, 		-- .. AND
			ALU_XOR,		-- .. XOR
			-- ALU_NOT, 		-- .. NOT
			
			ALU_SHL,		-- shift left
			ALU_SHR,		-- shift right 
			ALU_SHAR,		-- shift-arithmetic left
			ALU_ROL,		-- rotate left
			ALU_ROR,		-- rotate right 
			ALU_RCL,		-- rotate-carry-left
			ALU_RCR,		-- rotate-carry-right

			ALU_NOP			-- no operation
		);
		
	type alu_value_select is (
		ALU_REGISTER_PORT, 
		ALU_VALUE_PORT
	);

	-- constant definition for various CPU instructions 
		
	-- load and store instructions 
	-- prefix 001
	constant OP_STA 		: std_logic_vector(7 downto 0):="00100000";  -- mem[arg] = A
	constant OP_LDA 		: std_logic_vector(7 downto 0):="00100001";  -- A = mem[arg]
	constant OP_LDC 		: std_logic_vector(7 downto 0):="00100010";  -- A = arg
	
	-- math instructions 
	-- prefix 010
	constant OP_ADD 		: std_logic_vector(7 downto 0):="01000000";  -- A = A + mem[arg]
	constant OP_ADDC 		: std_logic_vector(7 downto 0):="01000010";  -- A = A + mem[arg] + carry
	constant OP_SUB 		: std_logic_vector(7 downto 0):="01000011";  -- A = A - mem[arg]
	constant OP_SUBC 		: std_logic_vector(7 downto 0):="01000100";  -- A = A - mem[arg] - carry
	constant OP_SUBR 		: std_logic_vector(7 downto 0):="01000101";  -- A = mem[arg] - A
	constant OP_SUBRC		: std_logic_vector(7 downto 0):="01000110";  -- A = mem[arg] - A - carry	
	
	constant OP_ADD_V 		: std_logic_vector(7 downto 0):="01010000";  -- A = A + arg
	constant OP_ADDC_V 		: std_logic_vector(7 downto 0):="01010010";  -- A = A + arg + carry
	constant OP_SUB_V 		: std_logic_vector(7 downto 0):="01010011";  -- A = A - arg
	constant OP_SUBC_V 		: std_logic_vector(7 downto 0):="01010100";  -- A = A - arg - carry
	constant OP_SUBR_V 		: std_logic_vector(7 downto 0):="01010101";  -- A = arg - A
	constant OP_SUBRC_V 	: std_logic_vector(7 downto 0):="01010110";  -- A = arg - A - carry
	
	-- no need for a separate opcode for OP_NEG: equals to OP_SUBR with arg = 0
	-- constant OP_NEG 		: std_logic_vector(7 downto 0):="01011000";  -- equals to OP_SUBR with arg = 0
	
	-- logical and bit instructions 
	-- prefix 011
	constant OP_OR  		: std_logic_vector(7 downto 0):="01100000";  -- A = A or mem[arg]
	constant OP_AND			: std_logic_vector(7 downto 0):="01100001";  -- A = A and mem[arg]
	constant OP_XOR			: std_logic_vector(7 downto 0):="01100010";  -- A = A xor mem[arg]
	constant OP_SHR 		: std_logic_vector(7 downto 0):="01100011";  -- shift A right by mem[arg]
	constant OP_SHL 		: std_logic_vector(7 downto 0):="01100100";  -- shift A left by mem[arg]
	constant OP_SHAR 		: std_logic_vector(7 downto 0):="01100101";  -- shift A right by mem[arg]
	constant OP_ROL 		: std_logic_vector(7 downto 0):="01100110";  -- rotate right by mem[arg]
	constant OP_ROR 		: std_logic_vector(7 downto 0):="01100111";  -- rotate left by mem[arg]
	constant OP_RCL 		: std_logic_vector(7 downto 0):="01101000";  -- rotate through carry right by mem[arg]
	constant OP_RCR 		: std_logic_vector(7 downto 0):="01101001";  -- rotate through carry left by mem[arg]

	constant OP_OR_V  		: std_logic_vector(7 downto 0):="01110000";  -- A = A or arg
	constant OP_AND_V		: std_logic_vector(7 downto 0):="01110001";  -- A = A and arg
	constant OP_XOR_V		: std_logic_vector(7 downto 0):="01110010";  -- A = A xor arg
	constant OP_SHR_V 		: std_logic_vector(7 downto 0):="01110011";  -- shift A right by arg
	constant OP_SHL_V 		: std_logic_vector(7 downto 0):="01110100";  -- shift A left by arg
	constant OP_SHAR_V 		: std_logic_vector(7 downto 0):="01110101";  -- shift A right by arg
	constant OP_ROL_V 		: std_logic_vector(7 downto 0):="01110110";  -- rotate right by arg
	constant OP_ROR_V 		: std_logic_vector(7 downto 0):="01110111";  -- rotate left by arg
	constant OP_RCL_V 		: std_logic_vector(7 downto 0):="01111000";  -- rotate through carry right by arg
	constant OP_RCR_V 		: std_logic_vector(7 downto 0):="01111001";  -- rotate through carry left by arg

	-- constant OP_NOT_V		: std_logic_vector(7 downto 0):="11000010";  -- same as OP_XOR_V with arg = 255 
	
	-- branching instructions 
	-- prefix 100
	constant OP_JMP 		: std_logic_vector(7 downto 0):="10000001"; -- jump to arg
	constant OP_JMP_A		: std_logic_vector(7 downto 0):="10000000"; -- jump to arg + A
	
	constant OP_JN  		: std_logic_vector(7 downto 0):="10000010";  -- jump to arg if negative 
	constant OP_JP  		: std_logic_vector(7 downto 0):="10000011";	 -- jump to arg if positive 
	constant OP_JV  		: std_logic_vector(7 downto 0):="10000101";  -- jump to arg if overflow 
	constant OP_JNV 		: std_logic_vector(7 downto 0):="10000100";  -- jump to arg if no overflow 
	constant OP_JZ  		: std_logic_vector(7 downto 0):="10000111";  -- jump to arg if zero
	constant OP_JNZ 		: std_logic_vector(7 downto 0):="10000110";  -- jump to arg if non zero
	constant OP_JC  		: std_logic_vector(7 downto 0):="10001001";  -- jump to arg if carry
	constant OP_JNC 		: std_logic_vector(7 downto 0):="10001000";  -- jump to arg if no carry
	
	
	-- port i/o instructions 
	-- prefix 101
	constant OP_IN 			: std_logic_vector(7 downto 0):="10100000";
	constant OP_OUT 		: std_logic_vector(7 downto 0):="10100001";
	
	-- special instructions 
	-- prefix 000
	constant OP_HLT 			    : std_logic_vector(7 downto 0):="00000000";
	constant OP_NOP 				: std_logic_vector(7 downto 0):="00000001";
	constant OP_SEVENSEGTRANSLATE 	: std_logic_vector(7 downto 0):="00000010";
	
end package opcodes;