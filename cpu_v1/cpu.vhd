library ieee ;
use ieee.std_logic_1164.all;
use work.opcodes.all;
use work.types.all;

entity cpu is
	port
	(
		clk					: in std_logic;
		reset				: in std_logic;
		error				: out std_logic;
	
		mem_address			: out std_logic_vector(7 downto 0);
		mem_data_r			: in std_logic_vector(7 downto 0);
		mem_data_w			: out std_logic_vector(7 downto 0);
		mem_read			: out std_logic;
		mem_write			: out std_logic;

	
		pio_address 		: out std_logic_vector(7 downto 0);
		pio_data_w			: out std_logic_vector(7 downto 0); -- data entering IO port 
		pio_data_r			: in std_logic_vector(7 downto 0);
		pio_write_enable	: out std_logic;
		pio_read_enable		: out std_logic;
		pio_io_ready		: in std_logic
	);
end cpu;

architecture structural of cpu is 

	component core is
		port
		(
			clk					: in std_logic;
			reset				: in std_logic;
			error				: out std_logic;
				
			address_bus			: out std_logic_vector(7 downto 0);
			data_in				: in std_logic_vector(7 downto 0);
			data_out			: out std_logic_vector(7 downto 0);
			mem_read			: out std_logic;
			mem_write			: out std_logic;
	
			alu_opcode 			: out alu_opcode_type;
			alu_carry_in		: out std_logic;		
			alu_left			: out std_logic_vector(7 downto 0);
			alu_right			: out std_logic_vector(7 downto 0);
			alu_result			: in std_logic_vector(7 downto 0);
			alu_flags_in		: in ALU_flags;
				
			pio_address 		: out std_logic_vector(7 downto 0);
			pio_data_w			: out std_logic_vector(7 downto 0); -- data entering IO port 
			pio_data_r			: in std_logic_vector(7 downto 0);
			pio_write_enable	: out std_logic;
			pio_read_enable		: out std_logic;
			pio_io_ready		: in std_logic;

			debug_program_counter		: out std_logic_vector(7 downto 0);
			debug_accumulator	 		: out std_logic_vector(7 downto 0);
			debug_instruction_code		: out std_logic_vector(7 downto 0); 
			debug_cpu_state				: out cpu_state_type;

			debug_clk_counter			: out std_logic_vector(31 downto 0);
			debug_inst_counter			: out std_logic_vector(31 downto 0)			
		);
	end component;	
	
	component ALU is
		port
		(
			operation			: in alu_opcode_type;
			left_arg			: in std_logic_vector(7 downto 0);
			right_arg			: in std_logic_vector(7 downto 0);
			carry_in			: in std_logic;
			result				: out std_logic_vector(7 downto 0);
			flags				: out ALU_flags
		);
	end component;

	signal alu_opcode 		: alu_opcode_type;
	signal alu_carry_in		: std_logic;		
	signal alu_left			: std_logic_vector(7 downto 0);
	signal alu_right		: std_logic_vector(7 downto 0);
	signal alu_result		: std_logic_vector(7 downto 0);
	signal alu_flags		: ALU_flags;

begin
	c: core port map(
			clk					=> clk,
			reset				=> reset,
			error				=> error,
			
			address_bus			=> mem_address,
			data_in				=> mem_data_r,
			data_out			=> mem_data_w,
			mem_read			=> mem_read,
			mem_write			=> mem_write,

			alu_opcode 			=> alu_opcode,
			alu_carry_in		=> alu_carry_in,
			alu_left			=> alu_left,
			alu_right			=> alu_right,
			alu_result			=> alu_result,
			alu_flags_in		=> alu_flags,

			pio_address 		=> pio_address,
			pio_data_w			=> pio_data_w, 
			pio_data_r			=> pio_data_r,
			pio_write_enable	=> pio_write_enable,
			pio_read_enable		=> pio_read_enable,
			pio_io_ready		=> pio_io_ready,
			
			debug_program_counter	=> open, -- these
			debug_accumulator	 	=> open, -- ports
			debug_instruction_code	=> open, -- are 
			debug_cpu_state			=> open, -- only 
			debug_clk_counter		=> open, -- for 
			debug_inst_counter		=> open  -- simulation			
	);
	
	a: ALU port map (
		operation			=> alu_opcode,
		left_arg			=> alu_left,
		right_arg			=> alu_right,
		carry_in			=> alu_carry_in,
		result				=> alu_result,
		flags				=> alu_flags
	);
	
end structural;
