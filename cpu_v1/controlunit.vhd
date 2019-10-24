library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;

use work.opcodes.all;
use work.types.all;

entity controlunit is
	port
	(
		clk_i					: in std_logic;
		reset_i					: in std_logic;
		error_o					: out std_logic;
		
		-- memory interface 
		mem_address_o			: out std_logic_vector(7 downto 0);
		mem_data_i				: in std_logic_vector(7 downto 0);
		mem_data_o				: out std_logic_vector(7 downto 0);
		mem_read_o				: out std_logic;
		mem_write_o				: out std_logic;
		
		-- regfile interface
		reg_read_select_a_o 	: out std_logic_vector(3 downto 0); -- hard-wired to mem_data_i(7 downto 4)
		reg_read_select_b_o 	: out std_logic_vector(3 downto 0); -- hard-wired to mem_data_i(3 downto 0)
		reg_read_select_c_o 	: out std_logic_vector(3 downto 0); -- latched 
		reg_write_select_o 		: out std_logic_vector(3 downto 0); -- latched 
		reg_write_enable_o 		: out std_logic;		
		reg_port_a_data_read_i 	: in std_logic_vector (7 downto 0); 
		reg_port_b_data_read_i 	: in std_logic_vector (7 downto 0); 
		reg_port_c_data_read_i 	: in std_logic_vector (7 downto 0); 
		reg_write_data_o 		: out  std_logic_vector (7 downto 0);

		-- aalu control 
		aalu_opcode_o 			: out alu_opcode_type;
		aalu_carry_in_o			: out std_logic;		
		aalu_right_val_o		: out std_logic_vector(7 downto 0);
		aalu_right_select_o 	: out ALU_arg_select;
		aalu_result_i			: in std_logic_vector(7 downto 0);
		aalu_flags_i			: in ALU_flags;

		-- pio 
		pio_address_o 			: out std_logic_vector(7 downto 0);
		pio_data_o				: out std_logic_vector(7 downto 0); -- data entering IO port 
		pio_data_i				: in std_logic_vector(7 downto 0);
		pio_write_enable_o		: out std_logic;
		pio_read_enable_o		: out std_logic;
		pio_io_ready_i			: in std_logic;
		
		
		-- debug stuff 
		dbg_pc_o				: out std_logic_vector(7 downto 0);
		dbg_ir_o				: out std_logic_vector(7 downto 0); 
		dbg_state_o				: out cpu_state_type;
		dbg_clk_cnt_o			: out std_logic_vector(31 downto 0);
		dbg_inst_cnt_o			: out std_logic_vector(31 downto 0)
		
	);
end controlunit;

architecture behaviour of controlunit is

	signal cpu_state 				: cpu_state_type;
	signal program_counter	 		: std_logic_vector(7 downto 0);

	signal flags					: ALU_flags := (others => '0');
	signal instruction_code			: std_logic_vector(7 downto 0);
	
	signal clk_counter				: std_logic_vector(31 downto 0) := (others => '0');
	signal inst_counter				: std_logic_vector(31 downto 0) := (others => '0');
	
		
