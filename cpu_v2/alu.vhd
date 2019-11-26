library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.opcodes.all;
use work.types.all;

entity ALU is
	generic (
		nbits	: integer := 16
	);
	port
	(
		clk_i			: in std_logic;
		rst_i			: in std_logic; 
		operation_i		: in std_logic_vector(4 downto 0);
		left_h_i		: in std_logic_vector(nbits-1 downto 0);
		left_l_i		: in std_logic_vector(nbits-1 downto 0);
		right_l_i		: in std_logic_vector(nbits-1 downto 0);
		carry_i			: in std_logic;
		result_h_o		: out std_logic_vector(nbits-1 downto 0);
		result_l_o		: out std_logic_vector(nbits-1 downto 0);
		flags_o			: out ALU_flags;
		ready_o			: out std_logic
	);
end ALU;


architecture behaviour of ALU is	

	constant all_zeroes : std_logic_vector(nbits-1 downto 0) := (others => '0');
	constant one_less_zero : std_logic_vector(nbits-2 downto 0) := (others => '0');
	constant all_ones : std_logic_vector(nbits-1 downto 0) := (others => '1');
	constant one : std_logic_vector(nbits-1 downto 0) := (0 => '1', others => '0');
	constant minus_one : std_logic_vector(nbits-1 downto 0) := (0 => '0', others => '1');
	

	type alu_state_type is (
		IDLE,
		
		ALU_SIMPL_FINISH, -- store result of simmple operations 

		ALU_IMUL_PREPARE, 
		ALU_MUL_COMPUTE_A,
		ALU_MUL_COMPUTE_B,
		ALU_MUL_DONE,
		ALU_MUL_FINISH, 
		ALU_IMUL_FINISH,

		ALU_IDIV_PREPARE,
		ALU_DIV_COMPUTE_A,
		ALU_DIV_COMPUTE_A_GE,
		ALU_DIV_COMPUTE_A_LE,
		ALU_DIV_COMPUTE_B,
		ALU_DIV_DONE,
		ALU_DIV_FINISH, 
		ALU_IDIV_FINISH
	);
	
	signal state 				: alu_state_type := IDLE;

	signal add_sub_acc 			: std_logic_vector(nbits downto 0);
	signal add_update_overflow 	: std_logic;
	signal sub_update_overflow 	: std_logic;

	signal mul_result_acc		: std_logic_vector(2*nbits-1 downto 0);
	signal mul_left_acc			: std_logic_vector(2*nbits-1 downto 0);
	signal mul_right_acc		: std_logic_vector(nbits-1 downto 0);
	
	signal div_result_acc		: std_logic_vector(2*nbits-1 downto 0);
	signal div_left_acc			: std_logic_vector(2*nbits-1 downto 0);
	signal div_right_acc		: std_logic_vector(2*nbits-1 downto 0);

	signal cnt					: integer range 0 to nbits := 0;
	signal result_sign			: std_logic; -- sign of the result

