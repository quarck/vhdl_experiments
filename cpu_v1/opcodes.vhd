library ieee ;
use ieee.std_logic_1164.all ;


package opcodes is
 	
	-- high bit set to 0 - simple operations, async ALU 
 	constant ALU_NOP  : alu_opcode_type := "0000";
 	constant ALU_ADD  : alu_opcode_type := "0001";
	constant ALU_ADDC : alu_opcode_type := "0010";
 	constant ALU_SUB  : alu_opcode_type := "0011";
	constant ALU_SUBC : alu_opcode_type := "0100";
 	constant ALU_NEG  : alu_opcode_type := "0101";
	constant ALU_OR   : alu_opcode_type := "0110";
	constant ALU_AND  : alu_opcode_type := "0111";
	constant ALU_XOR  : alu_opcode_type := "1000";
	constant ALU_NOT  : alu_opcode_type := "1001";
 	constant ALU_SHL  : alu_opcode_type := "1010";
 	constant ALU_SHR  : alu_opcode_type := "1011";
 	constant ALU_SHAR : alu_opcode_type := "1100";
	
	-- heavy sync monsters taking multiple cycles to complete 
 	constant ALU_MUL  : alu_opcode_type := "0001";
 	constant ALU_IMUL : alu_opcode_type := "0010";
 	constant ALU_DIV  : alu_opcode_type := "0011";
 	constant ALU_IDIV : alu_opcode_type := "0100";

	constant R0 		: std_logic_vector(4 downto 0) := "0000";
	constant R1 		: std_logic_vector(4 downto 0) := "0001";
	constant R2 		: std_logic_vector(4 downto 0) := "0010";
	constant R3 		: std_logic_vector(4 downto 0) := "0011";
	constant R4 		: std_logic_vector(4 downto 0) := "0100";
	constant R5 		: std_logic_vector(4 downto 0) := "0101";
	constant R6 		: std_logic_vector(4 downto 0) := "0110";
	constant R7 		: std_logic_vector(4 downto 0) := "0111";
	constant R8 		: std_logic_vector(4 downto 0) := "1000";
	constant R9 		: std_logic_vector(4 downto 0) := "1001";
	constant R10		: std_logic_vector(4 downto 0) := "1010";
	constant R11		: std_logic_vector(4 downto 0) := "1011";
	constant R12		: std_logic_vector(4 downto 0) := "1100";
	constant R13		: std_logic_vector(4 downto 0) := "1101";
	constant R14		: std_logic_vector(4 downto 0) := "1110";
	constant R15		: std_logic_vector(4 downto 0) := "1111";

	-- constant definition for various CPU instructions 
		
	-- load/store instructions, lower 4 bits indicate the register, second byte - addr or value
	constant OP_ST  		: std_logic_vector(3 downto 0) := "0001";  -- mem[arg] = reg[A]
	constant OP_LD  		: std_logic_vector(3 downto 0) := "0010";  -- reg[A] = mem[arg]
	constant OP_LDC 		: std_logic_vector(3 downto 0) := "0011";  -- reg[A] = arg
	
	-- Async ALU reg-reg instructions, lower 4 bits - op, second byte - reg-reg 
	constant OP_AALU_RR		: std_logic_vector(3 downto 0) := "0100";

	-- Sync ALU reg-reg instructions, lower 4 bits - op, second byte - reg-reg 
	constant OP_SALU_RR		: std_logic_vector(3 downto 0) := "0101"; 

	-- Async ALU reg-val instructions, lower 4 bits - op, second byte - reg-val
	constant OP_AALU_RV		: std_logic_vector(3 downto 0) := "0110";
	
	-- Sync ALU reg-reg instructions, lower 4 bits - op, second byte - reg-val 
	constant OP_SALU_RV		: std_logic_vector(3 downto 0) := "0111"; 
	
	-- move instructions between reg and reg
	constant OP_MOVE_GROUP 	: std_logic_vector(3 downto 0) := "1000"; 
	
	constant MOVE_TYPE_RR : std_logic_vector(1 downto 0) := "00"; -- R <- R
	constant MOVE_TYPE_RA : std_logic_vector(1 downto 0) := "01"; -- R <- [R]
	constant MOVE_TYPE_AR : std_logic_vector(1 downto 0) := "10"; -- [R] <- R
	
	constant OP_MOVE_RR 	: std_logic_vector(7 downto 0) := OP_MOVE_GROUP & MOVE_TYPE_RR & "00"; 
	constant OP_MOVE_RA 	: std_logic_vector(7 downto 0) := OP_MOVE_GROUP & MOVE_TYPE_RA & "00";
	constant OP_MOVE_AR 	: std_logic_vector(7 downto 0) := OP_MOVE_GROUP & MOVE_TYPE_AR & "00";
		
	-- branching instructions 
	constant OP_JMP_FAMILY 		: std_logic_vector(1 downto 0) := "11";

	-- jump type: 
	constant JMP_ABS : std_logic_vector(1 downto 0) := "00";  -- arg is an absolute 8-bit addr 
	constant JMP_REL : std_logic_vector(1 downto 0) := "01";  -- arg is a relative addr, jump to PC+arg
	constant JMP_R   : std_logic_vector(1 downto 0) := "10";  -- arg points to a register + 4-bit offset 

	
	constant OP_JMP_ABS_GROUP 	: std_logic_vector(1 downto 0) := OP_JMP_FAMILY & JMP_ABS;
	constant OP_JMP_REL_GROUP 	: std_logic_vector(1 downto 0) := OP_JMP_FAMILY & JMP_REL;
	constant OP_JMP_R_GROUP 	: std_logic_vector(1 downto 0) := OP_JMP_FAMILY & JMP_R;
	
	-- jump cond: 
	constant JMP_UNCOND : std_logic_vector(3 downto 0) := "0000"; -- no conditions 
	constant JMP_POS 	: std_logic_vector(3 downto 0) := "1000"; -- flags.negative = 0
	constant JMP_NEG 	: std_logic_vector(3 downto 0) := "1001"; -- flags.negative = 1
	constant JMP_NV 	: std_logic_vector(3 downto 0) := "1010"; -- flags.overflow = 0
	constant JMP_V 		: std_logic_vector(3 downto 0) := "1011"; -- flags.overflow = 1
	constant JMP_NZ 	: std_logic_vector(3 downto 0) := "1100"; -- flags.zero = 0
	constant JMP_Z 		: std_logic_vector(3 downto 0) := "1101"; -- flags.zero = 1
	constant JMP_NC 	: std_logic_vector(3 downto 0) := "1110"; -- flags.carry = 0
	constant JMP_C 		: std_logic_vector(3 downto 0) := "1111"; -- flags.carry = 1
	
	constant OP_JMP_A_UNCOND  	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_ABS & JMP_UNCOND;
	constant OP_JMP_A_POS 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_ABS & JMP_POS;
	constant OP_JMP_A_NEG 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_ABS & JMP_NEG;
	constant OP_JMP_A_NV 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_ABS & JMP_NV;
	constant OP_JMP_A_ 		 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_ABS & JMP_V;
	constant OP_JMP_A_NZ 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_ABS & JMP_NZ;
	constant OP_JMP_A_ 		 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_ABS & JMP_Z;
	constant OP_JMP_A_NC 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_ABS & JMP_NC;
	constant OP_JMP_A_C 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_ABS & JMP_C;

	constant OP_JMP_REL_UNCOND  : std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_REL & JMP_UNCOND;
	constant OP_JMP_REL_POS 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_REL & JMP_POS;
	constant OP_JMP_REL_NEG 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_REL & JMP_NEG;
	constant OP_JMP_REL_NV 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_REL & JMP_NV;
	constant OP_JMP_REL_ 		: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_REL & JMP_V;
	constant OP_JMP_REL_NZ 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_REL & JMP_NZ;
	constant OP_JMP_REL_ 		: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_REL & JMP_Z;
	constant OP_JMP_REL_NC 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_REL & JMP_NC;
	constant OP_JMP_REL_C 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_REL & JMP_C;

	constant OP_JMP_R_UNCOND  	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_R & JMP_UNCOND;
	constant OP_JMP_R_POS 		: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_R & JMP_POS;
	constant OP_JMP_R_NEG 		: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_R & JMP_NEG;
	constant OP_JMP_R_NV 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_R & JMP_NV;
	constant OP_JMP_R_ 			: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_R & JMP_V;
	constant OP_JMP_R_NZ 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_R & JMP_NZ;
	constant OP_JMP_R_ 			: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_R & JMP_Z;
	constant OP_JMP_R_NC 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_R & JMP_NC;
	constant OP_JMP_R_C 	 	: std_logic_vector(7 downto 0) := OP_JMP_FAMILY & JMP_R & JMP_C;

	
	-- port i/o instructions 
	constant OP_IN_GROUP 	: std_logic_vector(3 downto 0) := "1001"; -- R <- port
	constant OP_OUT_GROUP 	: std_logic_vector(3 downto 0) := "1010"; -- port <- R

	constant OP_UNUSED_GROUP_2 	: std_logic_vector(3 downto 0) := "1011";
		
	-- special instructions 
	
	constant OP_SPECIAL_GROUP := std_logic_vector(3 downto 0) := "0000";
	
	constant OP_HLT 			    : std_logic_vector(7 downto 0) := "00000000";
	constant OP_NOP 				: std_logic_vector(7 downto 0) := "00000001";
	constant OP_SEVENSEGTRANSLATE 	: std_logic_vector(7 downto 0) := "00000010";
	
end package opcodes;