begin

	dbg_pc_o <= program_counter;
	debug_accumulator	 <= (others => '0');
	dbg_ir_o <=	instruction_code;
	dbg_state_o <= cpu_state;

	dbg_clk_cnt_o	<= clk_counter;
	dbg_inst_cnt_o	<= inst_counter;

	-- hard-wire register select signals to the current memory data input, 
	-- thus we can have registers auto-selected fo commands using 2nd argument 
	-- as REG-REG or REG-VAL 
	reg_read_select_a_o <= mem_data_i(7 downto 4); -- hard-wired 
	reg_read_select_b_o <= mem_data_i(3 downto 0); -- hard-wired 
	
	-- same as registers - hard-wire for REG-VAL ALU operations
	aalu_right_val_o <= "0000" & mem_data_i(3 downto 0); 

	process (clk_i, reset_i, program_counter, accumulator)
		variable jump_state : cpu_state; 
		variable jump_cond_match : boolean;
	begin
		if reset_i = '1' 
		then
			cpu_state <= FETCH_0;
			program_counter <= "00000000";
			mem_write_o <= '0';
			mem_read_o <= '0';
			mem_address_o <= "00000000";
			mem_data_o <= "00000000";	

			aalu_opcode_o 	<= ALU_NOP;
			aalu_carry_in_o	<= '0';
			aalu_right_select_o 	<= reg_port;

			reg_write_enable_o <= '0';
			reg_read_select_c_o <= (others => '0');
			reg_write_select_o 	<= (others => '0');
			reg_write_data_o 	<= (others => '0');
			
			pio_address_o <= "00000000"; 
			pio_data_o <= "00000000"; 
			pio_write_enable_o <= '0';
			pio_read_enable_o	 <= '0';
			
			flags <= (others => '0');
			error_o <= '0';
			
			clk_counter <= (others => '0');
			inst_counter <= (others => '0');

		elsif rising_edge(clk_i) 
		then
			clk_counter <= clk_counter + 1;

			mem_write_o <= '0'; -- set it off by default unless we want it 
			mem_read_o <= '0';
			reg_write_enable_o <= '0'; 
			
			case cpu_state is
				when STOP => 
					cpu_state <= STOP;

				when FETCH_0 =>
					-- set instruction address on the memory bus
					mem_address_o <= program_counter;
					mem_read_o <= '1';
					program_counter <= program_counter + 1;
					cpu_state <= FETCH_1;
					
				when FETCH_1 =>
					-- set instruction address on the memory bus, 
					-- data from the FETCH_0 is still travelling through FF-s
					mem_address_o <= program_counter;
					mem_read_o <= '1';
					program_counter <= program_counter + 1;

					cpu_state <= DECODE;
					
					inst_counter <= inst_counter + 1;
					
				when DECODE =>
					-- instruction code would have just arrive by now in the data IN
					instruction_code <= mem_data_i;
				
					case mem_data_i(7 downto 4) is 
						when OP_NOP =>
							cpu_state <= FETCH_0;

						when OP_ST => 
							reg_read_select_c_o <= mem_data_i(3 downto 0); -- use latched 
							cpu_state <= EXECUTE_ST_1;

						when OP_LD => 
							reg_write_select_o <= mem_data_i(3 downto 0);
							cpu_state <= EXECUTE_LD_1;

						when OP_LDC =>
							reg_write_select_o <= mem_data_i(3 downto 0);
							cpu_state <= EXECUTE_LD_VAL_1;
						
						when OP_AALU_RR => 
							aalu_opcode_o <= mem_data_i(3 downto 0);
							aalu_carry_in_o <= flags.carry_out;
							aalu_right_select_o <= reg_port;
							state <= STORE;

						when OP_AALU_RV => 
							aalu_opcode_o <= mem_data_i(3 downto 0);
							aalu_carry_in_o <= flags.carry_out;
							aalu_right_select_o <= value_port;
							state <= STORE;

						when OP_SALU_RR | OP_SALU_RV =>
							error_o <= '1';
							cpu_state <= STOP; -- SALU is not implemented yet
						
						when OP_MOVE_GROUP => 
							case mem_data_i(3 downto 2) is 
								when MOVE_TYPE_RR	=> 	cpu_state <= EXECUTE_MOV_RR;
								when MOVE_TYPE_RA	=> 	cpu_state <= EXECUTE_MOV_RA_1;
								when MOVE_TYPE_AR	=> 	cpu_state <= EXECUTE_MOV_AR_1;
								when others => 			cpu_state <= STOP;
							end case;
						
						when OP_JMP_ABS_GROUP | OP_JMP_REL_GROUP | OP_JMP_R_GROUP => 

							case mem_data_i(5 downto 4) is 
								when JMP_ABS	=> 	jump_state := EXECUTE_JMP_ABS;
								when JMP_REL	=> 	jump_state := EXECUTE_JMP_REL;
								when JMP_R		=> 	jump_state := EXECUTE_JMP_REG_1;
								when others 	=> 	jump_state := STOP;
							end case;
							
							jump_cond_match := false;
							
							case mem_data_i(3 downto 0) is 
								when JMP_UNCOND 		=> jump_cond_match := true;
								when JMP_POS | JMP_NEG  => jump_cond_match := flags.negative = mem_data_i(0);
								when JMP_NV  | JMP_V 	=> jump_cond_match := flags.overflow = mem_data_i(0);
								when JMP_NZ  | JMP_Z 	=> jump_cond_match := flags.zero = mem_data_i(0);
								when JMP_NC  | JMP_C 	=> jump_cond_match := flags.carry_out = mem_data_i(0);
								when others 			=> jump_cond_match := false;
							end case;

							if jump_cond_match 
							then
								cpu_state <= jump_state;
							else
								cpu_state <= FETCH_0;
							end if;

						when OP_IN_GROUP => 
							reg_write_select_o <= mem_data_i(3 downto 0);
							cpu_state <= EXECUTE_PORT_IN_1;

						when OP_OUT_GROUP => 
							reg_read_select_c_o <= mem_data_i(3 downto 0); -- latched read port 
							cpu_state <= EXECUTE_PORT_OUT_1;
						
						when OP_SPECIAL_GROUP => 
							case mem_data_i is 
								when OP_HLT =>
									cpu_state <= STOP;

								when OP_SEVENSEGTRANSLATE =>
									aalu_opcode_o <= ALU_SHR;
									aalu_carry_in_o <= '0';
									aalu_right_select_o <= value_port;								
									cpu_state <= EXECUTE_7SEG_1;

								when others =>
									error_o <= '1';
									cpu_state <= STOP;							
							end case;
						
						when others => 
							error_o <= '1';
							cpu_state <= STOP;
	
					end case;
				
				
				when EXECUTE_ST_1  =>  
 					mem_address_o <= mem_data_i;					
 					mem_data_o <= reg_port_c_data_read_i;
 					mem_write_o <= '1';
 					cpu_state <= EXECUTE_ST_2;	-- go to FETCH_0 ?

				when EXECUTE_ST_2  => 
					cpu_state <= FETCH_0;


				when EXECUTE_LD_1  =>  
 					mem_address_o <= mem_data_i;
 					mem_read_o <= '1';
 					cpu_state <= EXECUTE_LD_2;

				when EXECUTE_LD_2  =>
 					cpu_state <= EXECUTE_LD_3;

				when EXECUTE_LD_3  =>  
					reg_write_data_o <= mem_data_i;
					reg_write_enable_o <= '1';
 					cpu_state <= FETCH_0;


				when EXECUTE_LD_VAL_1  =>  
					reg_write_data_o <= mem_data_i;
					reg_write_enable_o <= '1';
 					cpu_state <= FETCH_0;

