library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

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

		-- aalu control 
		aalu_opcode_o			: out std_logic_vector(3 downto 0);
		aalu_left_o				: out std_logic_vector(7 downto 0);
		aalu_right_o			: out std_logic_vector(7 downto 0);
		aalu_carry_in_o			: out std_logic;
		aalu_result_i			: in std_logic_vector(7 downto 0);
		aalu_flags_i			: in ALU_flags;

		-- pio 
		pio_address_o			: out std_logic_vector(7 downto 0);
		pio_data_o				: out std_logic_vector(7 downto 0); -- data entering IO port 
		pio_data_i				: in std_logic_vector(7 downto 0);
		pio_write_enable_o		: out std_logic;
		pio_read_enable_o		: out std_logic;
		pio_io_ready_i			: in std_logic;
		
		-- direct access to the video adapter 
		vga_pos_x_o				: out std_logic_vector(6 downto 0); -- 0-79 - enough 7 bits 
		vga_pos_y_o				: out std_logic_vector(4 downto 0); -- 0-29 - enough 5 bits
		vga_chr_o				: out std_logic_vector(7 downto 0); 
		vga_clr_o				: out std_logic_vector(7 downto 0); 
		vga_write_enable_o		: out std_logic;

		dbg_lr_o				: out std_logic_vector(7 downto 0);
		dbg_rr_o				: out std_logic_vector(7 downto 0);
		dbg_rv_o				: out std_logic_vector(7 downto 0);	
		dbg_state_o				: out cpu_state_type;
		dbg_pc_o				: out std_logic_vector(7 downto 0);	
		dbg_f_o					: out ALU_flags := (others => '0');
		dbg_ir_o				: out std_logic_vector(7 downto 0)		  
	);
end controlunit;

architecture behaviour of controlunit is

	type regfile_type is array (0 to 15) of std_logic_vector(7 downto 0);
	
	signal regfile					: regfile_type := (others => (others => '0'));
	signal left_arg_reg_value		: std_logic_vector(7 downto 0);
	signal right_arg_reg_value		: std_logic_vector(7 downto 0);
	signal right_arg_expl_value		: std_logic_vector(7 downto 0);

	signal cpu_state				: cpu_state_type;
	signal program_counter			: std_logic_vector(7 downto 0);

	signal flags					: ALU_flags := (others => '0');
	signal instruction_code			: std_logic_vector(7 downto 0);
	
	-- signal clk_counter			   : std_logic_vector(31 downto 0) := (others => '0');

	signal wait_counter				: std_logic_vector(24 downto 0) := (others => '0');

