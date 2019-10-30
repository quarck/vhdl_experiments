library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.opcodes.all;
use work.types.all;

entity sync_ALU is
	generic (
		nbits	: integer := 8
	);
	port
	(
		clk_i					: std_logic;
		operation_i				: in std_logic_vector(3 downto 0);
		left_arg_high_i			: in std_logic_vector(nbits-1 downto 0);
		left_arg_low_i			: in std_logic_vector(nbits-1 downto 0);
		right_arg_i				: in std_logic_vector(nbits-1 downto 0);
		result_high_o			: out std_logic_vector(nbits-1 downto 0);
		result_low_o			: out std_logic_vector(nbits-1 downto 0);
		flags_o					: out ALU_flags;
		alu_start_i				: in std_logic;
		alu_ready_o				: out std_logic
	);
end sync_ALU;


architecture behaviour of sync_ALU is	
	constant all_zeroes : std_logic_vector(nbits-1 downto 0) := (others => '0');
	constant one_less_dgt_all_zeroes : std_logic_vector(nbits-2 downto 0) := (others => '0');
	constant all_ones : std_logic_vector(nbits-1 downto 0) := (others => '1');
	constant one : std_logic_vector(nbits-1 downto 0) := (0 => '1', others => '0');
	constant minus_one : std_logic_vector(nbits-1 downto 0) := (0 => '0', others => '1');

	type sync_alu_state is (
		IDLE,
		ALU_MUL_START, 
		ALU_MUL_FINISH, 
		ALU_IMUL_START,
		ALU_IMUL_FINISH, 

		ALU_MUL_COMPUTE_1,
		ALU_MUL_COMPUTE_2,
		
		ALU_DIV_START, 
		ALU_DIV_FINISH, 
		ALU_IDIV_START,
		ALU_IDIV_FINISH,

		ALU_DIV_COMPUTE_1,
		ALU_DIV_COMPUTE_2,
		ALU_DIV_COMPUTE_3,
		ALU_DIV_COMPUTE_4
	);
	
	signal state : sync_alu_state := IDLE;

begin

	alu_ready_o <= '1' when state = IDLE else '0'; 
					
	process (clk_i)
		variable m_mask			: std_logic_vector(2*nbits-1 downto 0);
		variable m_acc			: std_logic_vector(2*nbits-1 downto 0);
		variable m_left			: std_logic_vector(2*nbits-1 downto 0);
		variable m_right		: std_logic_vector(nbits-1 downto 0);
		variable m_wright		: std_logic_vector(2*nbits-1 downto 0);
		
		variable im_l_sgn		: std_logic;
		variable im_r_sgn		: std_logic;		
	begin
	
		if rising_edge(clk_i)
		then 
			case state is 
				when IDLE => 
					if alu_start_i = '1' then 
						case operation_i is 
							when ALU_MUL =>	 state <= ALU_MUL_START;
							when ALU_IMUL => state <= ALU_IMUL_START;
							when ALU_DIV =>	 state <= ALU_DIV_START;
							when ALU_IDIV => state <= ALU_IDIV_START;
							when others		=> state <= IDLE;
						end case;
					end if;

				when ALU_MUL_START => 
					m_acc := all_zeroes & all_zeroes; 
					m_left := all_zeroes & left_arg_low_i;
					m_right := right_arg_i;
					state <= ALU_MUL_COMPUTE_1;

				when ALU_IMUL_START => 
					m_acc := all_zeroes & all_zeroes; 
					
					im_l_sgn := left_arg_low_i(nbits-1);
					im_r_sgn := right_arg_i(nbits-1);
					
					if im_l_sgn = '1' 
					then 
						-- negative number 
						m_left := not (all_ones & left_arg_low_i) + 1;
					else 
						m_left := all_zeroes & left_arg_low_i;
					end if;

					if im_r_sgn = '1' 
					then 
						-- negative number 
						m_right := not right_arg_i + 1;
					else 
						m_right := right_arg_i;
					end if;
					state <= ALU_MUL_COMPUTE_1;
				
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
					
					state <= ALU_MUL_COMPUTE_2;

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
						state <= ALU_MUL_FINISH;
					else 
						state <= ALU_IMUL_FINISH;
					end if;
				
				when ALU_MUL_FINISH => 
					flags_o <= (others => '0');
					if m_acc = (all_zeroes & all_zeroes)
					then 
						flags_o.zero <= '1';
					end if;
					if m_acc(2*nbits-1 downto nbits) /= all_zeroes
					then 
						flags_o.overflow <= '1';
					end if;

					result_high_o <= m_acc(2*nbits-1 downto nbits);
					result_low_o <= m_acc(nbits-1 downto 0);
					state <= IDLE;
					
				when ALU_IMUL_FINISH => 
					flags_o <= (others => '0');
					if m_acc = (all_zeroes & all_zeroes)
					then 
						flags_o.zero <= '1';
					end if;
					if m_acc(2*nbits-1 downto nbits) /= all_zeroes
					then 
						flags_o.overflow <= '1';
					end if;

					if (im_l_sgn xor im_r_sgn) = '1' 
					then 
						m_acc := not m_acc + 1;
					end if;

					result_high_o <= m_acc(2*nbits-1 downto nbits);
					result_low_o <= m_acc(nbits-1 downto 0);
					state <= IDLE;

				when ALU_DIV_START => 
					m_left := left_arg_high_i & left_arg_low_i;
					m_wright := right_arg_i & all_zeroes;
					m_acc := all_zeroes & all_zeroes;
					state <= ALU_DIV_COMPUTE_1;
				
				when ALU_IDIV_START => 
					im_l_sgn := left_arg_high_i(nbits-1);
					im_r_sgn := right_arg_i(nbits-1);

					if im_l_sgn = '1'
					then 
						m_left := not (left_arg_high_i & left_arg_low_i) + 1;
					else
						m_left := left_arg_high_i & left_arg_low_i;
					end if;
					
					if im_r_sgn = '1'
					then
						m_wright := (not right_arg_i + 1) & all_zeroes;
					else
						m_wright := right_arg_i & all_zeroes;
					end if;
					
					m_acc := all_zeroes & all_zeroes;
					state <= ALU_DIV_COMPUTE_1;

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
					state <= ALU_DIV_COMPUTE_2;
					
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
					state <= ALU_DIV_COMPUTE_3;
					
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
					state <= ALU_DIV_COMPUTE_4;
					
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
						state <= ALU_DIV_FINISH;
					else 
						state <= ALU_IDIV_FINISH;
					end if;				
				
				when ALU_DIV_FINISH =>
					flags_o <= (others => '0');
					if m_left > m_wright
					then 
						flags_o.divide_by_zero <= '1';
					end if;
					
					result_low_o <= m_acc(nbits-1 downto 0);
					result_high_o <= m_left(nbits-1 downto 0);
					state <= IDLE;
				
				when ALU_IDIV_FINISH =>
					flags_o <= (others => '0');
					if m_left > m_wright
					then 
						flags_o.divide_by_zero <= '1';
					end if;
					
					if (im_l_sgn xor im_r_sgn) = '1' 
					then 
						result_low_o <= not m_acc(nbits-1 downto 0) + 1;
						result_high_o <= m_left(nbits-1 downto 0); -- note - this is probably incorrect!
					else
						result_low_o <= m_acc(nbits-1 downto 0);
						result_high_o <= m_left(nbits-1 downto 0);
					end if;
					state <= IDLE;

			end case;
		end if;
	
	end process;
	
end behaviour;
