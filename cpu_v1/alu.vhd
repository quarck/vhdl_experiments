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

		 ALU_MUL_COMPUTE_1,
		 ALU_MUL_COMPUTE_2,

		 ALU_DIV_COMPUTE_1,
		 ALU_DIV_COMPUTE_2,
		 ALU_DIV_COMPUTE_3,
		 ALU_DIV_COMPUTE_4,

		 ALU_MUL_FINISH, 
		 ALU_IMUL_FINISH,
		 ALU_DIV_FINISH, 
		 ALU_IDIV_FINISH
	);
	
	signal sync_alu_state : sync_alu_state_type := IDLE;

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
		variable m_mask			: std_logic_vector(2*nbits-1 downto 0);
		variable m_acc			: std_logic_vector(2*nbits-1 downto 0);
		variable m_left			: std_logic_vector(2*nbits-1 downto 0);
		variable m_right		: std_logic_vector(nbits-1 downto 0);
		variable m_wright		: std_logic_vector(2*nbits-1 downto 0);
		
		variable im_l_sgn		: std_logic;
		variable im_r_sgn		: std_logic;		
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
						when ALU_MUL =>	
							m_acc := all_zeroes & all_zeroes; 
							m_left := all_zeroes & left_l_i;
							m_right := right_l_i;
							sync_alu_state <= ALU_MUL_COMPUTE_1;
							
						when ALU_IMUL => 
							m_acc := all_zeroes & all_zeroes; 
							
							im_l_sgn := left_l_i(nbits-1);
							im_r_sgn := right_l_i(nbits-1);
							
							if im_l_sgn = '1' 	-- negative number 
							then 
								m_left := not (all_ones & left_l_i) + 1;
							else 
								m_left := all_zeroes & left_l_i;
							end if;

							if im_r_sgn = '1' 	-- negative number 
							then 
								m_right := not right_l_i + 1;
							else 
								m_right := right_l_i;
							end if;
							sync_alu_state <= ALU_MUL_COMPUTE_1;
							
 						when ALU_DIV =>	 
 							m_left := left_h_i & left_l_i;
 							m_wright := right_l_i & all_zeroes;
 							m_acc := all_zeroes & all_zeroes;
 							sync_alu_state <= ALU_DIV_COMPUTE_1;
 							
 						when ALU_IDIV => 
 							im_l_sgn := left_h_i(nbits-1);
 							im_r_sgn := right_l_i(nbits-1);
 
 							if im_l_sgn = '1'
 							then 
 								m_left := not (left_h_i & left_l_i) + 1;
 							else
 								m_left := left_h_i & left_l_i;
 							end if;
 							
 							if im_r_sgn = '1'
 							then
 								m_wright := (not right_l_i + 1) & all_zeroes;
 							else
 								m_wright := right_l_i & all_zeroes;
 							end if;
 							
 							m_acc := all_zeroes & all_zeroes;
 							sync_alu_state <= ALU_DIV_COMPUTE_1;
							
						when others	=> 
								sync_alu_state <= IDLE;
					end case;

				when ALU_MUL_COMPUTE_1 => 
					
					for i in 0 to nbits/2-1 
					loop 
						if m_right(i) /= '0' 
						then 
							m_mask := all_ones & all_ones;
						else 
							m_mask := all_zeroes & all_zeroes;
						end if;

						m_acc := m_acc + (m_left and m_mask);
						m_left := m_left(2*nbits-2 downto 0) & '0';
					end loop;
					
					sync_alu_state <= ALU_MUL_COMPUTE_2;

				when ALU_MUL_COMPUTE_2 => 
					
					for i in nbits/2 to nbits-1 
					loop 
						if m_right(i) /= '0' 
						then 
							m_mask := all_ones & all_ones;
						else 
							m_mask := all_zeroes & all_zeroes;
						end if;

						m_acc := m_acc + (m_left and m_mask);
						m_left := m_left(2*nbits-2 downto 0) & '0';
					end loop;
					
					if im_l_sgn = '0' and im_r_sgn = '0' then 
						sync_alu_state <= ALU_MUL_FINISH;
					else 
						sync_alu_state <= ALU_IMUL_FINISH;
					end if;
				
				when ALU_MUL_FINISH => 
					sync_flags_o <= (others => '0');
					if m_acc = (all_zeroes & all_zeroes)
					then 
						sync_flags_o.zero <= '1';
					end if;
					if m_acc(2*nbits-1 downto nbits) /= all_zeroes
					then 
						sync_flags_o.overflow <= '1';
					end if;

					sync_result_h_o <= m_acc(2*nbits-1 downto nbits);
					sync_result_l_o <= m_acc(nbits-1 downto 0);
					sync_alu_state <= IDLE;
					
				when ALU_IMUL_FINISH => 
					sync_flags_o <= (others => '0');
					if m_acc = (all_zeroes & all_zeroes)
					then 
						sync_flags_o.zero <= '1';
					end if;
					if m_acc(2*nbits-1 downto nbits) /= all_zeroes
					then 
						sync_flags_o.overflow <= '1';
					end if;

					if (im_l_sgn xor im_r_sgn) = '1' 
					then 
						m_acc := not m_acc + 1;
					end if;

					sync_result_h_o <= m_acc(2*nbits-1 downto nbits);
					sync_result_l_o <= m_acc(nbits-1 downto 0);
					sync_alu_state <= IDLE;

 				when ALU_DIV_COMPUTE_1 =>
 					for i in nbits-1 downto nbits*3/4
 					loop 
  						m_wright := '0' & m_wright(2*nbits-1 downto 1);
 						if m_left >= m_wright 
 						then 
  							m_left := m_left - m_wright;
 							m_acc(i) := '1';
 						end if;
  					end loop;
 					sync_alu_state <= ALU_DIV_COMPUTE_2;
 					
 				when ALU_DIV_COMPUTE_2 =>
 					for i in nbits*3/4-1 downto nbits*2/4
 					loop 
  						m_wright := '0' & m_wright(2*nbits-1 downto 1);
 						if m_left >= m_wright 
 						then 
  							m_left := m_left - m_wright;
 							m_acc(i) := '1';
 						end if;
  					end loop;
 					sync_alu_state <= ALU_DIV_COMPUTE_3;
 					
 				when ALU_DIV_COMPUTE_3 =>
 					for i in nbits*2/4-1 downto nbits*1/4
 					loop 
  						m_wright := '0' & m_wright(2*nbits-1 downto 1);
 						if m_left >= m_wright 
 						then 
  							m_left := m_left - m_wright;
 							m_acc(i) := '1';
 						end if;
  					end loop;
 					sync_alu_state <= ALU_DIV_COMPUTE_4;
 					
 				when ALU_DIV_COMPUTE_4 =>
 					for i in nbits*1/4-1 downto 0
 					loop 
  						m_wright := '0' & m_wright(2*nbits-1 downto 1);
 						if m_left >= m_wright 
 						then 
  							m_left := m_left - m_wright;
 							m_acc(i) := '1';
 						end if;
  					end loop;
 					
 					if im_l_sgn = '0' and im_r_sgn = '0' then 
 						sync_alu_state <= ALU_DIV_FINISH;
 					else 
 						sync_alu_state <= ALU_IDIV_FINISH;
 					end if;				
 				
 				when ALU_DIV_FINISH =>
 					sync_flags_o <= (others => '0');
 					if m_left > m_wright
 					then 
 						sync_flags_o.divide_by_zero <= '1';
 					end if;
 					
 					sync_result_l_o <= m_acc(nbits-1 downto 0);
 					sync_result_h_o <= m_left(nbits-1 downto 0);
 					sync_alu_state <= IDLE;
 				
 				when ALU_IDIV_FINISH =>
 					sync_flags_o <= (others => '0');
 					if m_left > m_wright
 					then 
 						sync_flags_o.divide_by_zero <= '1';
 					end if;
 					
 					if (im_l_sgn xor im_r_sgn) = '1' 
 					then 
 						sync_result_l_o <= not m_acc(nbits-1 downto 0) + 1;
 						sync_result_h_o <= not m_left(nbits-1 downto 0) + 1; -- note - this is probably incorrect!
 					else
 						sync_result_l_o <= m_acc(nbits-1 downto 0);
 						sync_result_h_o <= m_left(nbits-1 downto 0);
 					end if;
 					sync_alu_state <= IDLE;

			end case;
		end if;
	
	end process;

end behaviour;