begin

	dbg_lr_o	<= left_arg_reg_value;
	dbg_rr_o	<= right_arg_reg_value;
	dbg_rv_o	<= right_arg_expl_value;
	dbg_state_o <= cpu_state;
	dbg_pc_o	<= program_counter;	
	dbg_f_o		<= flags;
	dbg_ir_o	<= instruction_code;

	process (clk_i, reset_i)
		variable jump_state : cpu_state_type; 
		variable jump_cond_match : boolean;
		variable jump_addr : std_logic_vector(7 downto 0);
	begin
		if reset_i = '1' 
		then
			cpu_state <= FETCH_0;
			program_counter <= "00000000";
			mem_write_o <= '0';
			mem_read_o <= '0';
			mem_address_o <= "00000000";
			mem_data_o <= "00000000";	

			aalu_opcode_o	<= ALU_NOP;
			aalu_carry_in_o <= '0';
			aalu_left_o	 <= (others => '0');
			aalu_right_o <= (others => '0');
			
			pio_address_o <= "00000000"; 
			pio_data_o <= "00000000"; 
			pio_write_enable_o <= '0';
			pio_read_enable_o	 <= '0';
			
			flags <= (others => '0');
			error_o <= '0';
			
			-- clk_counter	<= (others => '0');
			
			vga_pos_x_o			<= (others => '0'); 
			vga_pos_y_o			<= (others => '0');
			vga_chr_o			<= (others => '0');
			vga_clr_o			<= (others => '0');
			vga_write_enable_o	<= '0';

			
		elsif rising_edge(clk_i) 
		then
			-- clk_counter <= clk_counter + 1;

			mem_write_o <= '0'; -- set it off by default unless we want it 
			mem_read_o <= '0';
			vga_write_enable_o <= '0';
			
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

					cpu_state <= FETCH_2;
					
				when FETCH_2 =>				
					instruction_code <= mem_data_i;
					cpu_state <= DECODE;

				when DECODE =>
					left_arg_reg_value	<= regfile(to_integer(unsigned(mem_data_i(7 downto 4))));
					right_arg_reg_value	<=	regfile(to_integer(unsigned(mem_data_i(3 downto 0))));
					right_arg_expl_value <= "0000" & mem_data_i(3 downto 0); 

					case instruction_code(7 downto 4) is 
						when OP_ST => 
							left_arg_reg_value	<= regfile(to_integer(unsigned(instruction_code(3 downto 0))));
							cpu_state <= EXECUTE_ST_1;

						when OP_LD => 
							cpu_state <= EXECUTE_LD_1;

						when OP_LDC =>
							cpu_state <= EXECUTE_LD_VAL_1;
						
						when OP_AALU_RR => 
							aalu_opcode_o <= instruction_code(3 downto 0);
							aalu_carry_in_o <= flags.carry_out;
							aalu_left_o <= regfile(to_integer(unsigned(mem_data_i(7 downto 4))));
							aalu_right_o <= regfile(to_integer(unsigned(mem_data_i(3 downto 0))));
							cpu_state <= STORE;

						when OP_AALU_RV => 
							aalu_opcode_o <= instruction_code(3 downto 0);
							aalu_carry_in_o <= flags.carry_out;
							aalu_left_o <= regfile(to_integer(unsigned(mem_data_i(7 downto 4))));
							aalu_right_o <= "0000" & mem_data_i(3 downto 0);
							cpu_state <= STORE;

						when OP_SALU_RR | OP_SALU_RV =>
							error_o <= '1';
							cpu_state <= STOP; -- SALU is not implemented yet
						
						when OP_MOVE_GROUP => 
							case instruction_code(3 downto 2) is 
								when MOVE_TYPE_RR	=>	cpu_state <= EXECUTE_MOV_RR;
								when MOVE_TYPE_RA	=>	cpu_state <= EXECUTE_MOV_RA_1;
								when MOVE_TYPE_AR	=>	cpu_state <= EXECUTE_MOV_AR_1;
								when others =>			cpu_state <= STOP;
							end case;
						
						when OP_JMP_ABS_GROUP | OP_JMP_REL_GROUP | OP_JMP_R_GROUP => 

							case instruction_code(5 downto 4) is 
								when JMP_ABS	=>	jump_state := EXECUTE_JMP_ABS;
								when JMP_REL	=>	jump_state := EXECUTE_JMP_REL;
								when JMP_R		=>	jump_state := EXECUTE_JMP_REG;
								when others		=>	jump_state := STOP;
							end case;
							
							jump_cond_match := false;
							
							case instruction_code(3 downto 0) is 
								when JMP_UNCOND			=> jump_cond_match := true;
								when JMP_POS | JMP_NEG	=> jump_cond_match := flags.negative = instruction_code(0);
								when JMP_NV	 | JMP_V	=> jump_cond_match := flags.overflow = instruction_code(0);
								when JMP_NZ	 | JMP_Z	=> jump_cond_match := flags.zero = instruction_code(0);
								when JMP_NC	 | JMP_C	=> jump_cond_match := flags.carry_out = instruction_code(0);
								when others				=> jump_cond_match := false;
							end case;

							if jump_cond_match 
							then
								cpu_state <= jump_state;
							else
								cpu_state <= FETCH_0;
							end if;

						when OP_IN_GROUP => 
							cpu_state <= EXECUTE_PORT_IN_1;

						when OP_OUT_GROUP => 
							cpu_state <= EXECUTE_PORT_OUT_1;
						
						when OP_SPECIAL_GROUP => 
							case instruction_code is 
								when OP_NOP =>
									cpu_state <= FETCH_0;

								when OP_HLT =>
									cpu_state <= STOP;

								when OP_SEVENSEGTRANSLATE =>
									aalu_opcode_o <= ALU_SHR;
									aalu_carry_in_o <= '0';									
									aalu_left_o <= regfile(to_integer(unsigned(mem_data_i(7 downto 4))));
									aalu_right_o <= "0000" & mem_data_i(3 downto 0);
									cpu_state <= EXECUTE_7SEG_1;
									
									
								when OP_SETXY => 
									cpu_state <= EXECUTE_SET_XY;

								when OP_SETC => 
									cpu_state <= EXECUTE_SET_CHAR;
								
								when OP_SETCLR => 
									cpu_state <= EXECUTE_SET_COLOR;

								when OP_WAIT => 
									cpu_state <= EXECUTE_WAIT_1;

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
					mem_data_o <= left_arg_reg_value;
					mem_write_o <= '1';
					-- cpu_state <= EXECUTE_ST_2;	-- go to FETCH_0 ?
					cpu_state <= FETCH_0;

				when EXECUTE_ST_2  => 
					cpu_state <= FETCH_0;


				when EXECUTE_LD_1  =>  
					mem_address_o <= mem_data_i;
					mem_read_o <= '1';
					cpu_state <= EXECUTE_LD_2;

				when EXECUTE_LD_2  =>
					cpu_state <= EXECUTE_LD_3;

				when EXECUTE_LD_3  =>  
					regfile(to_integer(unsigned(instruction_code(3 downto 0)))) <= mem_data_i;					
					cpu_state <= FETCH_0;


				when EXECUTE_LD_VAL_1  =>  
					regfile(to_integer(unsigned(instruction_code(3 downto 0)))) <= mem_data_i;
					cpu_state <= FETCH_0;

					
				when EXECUTE_MOV_RR	 =>	 
					regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= right_arg_reg_value;
					cpu_state <= FETCH_0;
					

				when EXECUTE_MOV_RA_1  =>  
					left_arg_reg_value <= mem_data_i; 
					mem_address_o <= right_arg_reg_value;
					mem_read_o	<= '1';
					cpu_state <= EXECUTE_MOV_RA_2;
				when EXECUTE_MOV_RA_2  =>  
					cpu_state <= EXECUTE_MOV_RA_3;
				when EXECUTE_MOV_RA_3  =>  
					regfile(to_integer(unsigned(left_arg_reg_value(7 downto 4)))) <= mem_data_i;
					cpu_state <= FETCH_0;

				when EXECUTE_MOV_AR_1  =>  
					mem_address_o <= left_arg_reg_value;					
					mem_data_o <= right_arg_reg_value;
					mem_write_o <= '1';
					cpu_state <= EXECUTE_MOV_AR_2;	 -- go to FETCH_0 ?

				when EXECUTE_MOV_AR_2  =>  
					cpu_state <= FETCH_0;


				when EXECUTE_JMP_ABS  => 
					program_counter <= mem_data_i;
					cpu_state <= FETCH_0;
										

				when EXECUTE_JMP_REL  => 
					program_counter <= program_counter + mem_data_i;
					cpu_state <= FETCH_0;
				
				when EXECUTE_JMP_REG => 
					program_counter <= left_arg_reg_value + right_arg_expl_value;
					cpu_state <= FETCH_0; 

				when EXECUTE_PORT_IN_1	=> 
					pio_address_o <= mem_data_i;
					pio_read_enable_o <= '1';
					cpu_state <= EXECUTE_PORT_IN_2;
				when EXECUTE_PORT_IN_2	=> 
					if pio_io_ready_i = '1' then 
						regfile(to_integer(unsigned(instruction_code(3 downto 0)))) <= pio_data_i;
						pio_read_enable_o <= '0';
						cpu_state <= FETCH_0;
					end if;

				when EXECUTE_PORT_OUT_1	 => 
					pio_address_o <= mem_data_i;
					pio_write_enable_o <= '1';
					pio_data_o <= regfile(to_integer(unsigned(instruction_code(3 downto 0))));
					cpu_state <= EXECUTE_PORT_OUT_2;
				when EXECUTE_PORT_OUT_2 => 
					if pio_io_ready_i = '1' then 
						cpu_state <= FETCH_0;
						pio_write_enable_o <= '0';
					end if;

				when STORE	=>	
					regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= aalu_result_i;
					flags <= aalu_flags_i;
					aalu_opcode_o <= ALU_NOP;
										
					cpu_state <= FETCH_0;

				when EXECUTE_7SEG_1 => 
					aalu_opcode_o <= ALU_NOP;

					case aalu_result_i(3 downto 0) is 
						when "0000" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "11111100";
						when "0001" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "01100000";
						when "0010" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "11011010";
						when "0011" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "11110010"; 
						when "0100" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "01100110";
						when "0101" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "10110110";
						when "0110" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "10111110";
						when "0111" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "11100000";
						when "1000" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "11111110";
						when "1001" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "11110110";
						when "1010" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "11101110";
						when "1011" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "00111110";
						when "1100" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "10011100";
						when "1101" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "01111010";
						when "1110" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "10011110";
						when "1111" => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "10001110";								 
						when others => regfile(to_integer(unsigned(mem_data_i(7 downto 4)))) <= "00000010";
					end case;
					cpu_state <= FETCH_0; 


				when EXECUTE_SET_XY => 
					vga_pos_x_o <= left_arg_reg_value(6 downto 0);
					vga_pos_y_o <= right_arg_reg_value(4 downto 0);
					cpu_state <= FETCH_0; 

				when EXECUTE_SET_CHAR => 
					vga_chr_o <= left_arg_reg_value;
					vga_clr_o <= right_arg_reg_value;
					vga_write_enable_o <= '1';					
					cpu_state <= FETCH_0; 
				
				when EXECUTE_SET_COLOR => 
					vga_clr_o <= left_arg_reg_value;
					cpu_state <= FETCH_0; 

				when EXECUTE_WAIT_1 => 
					wait_counter(24 downto 17) <= mem_data_i;
					wait_counter(16 downto 0) <= (others => '0');
					cpu_state <= EXECUTE_WAIT_2;
				
				when EXECUTE_WAIT_2 => 
					if wait_counter(24 downto 17) = 0 
					then 
						cpu_state <= FETCH_0;
					else
						wait_counter <= wait_counter -1;
					end if;

				when others => 
					cpu_state <= STOP;
					error_o <= '1';
			end case;
		end if;
	end process;
end behaviour;
