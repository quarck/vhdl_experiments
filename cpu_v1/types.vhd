library ieee ;
use ieee.std_logic_1164.all ;


package types is

	type ALU_flags is record
		negative		: std_logic;
		zero 			: std_logic;
		carry_out 		: std_logic; -- means "borrow out" for sub
		overflow 		: std_logic;
	end record ALU_flags;

	type ALU_arg_select is ( reg_port, value_port );

	type alu_opcode_type is std_logic_vector(3 downto 0); 	
	
	type cpu_state_type is (
		
		FETCH_0, 
		FETCH_1,

		DECODE,
		
		EXECUTE_ST_1, 
		EXECUTE_ST_2,
		
		EXECUTE_LD_1, 
		EXECUTE_LD_2, 
		EXECUTE_LD_3, 
		
		EXECUTE_LD_VAL_1, 
		
-- 		EXECUTE_ALU_RV,		
-- 		EXECUTE_ALU_RR,
		
		EXECUTE_MOV_RR, 
		
		EXECUTE_MOV_RA_1, 
		EXECUTE_MOV_RA_2, 
		EXECUTE_MOV_RA_3, 

		EXECUTE_MOV_AR_1, 
		EXECUTE_MOV_AR_2, 

		EXECUTE_7SEG_1,
		EXECUTE_7SEG_2,
		
		EXECUTE_JMP_ABS,
		EXECUTE_JMP_REL,
		EXECUTE_JMP_REG,

		EXECUTE_PORT_IN_1,
		EXECUTE_PORT_IN_2,

		EXECUTE_PORT_OUT_1,
		EXECUTE_PORT_OUT_2,

		STORE, 
		
		STOP
	);
	
end package types;