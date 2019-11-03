library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.opcodes.all;
use work.types.all;

entity ALU is
	generic (
		nbits	: integer := 8
	);
	port
	(
		clk_i				: in std_logic;
		rst_i				: in std_logic; 
		operation_i			: in std_logic_vector(4 downto 0);
		sync_select_i		: in std_logic; -- latched MSB of operation_i
		left_h_i			: in std_logic_vector(nbits-1 downto 0);
		left_l_i			: in std_logic_vector(nbits-1 downto 0);
		right_l_i			: in std_logic_vector(nbits-1 downto 0);
		carry_i				: in std_logic;
		result_h_o			: out std_logic_vector(nbits-1 downto 0);
		result_l_o			: out std_logic_vector(nbits-1 downto 0);
		flags_o				: out ALU_flags;
		sync_ready_o		: out std_logic
	);
end ALU;


architecture behaviour of ALU is	

	constant all_zeroes : std_logic_vector(nbits-1 downto 0) := (others => '0');
	constant one_less_zero : std_logic_vector(nbits-2 downto 0) := (others => '0');
	constant all_ones : std_logic_vector(nbits-1 downto 0) := (others => '1');
	constant one : std_logic_vector(nbits-1 downto 0) := (0 => '1', others => '0');
	constant minus_one : std_logic_vector(nbits-1 downto 0) := (0 => '0', others => '1');
	
	signal async_result_l_o	: std_logic_vector(nbits-1 downto 0);
	signal async_flags_o	: ALU_flags;
							  
	signal sync_result_h_o	: std_logic_vector(nbits-1 downto 0) := (others => '0');
	signal sync_result_l_o	: std_logic_vector(nbits-1 downto 0) := (others => '0');
	signal sync_flags_o		: ALU_flags := (others => '0');


	type sync_alu_state_type is (
		 IDLE,
		 ALU_IMUL_PREPARE, 
		 ALU_IDIV_PREPARE,
		 ALU_MUL_COMPUTE,
		 ALU_DIV_COMPUTE,
		 ALU_MUL_FINISH, 
		 ALU_IMUL_FINISH,
		 ALU_DIV_FINISH, 
		 ALU_IDIV_FINISH
	);
	
	signal sync_alu_state : sync_alu_state_type := IDLE;

	signal acc			: std_logic_vector(2*nbits-1 downto 0);
	signal left_acc			: std_logic_vector(2*nbits-1 downto 0);
	signal right_acc		: std_logic_vector(nbits-1 downto 0);
	signal wide_right_acc		: std_logic_vector(2*nbits-1 downto 0);
	
	signal cnt			: integer range 0 to nbits := 0;
	signal result_sign			: std_logic; -- sign of the result


