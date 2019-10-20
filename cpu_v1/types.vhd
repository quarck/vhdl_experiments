library ieee ;
use ieee.std_logic_1164.all ;


package types is

	type ALU_flags is record
		negative		: std_logic;
		zero 			: std_logic;
		carry_out 		: std_logic; -- means "borrow out" for sub
		overflow 		: std_logic;
	end record ALU_flags;
	
	type cpu_state_type is (
		
		FETCH_0, 
		FETCH_1,

		DECODE,
		
		EXECUTE_STA_1, 
		EXECUTE_STA_2,
		
		EXECUTE_LDA_MEM_1, 
		EXECUTE_LDA_MEM_2, 
		EXECUTE_LDA_MEM_3, 
		
		EXECUTE_LDA_VAL_1, 
		
		EXECUTE_ALU_REGMEM_1, 
		EXECUTE_ALU_REGMEM_2, 
		EXECUTE_ALU_REGMEM_3, 

		EXECUTE_ALU_REGMEM_INV_1, 
		EXECUTE_ALU_REGMEM_INV_2, 
		EXECUTE_ALU_REGMEM_INV_3, 
		
		EXECUTE_ALU_REGVAL_1,
		
		EXECUTE_ALU_REGVAL_INV_1,
		
		EXECUTE_SEVENSEGMENTTRANSLATE_1,
		EXECUTE_SEVENSEGMENTTRANSLATE_2,
		
		EXECUTE_JMP,
		EXECUTE_JMP_A,

		EXECUTE_PORT_IN_1,
		EXECUTE_PORT_IN_2,

		EXECUTE_PORT_OUT_1,
		EXECUTE_PORT_OUT_2,

		STORE, 
		
		STOP
	);
	
end package types;