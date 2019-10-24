library ieee;
use ieee.std_logic_1164.all;
use work.opcodes.all;
use work.types.all;


entity TB_controlunit is
end TB_controlunit;

architecture behavior of TB_controlunit is
    -- Component Declaration for the Unit Under Test (UUT)
	component controlunit is
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
	end component;	
	
	component async_ALU is
		generic (
			bits	: integer := 8
		);
		port
		(
			operation				: in alu_opcode_type;
			regfile_read_port_a		: in std_logic_vector(nbits-1 downto 0);
			regfile_read_port_b		: in std_logic_vector(nbits-1 downto 0);
			direct_arg_port_b		: in std_logic_vector(nbits-1 downto 0);
			b_val_select 			: in ALU_arg_select;
			right_arg				: in std_logic_vector(nbits-1 downto 0);
			carry_in				: in std_logic;
			result					: out std_logic_vector(nbits-1 downto 0);
			flags					: out ALU_flags
		);
	end component;
	
	
	--Inputs into the core
	signal clk			: std_logic;
	signal reset		: std_logic;
	signal error		: std_logic;
	signal address_bus	: std_logic_vector(7 downto 0);
	signal data_in		: std_logic_vector(7 downto 0);
	signal data_out		: std_logic_vector(7 downto 0);
	signal mem_read	: std_logic;
	signal mem_write	: std_logic;
	signal alu_opcode 	: alu_opcode_type;
	signal alu_carry_in		: std_logic;
	signal alu_left		: std_logic_vector(7 downto 0);
	signal alu_right	: std_logic_vector(7 downto 0);
	signal alu_result	: std_logic_vector(7 downto 0);
	signal alu_flags	: ALU_flags;
	signal pio_address 	: std_logic_vector(7 downto 0);
	signal pio_data_w	: std_logic_vector(7 downto 0); -- data entering IO port 
	signal pio_data_r	: std_logic_vector(7 downto 0);
	signal pio_write_enable	: std_logic;
	signal pio_read_enable	: std_logic;
	signal pio_io_ready		: std_logic;

	signal pio_in_port_0		: std_logic_vector (7 downto 0) := (others => '0'); -- dp switches 
	signal pio_in_port_1		: std_logic_vector (7 downto 0) := (others => '0');	-- push btns
	signal pio_in_port_2		: std_logic_vector (7 downto 0) := (others => '0'); -- pin header 6
	signal pio_in_port_3		: std_logic_vector (7 downto 0) := (others => '0'); -- pin header 7
	
	signal pio_out_port_4		: std_logic_vector (7 downto 0); -- individual leds
	signal pio_out_port_5		: std_logic_vector (7 downto 0); -- 7-segment digits 
	signal pio_out_port_6		: std_logic_vector (7 downto 0); -- 7-segment enable signals 
	signal pio_out_port_7		: std_logic_vector (7 downto 0); -- pin header 8
	signal pio_out_port_8		: std_logic_vector (7 downto 0); -- pin header 9


	signal debug_program_counter		: std_logic_vector(7 downto 0);
	signal debug_accumulator	 		: std_logic_vector(7 downto 0);
	signal debug_instruction_code		: std_logic_vector(7 downto 0); 
	signal debug_cpu_state				: cpu_state_type;
	signal debug_clk_counter			: std_logic_vector(31 downto 0);
	signal debug_inst_counter			: std_logic_vector(31 downto 0);


   -- Clock period definitions
   constant clk_period : time := 10 ns; 
begin
 	-- Instantiate the Unit(s) Under Test (UUT)
	c: controlunit port map(
		clk			=> clk,
		reset		=> reset,
		error		=> error,
		address_bus	=> address_bus,
		data_in		=> data_in,
		data_out		=> data_out,
		mem_read		=> mem_read,
		mem_write	=> mem_write,
		alu_opcode 	=> alu_opcode,
		alu_carry_in	=> alu_carry_in,
		alu_left	=> alu_left,
		alu_right	=> alu_right,
		alu_result	=> alu_result,
		alu_flags_in	=> alu_flags,
		pio_address      => pio_address,
		pio_data_w	     => pio_data_w,	    
		pio_data_r	     => pio_data_r,	    
		pio_write_enable => pio_write_enable,
		pio_read_enable	 => pio_read_enable,
		pio_io_ready	 => pio_io_ready, 
		debug_program_counter	 => debug_program_counter,
		debug_accumulator	 	 => debug_accumulator,
		debug_instruction_code	 => debug_instruction_code,
		debug_cpu_state			 => debug_cpu_state,
		debug_clk_counter		 => debug_clk_counter,
		debug_inst_counter		 => debug_inst_counter
	);

	m: memory port map(
		clk => clk,
		address_bus => address_bus,
		data_write => data_out,
		data_read => data_in,
		mem_read => mem_read,
		mem_write => mem_write,
		rst => reset
	);

	a: ALU port map(
		operation => alu_opcode,
		left_arg	 => alu_left,
		right_arg => alu_right,
		carry_in	 => alu_carry_in,
		result	 => alu_result,
		flags		 => alu_flags
	);

	p: pio port map (
			clk => clk,
			clk_unscaled => clk, 
			rst => reset,
			address 	=> pio_address,
			data_w		=> pio_data_w,
			data_r		=> pio_data_r,
			write_enable	=> pio_write_enable, 
			read_enable		=> pio_read_enable,
			io_ready		=> pio_io_ready,
			
			in_port_0		=> pio_in_port_0,
			in_port_1		=> pio_in_port_1,
			in_port_2		=> pio_in_port_2,
			in_port_3		=> pio_in_port_3,

			out_port_4		=> pio_out_port_4,
			out_port_5		=> pio_out_port_5,
			out_port_6		=> pio_out_port_6,
			out_port_7		=> pio_out_port_7,
			out_port_8		=> pio_out_port_8
	);

clock_process: 
	process -- clock generator process 
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

stim_proc: 
   process   -- Stimulus process - main process that drives things 
   begin
		reset <= '1';
		-- hold reset state for 100 ns.
		wait for 200 ns;	
		reset <= '0';
		
		-- anything that is an input - drive to some known state 
		pio_data_r <= "00000000";		
	
		wait for clk_period*40; -- offset our sampling point into the middle of the positive pulse 		
		
		wait;
   end process;

end behavior;