-- 				when EXECUTE_ALU_RR  => 
-- 					-- reg-reg
-- 					reg_write_select_o	<= mem_data_i(7 downto 4); -- left reg
-- 					reg_read_select_a_o	<= mem_data_i(7 downto 4);
-- 					reg_read_select_b_o	<= mem_data_i(3 downto 0);
--  					cpu_state <= STORE;
-- 
-- 				when EXECUTE_ALU_RV  => 
-- 					-- reg-val
-- 					reg_write_select_o	<= mem_data_i(7 downto 4); -- left reg
-- 					reg_read_select_a_o	<= mem_data_i(7 downto 4);
-- 					aalu_right_val_o	<= "0000" & mem_data_i(3 downto 0);
--  					cpu_state <= STORE;

				when EXECUTE_MOV_RR  =>  
					reg_write_select_o	<= mem_data_i(7 downto 4); -- left reg of the op 
					reg_write_data_o 	<= reg_port_b_data_read_i;
					reg_write_enable_o 	<= '1';	
 					cpu_state <= FETCH_0;

				when EXECUTE_MOV_RA_1  =>  
					reg_write_select_o	<= mem_data_i(7 downto 4); -- left reg of the op 
					mem_address_o <= reg_port_b_data_read_i;
 					mem_read_o 	<= '1';
					cpu_state <= EXECUTE_MOV_RA_2;
				when EXECUTE_MOV_RA_2  =>  
					cpu_state <= EXECUTE_MOV_RA_3;
				when EXECUTE_MOV_RA_3  =>  
					reg_write_data_o <= mem_data_i;
					reg_write_enable_o <= '1';
 					cpu_state <= FETCH_0;

				when EXECUTE_MOV_AR_1  =>  
					mem_address_o <= reg_port_a_data_read_i;					
 					mem_data_o <= reg_port_b_data_read_i;
 					mem_write_o <= '1';
 					cpu_state <= EXECUTE_MOV_AR_2;	-- go to FETCH_0 ?

				when EXECUTE_MOV_AR_2  =>  
					cpu_state <= FETCH_0;


				when EXECUTE_JMP_ABS  => 
 					program_counter <= mem_data_i;
 					cpu_state <= FETCH_0;
				
				when EXECUTE_JMP_REL  => 
 					program_counter <= program_counter + mem_data_i;
 					cpu_state <= FETCH_0;
				
				when EXECUTE_JMP_REG => 
					program_counter <= reg_port_a_data_read_i + ("0000" + mem_data_i(3 downto 0))
					cpu_state => FETCH_0;				


				when EXECUTE_PORT_IN_1  => 
					pio_address_o <= mem_data_i;
					pio_read_enable_o <= '1';
					cpu_state <= EXECUTE_PORT_IN_2;
				when EXECUTE_PORT_IN_2  => 
					if pio_io_ready_i = '1' then 
						reg_write_data_o 	<= pio_data_i;
						reg_write_enable_o 	<= '1';	
						pio_read_enable_o <= '0';
						cpu_state <= FETCH_0;
					end if;

				when EXECUTE_PORT_OUT_1  => 
					pio_address_o <= mem_data_i;
					pio_write_enable_o <= '1';
					pio_data_o <= reg_port_c_data_read_i;
					cpu_state <= EXECUTE_PORT_OUT_2;
				when EXECUTE_PORT_OUT_2 => 
					if pio_io_ready_i = '1' then 
						cpu_state <= FETCH_0;
						pio_write_enable_o <= '0';
					end if;

				when STORE  =>  
					reg_write_select_o	<= mem_data_i(7 downto 4); -- left reg of the op 
					reg_write_data_o 	<= aalu_result_i;
					reg_write_enable_o 	<= '1';	
 					flags <= aalu_flags_i;
 					cpu_state <= FETCH_0;

 				when EXECUTE_7SEG_1 => 
					reg_write_select_o	<= mem_data_i(7 downto 4); -- left reg of the op 
					reg_write_enable_o 	<= '1';	

 					case aalu_result_i(3 downto 0) is 
 						when "0000" => reg_write_data_o <= "11111100";
 						when "0001" => reg_write_data_o <= "01100000";
 						when "0010" => reg_write_data_o <= "11011010";
 						when "0011" => reg_write_data_o <= "11110010"; 
 						when "0100" => reg_write_data_o <= "01100110";
 						when "0101" => reg_write_data_o <= "10110110";
 						when "0110" => reg_write_data_o <= "10111110";
 						when "0111" => reg_write_data_o <= "11100000";
 						when "1000" => reg_write_data_o <= "11111110";
 						when "1001" => reg_write_data_o <= "11110110";
 						when "1010" => reg_write_data_o <= "11101110";
 						when "1011" => reg_write_data_o <= "00111110";
 						when "1100" => reg_write_data_o <= "10011100";
 						when "1101" => reg_write_data_o <= "01111010";
 						when "1110" => reg_write_data_o <= "10011110";
 						when "1111" => reg_write_data_o <= "10001110";								
 						when others => reg_write_data_o <= "00000010";
 					end case;
 					cpu_state <= FETCH_0; 

			end case;
		end if;
	end process;
end behaviour;