begin
	ready_o <= '1' when state = IDLE and operation_i = ALU_NOP else '0'; 

	process (clk_i, rst_i)
	
		variable right_as_uint: integer;
		variable mask : std_logic_vector(nbits-1 downto 0);
	begin
		if rst_i = '1'
		then
			result_h_o	<= (others => '0');
			result_l_o	<= (others => '0');
			flags_o		<= (others => '0');
			state		<= IDLE;
		elsif rising_edge(clk_i)
		then 
		
			add_update_overflow <= '0';
			sub_update_overflow <= '0';
			
			right_as_uint := to_integer(unsigned(right_l_i));
			
			case state is 
				when IDLE =>
					case operation_i is 

			 			when ALU_ADD | ALU_ADDC =>
			 				if operation_i = ALU_ADDC 
			 				then 
			 					add_sub_acc <= ('0' & left_l_i) + ('0' & right_l_i) + carry_i;
							else 
								add_sub_acc <= ('0' & left_l_i) + ('0' & right_l_i);
			 				end if;
							add_update_overflow <= '1';			 				
							state <= ALU_SIMPL_FINISH;

			 			when ALU_SUB | ALU_SUBC | ALU_CMP =>
			 				if operation_i = ALU_SUBC 
			 				then 
								add_sub_acc <= ('0'&left_l_i) - ('0'&right_l_i) - carry_i;
							else 
								add_sub_acc <= ('0'&left_l_i) - ('0'&right_l_i);
			 				end if;
							sub_update_overflow <= '1';
							state <= ALU_SIMPL_FINISH;

			 			when ALU_NEG =>
			 				add_sub_acc <=	 carry_i & (all_zeroes - left_l_i);
							state <= ALU_SIMPL_FINISH;
							
			 			when ALU_OR =>
			 				add_sub_acc <= carry_i & (left_l_i or right_l_i);
			 				state <= ALU_SIMPL_FINISH;
							
			 			when ALU_AND | ALU_TEST =>
			 				add_sub_acc <= carry_i & (left_l_i and right_l_i);
							state <= ALU_SIMPL_FINISH;
			 
			 			when ALU_XOR =>
			 				add_sub_acc <= carry_i & (left_l_i xor right_l_i);
							state <= ALU_SIMPL_FINISH;
			 				
			 			when ALU_NOT =>
			 				add_sub_acc <= carry_i & (not left_l_i);
							state <= ALU_SIMPL_FINISH;
			 			
			 			when ALU_SHR =>			
			 				if right_as_uint >= 0 and right_as_uint <= nbits then 
			 					add_sub_acc <= carry_i & std_logic_vector(shift_right(unsigned(left_l_i), right_as_uint));
			 				else 
			 					add_sub_acc <= carry_i & all_zeroes;
			 				end if;
							
							state <= ALU_SIMPL_FINISH;
			 				
			 			when ALU_SHAR => 
			 				-- a bit wordy...
			 				if left_l_i(nbits-1) = '1' then 
			 					mask := all_ones;
			 				else 
			 					mask := all_zeroes;
			 				end if;
			 
			 				if right_as_uint >= 0 and right_as_uint <= nbits then 
			 					mask := std_logic_vector(shift_left(unsigned(mask), nbits-right_as_uint));
			 					add_sub_acc <= carry_i & (mask or std_logic_vector(shift_left(unsigned(left_l_i), right_as_uint)));
			 				else 
			 					add_sub_acc <= carry_i & all_zeroes;
			 				end if;
							
							state <= ALU_SIMPL_FINISH;
			 							
			 			when ALU_SHL => 
			 				if right_as_uint >= 0 and right_as_uint <= nbits then 
			 					add_sub_acc <= carry_i & std_logic_vector(shift_left(unsigned(left_l_i), right_as_uint));
			 				else 
			 					add_sub_acc <= carry_i & all_zeroes;
			 				end if;
							
							state <= ALU_SIMPL_FINISH;


						when ALU_MUL | ALU_IMUL =>	
							mul_result_acc <= (others => '0'); 
							mul_left_acc <= all_zeroes & left_l_i;
							mul_right_acc <= right_l_i;
							cnt <= 0;
							result_sign <= '0';
							
							if operation_i = ALU_IMUL
							then 
								state <= ALU_IMUL_PREPARE;
							else
								state <= ALU_MUL_COMPUTE_A;
							end if;
							
 						when ALU_DIV | ALU_IDIV =>	 
 							div_left_acc <= left_h_i & left_l_i;
 							div_right_acc <= '0' & right_l_i & one_less_zero;
 							mul_result_acc <= (others => '0');
							cnt <= 0;
							result_sign <= '0';

							if operation_i = ALU_IDIV
							then 
								state <= ALU_IDIV_PREPARE;
							else
								state <= ALU_DIV_COMPUTE_A;
							end if;

						when others	=> 
							state <= IDLE;
					end case;

				when ALU_SIMPL_FINISH => 
					if add_update_overflow = '1' 
					then 
						if left_l_i(nbits-1) = right_l_i(nbits-1) then 
							flags_o.overflow <= (left_l_i(nbits-1) xor add_sub_acc(nbits-1));
						else 
							flags_o.overflow <= '0';
						end if;
					end if;

					if sub_update_overflow = '1'
					then 
						if left_l_i(nbits-1) /= right_l_i(nbits-1) then 
							flags_o.overflow <= (left_l_i(nbits-1) xor add_sub_acc(nbits-1));
						else
							flags_o.overflow <= '0';
						end if;
					end if;
				
				
					if add_sub_acc(nbits-1 downto 0) = all_zeroes then 
						flags_o.zero <= '1';
					else 
						flags_o.zero <= '0';
					end if;		
					
					flags_o.carry_out <= add_sub_acc(nbits);
					flags_o.negative <= add_sub_acc(nbits-1);

					if operation_i /= ALU_CMP and operation_i /= ALU_TEST 
					then 
						result_l_o <= add_sub_acc(nbits-1 downto 0);
					else 
						result_l_o <= left_l_i; -- unchanged for cmp operation 
					end if;
					
					state <= IDLE;


 				when ALU_IMUL_PREPARE => 
  					result_sign <= mul_left_acc(nbits-1) xor mul_right_acc(nbits-1);
  					
  					if mul_left_acc(nbits-1) = '1' 	-- negative number 
  					then 
  						mul_left_acc <= all_zeroes & (0 - left_l_i);
  					end if;
  
  					if mul_right_acc(nbits-1) = '1' 	-- negative number 
  					then 
  						mul_right_acc <= 0 - mul_right_acc;
  					end if;
 
 					state <= ALU_MUL_COMPUTE_A;
 							
 				when ALU_MUL_COMPUTE_A => 

 					if mul_right_acc(0) /= '0' 
 					then 
 						mul_result_acc <= mul_result_acc + mul_left_acc;
 					end if;
 
					state <= ALU_MUL_COMPUTE_B;
	
					
 				when ALU_MUL_COMPUTE_B =>
 					mul_left_acc <= mul_left_acc(2*nbits-2 downto 0) & '0';
 					mul_right_acc <= '0' & mul_right_acc(nbits-1 downto 1);
 
 					if cnt = nbits-1 
 					then 
						state <= ALU_MUL_DONE;
					else 
						state <= ALU_MUL_COMPUTE_A;
 					end if;

 					cnt <= cnt + 1;
					
				when ALU_MUL_DONE => 
					if result_sign = '1'
					then 
						state <= ALU_IMUL_FINISH;
					else 
						state <= ALU_MUL_FINISH;
					end if;
 				
 				when ALU_IMUL_FINISH => 
 					mul_result_acc <= 0 - mul_result_acc;
 					state <= ALU_MUL_FINISH;
 
 				when ALU_MUL_FINISH => 
 					flags_o <= (others => '0');
 					if mul_result_acc = (all_zeroes & all_zeroes)
 					then 
 						flags_o.zero <= '1';
 					end if;
 					if mul_result_acc(2*nbits-1 downto nbits) /= all_zeroes
 					then 
 						flags_o.overflow <= '1';
 					end if;
 					
 					flags_o.negative <= result_sign;
 
 					result_h_o <= mul_result_acc(2*nbits-1 downto nbits);
 					result_l_o <= mul_result_acc(nbits-1 downto 0);
 					state <= IDLE;
 
 
 				when ALU_IDIV_PREPARE => 
 					
 					result_sign <= left_h_i(nbits-1) xor right_l_i(nbits-1);
 
 					if left_h_i(nbits-1) = '1'
 					then 
 						div_left_acc <= 0 - div_left_acc; 
 					end if;
 					
 					if right_l_i(nbits-1) = '1'
 					then
 						div_right_acc <= '0' & (0 - right_l_i) & one_less_zero;
 					end if;
 
 					state <= ALU_DIV_COMPUTE_A;
 
  				when ALU_DIV_COMPUTE_A =>
 				
 					if div_left_acc >= div_right_acc
 					then 
						state <= ALU_DIV_COMPUTE_A_GE;
 					else 
						state <= ALU_DIV_COMPUTE_A_LE;
 					end if;

  				when ALU_DIV_COMPUTE_A_GE =>
					div_left_acc <= div_left_acc - div_right_acc;
					div_result_acc <= div_result_acc(2*nbits-2 downto 0) & '1';
					state <= ALU_DIV_COMPUTE_B;

  				when ALU_DIV_COMPUTE_A_LE =>
					div_result_acc <= div_result_acc(2*nbits-2 downto 0) & '0';
					state <= ALU_DIV_COMPUTE_B;
 
  				when ALU_DIV_COMPUTE_B =>
 					div_right_acc <= '0' & div_right_acc(2*nbits-1 downto 1);
  
 					if cnt = nbits-1
 					then 
						state <= ALU_DIV_DONE;
					else 
						state <= ALU_DIV_COMPUTE_A;
 					end if;
 					cnt <= cnt + 1;

				when ALU_DIV_DONE => 
					if result_sign = '1'
					then 
						state <= ALU_IDIV_FINISH;
					else 
						state <= ALU_DIV_FINISH;
					end if;
 
  				when ALU_IDIV_FINISH =>
 					div_result_acc <= 0 - div_result_acc;
 					div_left_acc <= 0 - div_left_acc; -- note - this is probably incorrect!
  					state <= ALU_DIV_FINISH;
  				
  				when ALU_DIV_FINISH =>
  					flags_o <= (others => '0');
  					if div_left_acc > div_right_acc
  					then 
  						flags_o.divide_by_zero <= '1';
  					end if;
 					
 					flags_o.negative <= result_sign;
  					
  					result_l_o <= div_result_acc(nbits-1 downto 0);
  					result_h_o <= div_left_acc(nbits-1 downto 0);
  					state <= IDLE;
 				
			end case;
		end if;
	
	end process;

end behaviour;