begin
	-- output multiplexing.. 
	
	with sync_select_i select
		result_h_o <= sync_result_h_o when '1',
					(others => '0') when others;

	with sync_select_i select 
		result_l_o <= sync_result_l_o when '1',
					async_result_l_o when others;
	
	with sync_select_i select 
		flags_o <= sync_flags_o when '1',
					async_flags_o when others;

	sync_ready_o <= '1' when sync_alu_state = IDLE else '0'; 
	
	-- async ALU process 
	process (left_l_i, right_l_i, operation_i, carry_i, sync_select_i)
		variable temp : std_logic_vector(nbits downto 0);
		variable mask : std_logic_vector(nbits-1 downto 0);
		variable right_as_uint: integer;
	begin
		async_flags_o.overflow <= '0';
		async_flags_o.divide_by_zero <= '0'; -- never set by this ALU_ADD

		right_as_uint := to_integer(unsigned(right_l_i));

		case operation_i is
			when ALU_ADD | ALU_ADDC =>
				temp := ('0' & left_l_i) + ('0' & right_l_i);

				if operation_i = ALU_ADDC 
				then 
					temp := temp + (all_zeroes & carry_i);
				end if;
				
				if left_l_i(nbits-1)=right_l_i(nbits-1) then 
					async_flags_o.overflow <= (left_l_i(nbits-1) xor temp(nbits-1));
				else 
					async_flags_o.overflow <= '0';
				end if;
				
			when ALU_SUB | ALU_SUBC | ALU_CMP =>
				temp := ('0'&left_l_i) - ('0'&right_l_i);

				if operation_i = ALU_SUBC 
				then 
					temp := temp - (all_zeroes & carry_i);
				end if;
				
				if left_l_i(nbits-1) /= right_l_i(nbits-1) then 
					async_flags_o.overflow <= (left_l_i(nbits-1) xor temp(nbits-1));
				else
					async_flags_o.overflow <= '0';
				end if;

			when ALU_NEG =>
				temp :=	 carry_i & (all_zeroes - left_l_i);
 
			when ALU_OR =>
				temp := carry_i & (left_l_i or right_l_i);
				
			when ALU_AND | ALU_TEST =>
				temp := carry_i & (left_l_i and right_l_i);

			when ALU_XOR =>
				temp := carry_i & (left_l_i xor right_l_i);
				
			when ALU_NOT =>
				temp := carry_i & (not left_l_i);
			
			when ALU_SHR =>			
				if right_as_uint >= 0 and right_as_uint <= nbits then 
					temp := carry_i & std_logic_vector(shift_right(unsigned(left_l_i), right_as_uint));
				else 
					temp := carry_i & all_zeroes;
				end if;
				
			when ALU_SHAR => 
				-- a bit wordy...
				if left_l_i(nbits-1) = '1' then 
					mask := all_ones;
				else 
					mask := all_zeroes;
				end if;

				if right_as_uint >= 0 and right_as_uint <= nbits then 
					mask := std_logic_vector(shift_left(unsigned(mask), nbits-right_as_uint));
					temp := carry_i & (mask or std_logic_vector(shift_left(unsigned(left_l_i), right_as_uint)));
				else 
					temp := carry_i & all_zeroes;
				end if;
							
			when ALU_SHL => 
				if right_as_uint >= 0 and right_as_uint <= nbits then 
					temp := carry_i & std_logic_vector(shift_left(unsigned(left_l_i), right_as_uint));
				else 
					temp := carry_i & all_zeroes;
				end if;

			when others =>
				temp := '0' & all_zeroes;
		end case;

		if temp(nbits-1 downto 0) = all_zeroes then 
			async_flags_o.zero <= '1';
		else 
			async_flags_o.zero <= '0';
		end if;		
		
		async_flags_o.carry_out <= temp(nbits);
		async_flags_o.negative <= temp(nbits-1);

		if operation_i /= ALU_CMP and operation_i /= ALU_TEST 
		then 
			async_result_l_o <= temp(nbits-1 downto 0);
		else 
			async_result_l_o <= left_l_i; -- unchanged for cmp operation 
		end if;
	end process;
	

	-- sync ALU process 
	process (clk_i, rst_i)
	begin
		
		if rst_i = '1'
		then
			sync_result_h_o	<= (others => '0');
			sync_result_l_o	<= (others => '0');
			sync_flags_o		<= (others => '0');
			sync_alu_state		<= IDLE;
		elsif rising_edge(clk_i)
		then 
			case sync_alu_state is 
				when IDLE =>
					case operation_i is 

						when ALU_MUL | ALU_IMUL =>	
							acc <= (others => '0'); 
							left_acc <= all_zeroes & left_l_i;
							right_acc <= right_l_i;
							cnt <= 0;
							result_sign <= '0';
							
							if operation_i = ALU_IMUL
							then 
								sync_alu_state <= ALU_IMUL_PREPARE;
							else
								sync_alu_state <= ALU_MUL_COMPUTE;
							end if;
							
 						when ALU_DIV | ALU_IDIV =>	 
 							left_acc <= left_h_i & left_l_i;
 							wide_right_acc <= '0' & right_l_i & one_less_zero;
 							acc <= (others => '0');
							cnt <= 0;
							result_sign <= '0';

							if operation_i = ALU_IDIV
							then 
								sync_alu_state <= ALU_IDIV_PREPARE;
							else
								sync_alu_state <= ALU_DIV_COMPUTE;
							end if;

						when others	=> 
								sync_alu_state <= IDLE;
					end case;

				when ALU_IMUL_PREPARE => 
					result_sign <= left_acc(nbits-1) xor right_acc(nbits-1);
					
					if left_acc(nbits-1) = '1' 	-- negative number 
					then 
						left_acc <= all_zeroes & (0 - left_l_i);
					end if;

					if right_acc(nbits-1) = '1' 	-- negative number 
					then 
						right_acc <= 0 - right_acc;
					end if;

					sync_alu_state <= ALU_MUL_COMPUTE;
							
				when ALU_MUL_COMPUTE => 
					if right_acc(0) /= '0' 
					then 
						acc <= acc + left_acc;
					end if;

					left_acc <= left_acc(2*nbits-2 downto 0) & '0';
					right_acc <= '0' & right_acc(nbits-1 downto 1);
					
					if cnt = nbits-1 
					then 
						if result_sign = '1'
						then 
							sync_alu_state <= ALU_IMUL_FINISH;
						else 
							sync_alu_state <= ALU_MUL_FINISH;
						end if;
					end if;
					cnt <= cnt + 1;
								
				when ALU_IMUL_FINISH => 
					acc <= 0 - acc;
					sync_alu_state <= ALU_MUL_FINISH;

				when ALU_MUL_FINISH => 
					sync_flags_o <= (others => '0');
					if acc = (all_zeroes & all_zeroes)
					then 
						sync_flags_o.zero <= '1';
					end if;
					if acc(2*nbits-1 downto nbits) /= all_zeroes
					then 
						sync_flags_o.overflow <= '1';
					end if;
					
					sync_flags_o.negative <= result_sign;

					sync_result_h_o <= acc(2*nbits-1 downto nbits);
					sync_result_l_o <= acc(nbits-1 downto 0);
					sync_alu_state <= IDLE;


				when ALU_IDIV_PREPARE => 
					
					result_sign <= left_h_i(nbits-1) xor right_l_i(nbits-1);

					if left_h_i(nbits-1) = '1'
					then 
						left_acc <= 0 - left_acc; 
					end if;
					
					if right_l_i(nbits-1) = '1'
					then
						wide_right_acc <= '0' & (0 - right_l_i) & one_less_zero;
					end if;

					sync_alu_state <= ALU_DIV_COMPUTE;

 				when ALU_DIV_COMPUTE =>
				
					if left_acc >= wide_right_acc
					then 
						left_acc <= left_acc - wide_right_acc;
						acc <= acc(2*nbits-2 downto 0) & '1';
					else 
						acc <= acc(2*nbits-2 downto 0) & '0';
					end if;

					wide_right_acc <= '0' & wide_right_acc(2*nbits-1 downto 1);


					if cnt = nbits-1
					then 
						if result_sign = '1'
						then 
							sync_alu_state <= ALU_IDIV_FINISH;
						else 
							sync_alu_state <= ALU_DIV_FINISH;
						end if;
					end if;
					cnt <= cnt + 1;

 				when ALU_IDIV_FINISH =>
					acc <= 0 - acc;
					left_acc <= 0 - left_acc; -- note - this is probably incorrect!
 					sync_alu_state <= ALU_DIV_FINISH;
 				
 				when ALU_DIV_FINISH =>
 					sync_flags_o <= (others => '0');
 					if left_acc > wide_right_acc
 					then 
 						sync_flags_o.divide_by_zero <= '1';
 					end if;
					
					sync_flags_o.negative <= result_sign;
 					
 					sync_result_l_o <= acc(nbits-1 downto 0);
 					sync_result_h_o <= left_acc(nbits-1 downto 0);
 					sync_alu_state <= IDLE;
 				
			end case;
		end if;
	
	end process;

end behaviour;
