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
		
		-- address bus - multiplexed between memory and PIO 
		address_o				: out std_logic_vector(15 downto 0);
		
		-- data buses - multiplexed between port and memory 
		data_i					: in std_logic_vector(15 downto 0);
		data_o					: out std_logic_vector(15 downto 0);

		-- read/write controls for both memory and PIO
		read_enable_o			: out std_logic;
		read_select_o			: out data_select;
		write_enable_o			: out std_logic;
		write_select_o			: out data_select;

		pio_io_ready_i			: in std_logic;
	
		alu_operation_o			: out std_logic_vector(4 downto 0);
		alu_sync_select_o		: out std_logic; -- latched MSB of operation_i
		alu_left_h_o			: out std_logic_vector(15 downto 0);
		alu_left_l_o			: out std_logic_vector(15 downto 0);
		alu_right_l_o			: out std_logic_vector(15 downto 0);
		alu_carry_o				: out std_logic;
		alu_result_h_i			: in std_logic_vector(15 downto 0);
		alu_result_l_i			: in std_logic_vector(15 downto 0);
		alu_flags_i				: in ALU_flags;
		alu_sync_ready_i		: in std_logic;
		
		-- direct access to the video adapter 
		-- todo - remove this later in favour of using I/O ports 
		-- (even if we use dedicated opcodes for VGA, we can just use particular 
		-- port numbers for these 
		vga_pos_x_o				: out std_logic_vector(6 downto 0); -- 0-79 - enough 7 bits 
		vga_pos_y_o				: out std_logic_vector(4 downto 0); -- 0-29 - enough 5 bits
		vga_chr_o				: out std_logic_vector(7 downto 0); 
		vga_clr_o				: out std_logic_vector(7 downto 0); 
		vga_write_enable_o		: out std_logic;

		-- debug -- would be stripped out during synthesis 
		dbg_state_o				: out cpu_state_type;
		dbg_pc_o				: out std_logic_vector(15 downto 0);	
		dbg_f_o					: out ALU_flags := (others => '0');
		dbg_ir_o				: out std_logic_vector(15 downto 0)		  
	);
end controlunit;

architecture behaviour of controlunit is

	type regfile_type is array (0 to 15) of std_logic_vector(15 downto 0);
	
	signal regfile					: regfile_type := (others => (others => '0'));

	signal cpu_state				: cpu_state_type;
	signal program_counter			: std_logic_vector(15 downto 0);

	signal flags					: ALU_flags := (others => '0');
	signal instruction_register			: std_logic_vector(15 downto 0);
	
	-- signal clk_counter			   : std_logic_vector(31 downto 0) := (others => '0');

	signal wait_counter				: std_logic_vector(24 downto 0) := (others => '0');

