library ieee ;
use ieee.std_logic_1164.all ;


package types is

	type ALU_flags is record
		negative		: std_logic;
		zero			: std_logic;
		carry_out		: std_logic; -- means "borrow out" for sub
		overflow		: std_logic;
		divide_by_zero	: std_logic;
	end record ALU_flags;

	type cpu_state_type is (
		
		FETCH_0, 
		FETCH_1,
		FETCH_2,

		DECODE,
		
		EXECUTE_ST_1, 
		EXECUTE_ST_2,
		
		EXECUTE_LD_1, 
		EXECUTE_LD_2, 
		EXECUTE_LD_3, 
		
		EXECUTE_LD_VAL_1, 
		
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
		
		EXECUTE_SET_XY, 
		EXECUTE_SET_CHAR,
		
		EXECUTE_WAIT_1, EXECUTE_WAIT_2,
		
		WAIT_AND_STORE_SALU_1, WAIT_AND_STORE_SALU_2,

		STORE, 
		
		STOP
	);
	
end package types;