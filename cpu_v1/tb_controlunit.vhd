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
			clk				: in std_logic;
			reset			: in std_logic;
			error			: out std_logic;
			
			address_bus		: out std_logic_vector(7 downto 0);
			data_in			: in std_logic_vector(7 downto 0);
			data_out		: out std_logic_vector(7 downto 0);
			mem_read		: out std_logic;
			mem_write		: out std_logic;

			alu_opcode 		: out alu_opcode_type;
			alu_carry_in	: out std_logic;		
			alu_left		: out std_logic_vector(7 downto 0);
			alu_right		: out std_logic_vector(7 downto 0);
			alu_result		: in std_logic_vector(7 downto 0);
			alu_flags_in		: in ALU_flags;
			
			pio_address 	: out std_logic_vector(7 downto 0);
			pio_data_w		: out std_logic_vector(7 downto 0); -- data entering IO port 
			pio_data_r		: in std_logic_vector(7 downto 0);
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
	
	component memory
		port(
         clk : in  std_logic;
         address_bus : in  std_logic_vector(7 downto 0);
         data_write : in  std_logic_vector(7 downto 0);
         data_read : out  std_logic_vector(7 downto 0);
		 mem_read : in std_logic;
         mem_write : in  std_logic;
         rst : in  std_logic
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
	
	component pio is 
		port (
			clk				: in std_logic;
			clk_unscaled	: in std_logic;
			rst 			: in std_logic;
			address 	: in std_logic_vector(7 downto 0);
			data_w		: in std_logic_vector(7 downto 0); -- data entering IO port 
			data_r		: out std_logic_vector(7 downto 0);
			write_enable	: in std_logic;
			read_enable		: in std_logic;
			io_ready		: out std_logic;
			
			in_port_0		: in std_logic_vector (7 downto 0); -- dp switches 
			in_port_1		: in std_logic_vector (7 downto 0);	-- push btns
			in_port_2		: in std_logic_vector (7 downto 0); -- pin header 6
			in_port_3		: in std_logic_vector (7 downto 0); -- pin header 7

			out_port_4			: out std_logic_vector (7 downto 0); -- individual leds
			out_port_5			: out std_logic_vector (7 downto 0); -- 7-segment digits 
			out_port_6			: out std_logic_vector (7 downto 0); -- 7-segment enable signals 
			out_port_7			: out std_logic_vector (7 downto 0); -- pin header 8
			out_port_8			: out std_logic_vector (7 downto 0) -- pin header 9
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