begin

	dbg_state_o <= cpu_state;
	dbg_pc_o	<= program_counter;	
	dbg_f_o		<= flags;
	dbg_ir_o	<= instruction_register;

	process (clk_i, reset_i)
		variable jump_state : cpu_state_type; 
		variable jump_cond_match : boolean;
		variable jump_addr : std_logic_vector(15 downto 0);
	begin
		if reset_i = '1' 
		then
			cpu_state <= FETCH_0;
			program_counter <= "0000000000000000";
			flags <= (others => '0');
			error_o <= '0';
			
			address_o		<= (others => '0');
			data_o			<= (others => '0');
			alu_operation_o	<= (others => '0');
			alu_sync_select_o <= '0';
			alu_left_h_o	<= (others => '0');
			alu_left_l_o	<= (others => '0');
			alu_right_l_o	<= (others => '0');
			read_select_o	<= DS_MEMORY;
			write_select_o	<= DS_MEMORY;
			read_enable_o	<= '0';
			write_enable_o	<= '0';
			alu_carry_o		<= '0';

			vga_pos_x_o			<= (others => '0'); 
			vga_pos_y_o			<= (others => '0');
			vga_chr_o			<= (others => '0');
			vga_clr_o			<= (others => '0');
			vga_write_enable_o	<= '0';
			
		elsif rising_edge(clk_i) 
		then			
			read_enable_o <= '0';
			write_enable_o <= '0';
			read_select_o	<= DS_MEMORY;
			write_select_o	<= DS_MEMORY;
			vga_write_enable_o <= '0';

			case cpu_state is
				when STOP => 
					cpu_state <= STOP;

				when FETCH_0 =>
					-- alu_operation_o	<= (others => '0');
					-- alu_left_h_o	<= (others => '0');
					-- alu_left_l_o	<= (others => '0');
					-- alu_right_l_o	<= (others => '0');
					-- alu_carry_o		<= '0';
					
					-- set instruction address on the memory bus
					address_o <= program_counter;
					read_enable_o <= '1';
					program_counter <= program_counter + 1;
					
					cpu_state <= FETCH_1;
								
				when FETCH_1 =>
					cpu_state <= DECODE;
					
				when DECODE =>
					instruction_register <= data_i;

					case data_i(15 downto 12) is 
						when OP_ST => 
							cpu_state <= EXECUTE_ST_1;

						when OP_LD => 
							cpu_state <= EXECUTE_LD_1;

						when OP_LDC =>
							cpu_state <= EXECUTE_LD_VAL_1;
						
						when OP_AALU_RR => 
							alu_operation_o <= data_i(12 downto 8);
							alu_sync_select_o <= '0';
							alu_carry_o <= flags.carry_out;
							alu_left_l_o <= regfile(conv_integer(data_i(7 downto 4)));
							alu_right_l_o <= regfile(conv_integer(data_i(3 downto 0)));
							cpu_state <= STORE;

						when OP_AALU_RV => 
							alu_operation_o <= data_i(12 downto 8);
							alu_sync_select_o <= '0';
							alu_carry_o <= flags.carry_out;
							alu_left_l_o <= regfile(conv_integer(data_i(7 downto 4)));
							alu_right_l_o <= "0000" & data_i(3 downto 0);
							cpu_state <= STORE;

						when OP_SALU_RR =>
							alu_operation_o <= data_i(12 downto 8);
							alu_sync_select_o <= '1';
							alu_left_l_o <= regfile(conv_integer(data_i(7 downto 4)));
							alu_left_h_o <= regfile(conv_integer(data_i(7 downto 4) xor "0001"));
							alu_right_l_o <= (others => '0');
							alu_right_l_o <= regfile(conv_integer(data_i(3 downto 0)));
							cpu_state <= WAIT_AND_STORE_SALU_1; -- SALU is not implemented yet
						
						when OP_MOVE_GROUP => 
							case data_i(11 downto 10) is 
								when MOVE_TYPE_RR	=>	cpu_state <= EXECUTE_MOV_RR;
								when MOVE_TYPE_RA	=>	cpu_state <= EXECUTE_MOV_RA_1;
								when MOVE_TYPE_AR	=>	cpu_state <= EXECUTE_MOV_AR_1;
								when others =>			cpu_state <= STOP;
							end case;
						
						when OP_JMP_ABS_GROUP | OP_JMP_REL_GROUP | OP_JMP_R_GROUP => 

							case data_i(13 downto 12) is 
								when JMP_ABS	=>	jump_state := EXECUTE_JMP_ABS;
								when JMP_REL	=>	jump_state := EXECUTE_JMP_REL;
								when JMP_R		=>	jump_state := EXECUTE_JMP_REG;
								when others		=>	jump_state := STOP;
							end case;
							
							jump_cond_match := false;
							
							case data_i(11 downto 8) is 
								when JMP_UNCOND			=> jump_cond_match := true;
								when JMP_POS | JMP_NEG	=> jump_cond_match := flags.negative = data_i(8);
								when JMP_NV	 | JMP_V	=> jump_cond_match := flags.overflow = data_i(8);
								when JMP_NZ	 | JMP_Z	=> jump_cond_match := flags.zero = data_i(8);
								when JMP_NC	 | JMP_C	=> jump_cond_match := flags.carry_out = data_i(8);
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
							case data_i(15 downto 8) is 
								when OP_NOP =>
									cpu_state <= FETCH_0;

								when OP_HLT =>
									cpu_state <= STOP;

								when OP_SEVENSEGTRANSLATE =>
									alu_operation_o <= ALU_SHR;
									alu_sync_select_o <= '0';
									alu_carry_o <= '0';									
									alu_left_l_o <= regfile(conv_integer(data_i(7 downto 4)));
									alu_right_l_o <= "0000" & data_i(3 downto 0);
									cpu_state <= EXECUTE_7SEG_1;
									
									
								when OP_SETXY => 
									cpu_state <= EXECUTE_SET_XY;

								when OP_SETC => 
									cpu_state <= EXECUTE_SET_CHAR;
								
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
					address_o <= "00000000" & instruction_register(7 downto 0);
					data_o <= regfile(conv_integer(instruction_register(11 downto 8)));
					write_enable_o <= '1';
					cpu_state <= FETCH_0;

				when EXECUTE_LD_1  =>  
					address_o <= "00000000" &instruction_register(7 downto 0);
					read_enable_o <= '1';
					cpu_state <= EXECUTE_LD_2;
				when EXECUTE_LD_2 => 
					cpu_state <= EXECUTE_LD_3;
				when EXECUTE_LD_3  =>
					regfile(conv_integer(instruction_register(11 downto 8))) <= data_i;					
					cpu_state <= FETCH_0;

				when EXECUTE_LD_VAL_1  =>  
					regfile(conv_integer(instruction_register(11 downto 8))) <= "00000000" & instruction_register(7 downto 0);
					cpu_state <= FETCH_0;
					
				when EXECUTE_MOV_RR	 =>	 
					regfile(conv_integer(instruction_register(7 downto 4))) <= 
							regfile(conv_integer(instruction_register(3 downto 0)));
					cpu_state <= FETCH_0;
					

				when EXECUTE_MOV_RA_1  =>  
					address_o <= regfile(conv_integer(instruction_register(3 downto 0)));
					read_enable_o	<= '1';
					cpu_state <= EXECUTE_MOV_RA_2;
				when EXECUTE_MOV_RA_2  =>  
					cpu_state <= EXECUTE_MOV_RA_3;
				when EXECUTE_MOV_RA_3 =>  
					regfile(conv_integer(instruction_register(7 downto 4))) <= data_i;
					cpu_state <= FETCH_0;

				when EXECUTE_MOV_AR_1  =>  
					address_o <= regfile(conv_integer(instruction_register(7 downto 4)));					
					data_o <= regfile(conv_integer(instruction_register(3 downto 0)));
					write_enable_o <= '1';
					cpu_state <= FETCH_0;	 -- go to FETCH_0 ?

				when EXECUTE_JMP_ABS  => 
					program_counter <= "00000000" & instruction_register(7 downto 0);
					cpu_state <= FETCH_0;

				when EXECUTE_JMP_REL  => 
					if instruction_register(7) = '0' 
					then 
						program_counter <= program_counter + ("00000000" & instruction_register(7 downto 0));
					else 
						-- keep the sign for the negative offsets 
						program_counter <= program_counter + ("11111111" & instruction_register(7 downto 0));
					end if; 
					cpu_state <= FETCH_0;
				
				when EXECUTE_JMP_REG => 
					program_counter <= 
							regfile(conv_integer(instruction_register(7 downto 4)));
					cpu_state <= FETCH_0; 

				when EXECUTE_PORT_IN_1	=> 
					address_o <= "00000000" & instruction_register(7 downto 0);
					read_enable_o <= '1';
					read_select_o <= DS_PIO;
					cpu_state <= EXECUTE_PORT_IN_2;
				when EXECUTE_PORT_IN_2	=> 
					if pio_io_ready_i = '1' then 
						regfile(conv_integer(instruction_register(11 downto 8))) <= data_i;
						cpu_state <= FETCH_0;
					else 
						read_enable_o <= '1';
						read_select_o <= DS_PIO;
					end if;

				when EXECUTE_PORT_OUT_1	 => 
					address_o <= "00000000" & instruction_register(7 downto 0);
					write_enable_o <= '1';
					write_select_o <= DS_PIO;
					data_o <= regfile(conv_integer(instruction_register(11 downto 8)));
					cpu_state <= EXECUTE_PORT_OUT_2;
				when EXECUTE_PORT_OUT_2 => 
					if pio_io_ready_i = '1' then 
						cpu_state <= FETCH_0;
					else 
						write_enable_o <= '1';
						write_select_o <= DS_PIO;					
					end if;


				when WAIT_AND_STORE_SALU_1 => 
					cpu_state <= WAIT_AND_STORE_SALU_2;
					
				when WAIT_AND_STORE_SALU_2 => 
					if alu_sync_ready_i = '1' 
					then 
						regfile(conv_integer(instruction_register(7 downto 4))) <= alu_result_l_i;
						flags <= alu_flags_i;
						alu_operation_o <= ALU_NOP;
						cpu_state <= WAIT_AND_STORE_SALU_3;
					end if;
					
				when WAIT_AND_STORE_SALU_3 =>
					regfile(conv_integer(instruction_register(7 downto 4) xor "0001" )) <= alu_result_h_i;
					cpu_state <= FETCH_0;

				when STORE	=>	
					regfile(conv_integer(instruction_register(7 downto 4))) <= alu_result_l_i;
					flags <= alu_flags_i;
					-- alu_operation_o <= ALU_NOP;
										
					cpu_state <= FETCH_0;

				when EXECUTE_7SEG_1 => 
					-- alu_operation_o <= ALU_NOP;

					case alu_result_l_i(3 downto 0) is 
						when "0000" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011111100";
						when "0001" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000001100000";
						when "0010" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011011010";
						when "0011" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011110010"; 
						when "0100" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000001100110";
						when "0101" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000010110110";
						when "0110" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000010111110";
						when "0111" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011100000";
						when "1000" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011111110";
						when "1001" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011110110";
						when "1010" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011101110";
						when "1011" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000000111110";
						when "1100" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000010011100";
						when "1101" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000001111010";
						when "1110" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000010011110";
						when "1111" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000010001110";								 
						when others => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000000000010";
					end case;
					cpu_state <= FETCH_0; 


				when EXECUTE_SET_XY => 
					vga_pos_x_o <= regfile(conv_integer(instruction_register(7 downto 4))) (6 downto 0);
					vga_pos_y_o <= regfile(conv_integer(instruction_register(3 downto 0))) (4 downto 0);
					cpu_state <= FETCH_0; 

				when EXECUTE_SET_CHAR => 
					vga_chr_o <=  regfile(conv_integer(instruction_register(7 downto 4))) (7 downto 0);
					vga_clr_o <=  regfile(conv_integer(instruction_register(3 downto 0))) (7 downto 0);
					vga_write_enable_o <= '1';		
					cpu_state <= FETCH_0; 
				
				when EXECUTE_WAIT_1 => 
					wait_counter(24 downto 8) <= not data_i;
					wait_counter(7 downto 0) <= (others => '1');
					cpu_state <= EXECUTE_WAIT_2;
				
				when EXECUTE_WAIT_2 => 
					wait_counter <= wait_counter + 1; -- (0 => '1', others => '0');
					if wait_counter = 0 
					then 
						cpu_state <= FETCH_0;
					end if;

				when others => 
					cpu_state <= STOP;
					error_o <= '1';
			end case;
		end if;
	end process;
end behaviour;
