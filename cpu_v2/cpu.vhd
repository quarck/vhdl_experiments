library ieee ;
use ieee.std_logic_1164.all;
use work.opcodes.all;
use work.types.all;

entity cpu is
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

		-- direct access to the video adapter 
		-- todo - remove this later in favour of using I/O ports 
		-- (even if we use dedicated opcodes for VGA, we can just use particular 
		-- port numbers for these 
		vga_pos_x_o				: out std_logic_vector(6 downto 0); -- 0-79 - enough 7 bits 
		vga_pos_y_o				: out std_logic_vector(4 downto 0); -- 0-29 - enough 5 bits
		vga_chr_o				: out std_logic_vector(7 downto 0); 
		vga_clr_o				: out std_logic_vector(7 downto 0); 
		vga_write_enable_o		: out std_logic
	);
end cpu;

architecture structural of cpu is 

	component controlunit is
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
	end component;	
	
	component ALU is
		generic (
			nbits	: integer := 16
		);
		port
		(
			clk_i				: in std_logic;
			rst_i				: in std_logic; 
			operation_i			: in std_logic_vector(4 downto 0);
			sync_select_i	: in std_logic; -- latched MSB of operation_i
			left_h_i			: in std_logic_vector(nbits-1 downto 0);
			left_l_i			: in std_logic_vector(nbits-1 downto 0);
			right_l_i			: in std_logic_vector(nbits-1 downto 0);
			carry_i				: in std_logic;
			result_h_o			: out std_logic_vector(nbits-1 downto 0);
			result_l_o			: out std_logic_vector(nbits-1 downto 0);
			flags_o				: out ALU_flags;
			sync_ready_o		: out std_logic
		);
	end component;

	signal alu_operation		: std_logic_vector(4 downto 0);
	signal alu_sync_select	: std_logic;
	signal alu_left_h			: std_logic_vector(15 downto 0);
	signal alu_left_l			: std_logic_vector(15 downto 0);
	signal alu_right_l			: std_logic_vector(15 downto 0);
	signal alu_carry			: std_logic;
	signal alu_result_h			: std_logic_vector(15 downto 0);
	signal alu_result_l			: std_logic_vector(15 downto 0);
	signal alu_flags			: ALU_flags;
	signal alu_sync_ready		: std_logic;

	
begin
	c: controlunit port map(
		clk_i					=> clk_i,
		reset_i					=> reset_i,
		error_o					=> error_o,
		
		-- address bus - multiplexed between memory and PIO 
		address_o				=> address_o,
		
		-- data buses - multiplexed between port and memory 
		data_i					=> data_i,
		data_o					=> data_o,

		-- read/write controls for both memory and PIO
		read_enable_o			=> read_enable_o,
		read_select_o			=> read_select_o,
		write_enable_o			=> write_enable_o,
		write_select_o			=> write_select_o,

		pio_io_ready_i			=> pio_io_ready_i,

		alu_operation_o			=> alu_operation,
		alu_sync_select_o		=> alu_sync_select,
		alu_left_h_o			=> alu_left_h,
		alu_left_l_o			=> alu_left_l,
		alu_right_l_o			=> alu_right_l,
		alu_carry_o				=> alu_carry,
		alu_result_h_i			=> alu_result_h,
		alu_result_l_i			=> alu_result_l,
		alu_flags_i				=> alu_flags,
		alu_sync_ready_i		=> alu_sync_ready,

		vga_pos_x_o				=> vga_pos_x_o,
		vga_pos_y_o				=> vga_pos_y_o,
		vga_chr_o				=> vga_chr_o,
		vga_clr_o				=> vga_clr_o,
		vga_write_enable_o		=> vga_write_enable_o, 
		
		dbg_state_o				=> open,
		dbg_pc_o				=> open,
		dbg_f_o					=> open,
		dbg_ir_o				=> open
	);
	
	a: ALU port map (
		clk_i				=> clk_i,
		rst_i				=> reset_i,
		operation_i			=> alu_operation,
		sync_select_i		=> alu_sync_select,
		left_h_i			=> alu_left_h,
		left_l_i			=> alu_left_l,
		right_l_i			=> alu_right_l,
		carry_i				=> alu_carry,
		result_h_o			=> alu_result_h,
		result_l_o			=> alu_result_l,
		flags_o				=> alu_flags,
		sync_ready_o		=> alu_sync_ready
	);
		
end structural;
