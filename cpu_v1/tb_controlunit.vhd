library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

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
	end component;	
	
	component async_ALU is
		generic (
			nbits	: integer := 8
		);
		port
		(
			operation_i				: in std_logic_vector(3 downto 0);
			left_arg_i				: in std_logic_vector(nbits-1 downto 0);
			right_arg_i				: in std_logic_vector(nbits-1 downto 0);
			carry_i					: in std_logic;
			result_o				: out std_logic_vector(nbits-1 downto 0);
			flags_o					: out ALU_flags
		);
	end component;
	
	 component pio is 
		 port (
			  clk_i			  : in std_logic;
			  rst_i			  : in std_logic;
			  
			  port_address_i  : in std_logic_vector(7 downto 0);
			  data_i		  : in std_logic_vector(7 downto 0); -- data entering IO port 
			  data_o		  : out std_logic_vector(7 downto 0);
			  write_enable_i  : in std_logic;
			  read_enable_i	  : in std_logic;
			  io_ready_o	  : out std_logic;
			  
			  gpio_0_i		  : in std_logic_vector (7 downto 0); -- dp switches 
			  gpio_1_i		  : in std_logic_vector (7 downto 0); -- push btns
			  gpio_2_i		  : in std_logic_vector (7 downto 0); -- pin header 6
			  gpio_3_i		  : in std_logic_vector (7 downto 0); -- pin header 7
									
			  gpio_4_o		  : out std_logic_vector (7 downto 0); -- individual leds
			  gpio_5_o		  : out std_logic_vector (7 downto 0); -- 7-segment digits 
			  gpio_6_o		  : out std_logic_vector (7 downto 0); -- 7-segment enable signals 
			  gpio_7_o		  : out std_logic_vector (7 downto 0); -- pin header 8
			  gpio_8_o		  : out std_logic_vector (7 downto 0) -- pin header 9
		 );
	end component;

	
   -- Clock period definitions
	constant clk_period : time := 10 ns; 
   
	signal clk						: std_logic;
	signal	reset_i					: std_logic;
	signal	error_o					: std_logic;

	-- memory interface 
	signal mem_address_o			: std_logic_vector(7 downto 0);
	signal mem_data_i				: std_logic_vector(7 downto 0);
	signal mem_data_o				: std_logic_vector(7 downto 0);
	signal mem_read_o				: std_logic;
	signal mem_write_o				: std_logic;
		
	-- aalu control 
	signal alu_opcode			  : std_logic_vector(3 downto 0);
	signal alu_left				  : std_logic_vector(7 downto 0);
	signal alu_right			  : std_logic_vector(7 downto 0);
	signal alu_carry_in			  : std_logic;
	signal alu_result			  : std_logic_vector(7 downto 0);
	signal alu_flagss			   : ALU_flags;

	
	-- pio 
	signal pio_address			  : std_logic_vector(7 downto 0);
	signal pio_data_from_cpu	  : std_logic_vector(7 downto 0); -- data entering IO port 
	signal pio_data_to_cpu		  : std_logic_vector(7 downto 0);
	signal pio_write_enable		  : std_logic;
	signal pio_read_enable		  : std_logic;
	signal pio_io_ready			  : std_logic;

	signal gpio_0				: std_logic_vector (7 downto 0); -- dp switches 
	signal gpio_1				: std_logic_vector (7 downto 0); -- push btns
	signal gpio_2				: std_logic_vector (7 downto 0); -- pin header 6
	signal gpio_3				: std_logic_vector (7 downto 0); -- pin header 7

	signal gpio_4				: std_logic_vector (7 downto 0); -- individual leds
	signal gpio_5				: std_logic_vector (7 downto 0); -- 7-segment digits 
	signal gpio_6				: std_logic_vector (7 downto 0); -- 7-segment enable signals 
	signal gpio_7				: std_logic_vector (7 downto 0); -- pin header 8
	signal gpio_8				: std_logic_vector (7 downto 0); -- pin header 9
	
	
			-- direct access to the video adapter 
	signal vga_pos_x			: std_logic_vector(6 downto 0); -- 0-79 - enough 7 bits 
	signal vga_pos_y			: std_logic_vector(4 downto 0); -- 0-29 - enough 5 bits
	signal vga_chr				: std_logic_vector(7 downto 0); 
	signal vga_clr				: std_logic_vector(7 downto 0); 
	signal vga_write_enable		: std_logic;
	
	signal dbg_lr				: std_logic_vector(7 downto 0);
	signal dbg_rr				: std_logic_vector(7 downto 0);
	signal dbg_rv				: std_logic_vector(7 downto 0);	
	signal dbg_state			: cpu_state_type;
	signal dbg_pc				: std_logic_vector(7 downto 0);	
	signal dbg_f				: ALU_flags := (others => '0');
	signal dbg_ir				: std_logic_vector(7 downto 0);


   type mem_type is array (0 to 255) of std_logic_vector(7 downto 0);
   signal mem: mem_type := (
   
		--0: start:
		OP_LDC & R0, x"01", -- A0 
		OP_LDC & R1, x"00", -- A1
		
		OP_LDC & R2, x"01", -- B0
		OP_LDC & R3, x"00", -- B1
		
		OP_LDC & R4, x"00", -- C0
		OP_LDC & R5, x"00", -- C1
			
--0x0c: loop: 
		OP_MOVE_RR, R4 & R0,  -- C0 = A0
		OP_AALU_RR & ALU_ADD, R4 & R2, -- C0 = A0 + B0
		OP_MOVE_RR, R5 & R1,  -- C1 = A1
		OP_AALU_RR & ALU_ADDC, R5 & R3, -- C1 = A1 + B1 + carry

		OP_MOVE_RR, R0 & R2, 
		OP_MOVE_RR, R1 & R3,	 
		OP_MOVE_RR, R2 & R4, 
		OP_MOVE_RR, R3 & R5, 

		OP_SETXY, R0 & R1,
		OP_SETC, R2 & R3,
			 

		-- now - display the thing	
		OP_LDC & R15, x"00",
		OP_OUT_GROUP & R15, x"06",
		OP_MOVE_RR, R15 & R4,
		OP_SEVENSEGTRANSLATE, R15 & x"0",
		OP_OUT_GROUP & R15, x"05",

		OP_LDC & R15, x"01",
		OP_OUT_GROUP & R15, x"06",
		OP_MOVE_RR, R15 & R4,
		OP_SEVENSEGTRANSLATE, R15 & x"4",
		OP_OUT_GROUP & R15, x"05",

		OP_LDC & R15, x"02",
		OP_OUT_GROUP & R15, x"06",
		OP_MOVE_RR, R15 & R5,
		OP_SEVENSEGTRANSLATE, R15 & x"0",
		OP_OUT_GROUP & R15, x"05",
			
			
		OP_WAIT, x"ff",

		OP_LDC & R14, x"F0",
		OP_AALU_RR & ALU_AND, R14 & R5,

		-- OP_JMP_A_NZ,			x"00",		-- go start if Acc != 0 (12-bit ovflow)						
		OP_JMP_A_UNCOND,	x"0c",		-- go loop in all other cases	  
			 
			 others => x"00"
	);

begin
	-- Instantiate the Unit(s) Under Test (UUT)
	c: controlunit port map(

		clk_i					=> clk,
		reset_i					=> reset_i,
		error_o					=> error_o,

		mem_address_o			=> mem_address_o,
		mem_data_i				=> mem_data_i,
		mem_data_o				=> mem_data_o,
		mem_read_o				=> mem_read_o,
		mem_write_o				=> mem_write_o,
		
		aalu_opcode_o			=> alu_opcode,
		aalu_left_o				=> alu_left,
		aalu_right_o			=> alu_right,
		aalu_carry_in_o			=> alu_carry_in,
		aalu_result_i			=> alu_result,
		aalu_flags_i			=> alu_flagss,

		pio_address_o			=> pio_address,
		pio_data_o				=> pio_data_from_cpu,
		pio_data_i				=> pio_data_to_cpu,
		pio_write_enable_o		=> pio_write_enable,
		pio_read_enable_o		=> pio_read_enable,
		pio_io_ready_i			=> pio_io_ready,

		vga_pos_x_o			=> vga_pos_x,
		vga_pos_y_o			=> vga_pos_y,
		vga_chr_o			=> vga_chr,
		vga_clr_o			=> vga_clr,
		vga_write_enable_o	=> vga_write_enable,

		dbg_lr_o		=>	dbg_lr,
		dbg_rr_o		=>	dbg_rr,
		dbg_rv_o		=>	dbg_rv,
		dbg_state_o		=>	dbg_state,
		dbg_pc_o		=>	dbg_pc,
		dbg_f_o			=>	dbg_f,
		dbg_ir_o		=>	dbg_ir 
	);

	a: async_ALU
		port map
		(
			operation_i			=> alu_opcode, 
			left_arg_i			=> alu_left, 
			right_arg_i			=> alu_right, 
			carry_i				=> alu_carry_in, 
			result_o			=> alu_result, 
			flags_o				=> alu_flagss 
		);

memory: 
	process (clk, mem_address_o, mem_data_o, mem_read_o, mem_write_o)
	begin
		if rising_edge(clk) 
		then
			if mem_write_o = '1' 
			then 
				mem(to_integer(unsigned(mem_address_o))) <= mem_data_o;
				mem_data_i <= mem_data_o;				
			elsif mem_read_o = '1' 
			then			
				mem_data_i <= mem(to_integer(unsigned(mem_address_o)));
			end if;			
		end if;
	end process;
	
	
	p: pio port map (
		clk_i			 => clk, 
		rst_i			 => reset_i,

		port_address_i	=> pio_address,
		data_i			=> pio_data_from_cpu,
		data_o			=> pio_data_to_cpu,
		write_enable_i	=> pio_write_enable,
		read_enable_i	=> pio_read_enable,
		io_ready_o		=> pio_io_ready,

		gpio_0_i   => gpio_0,
		gpio_1_i   => gpio_1,
		gpio_2_i   => gpio_2,
		gpio_3_i   => gpio_3,
		gpio_4_o   => gpio_4,
		gpio_5_o   => gpio_5,
		gpio_6_o   => gpio_6,
		gpio_7_o   => gpio_7,
		gpio_8_o   => gpio_8
	);

	gpio_0 <= (others => '0');
	gpio_1 <= (others => '0');
	gpio_2 <= (others => '0');
	gpio_3 <= (others => '0');

	
clock_process: 
	process -- clock generator process 
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

stim_proc: 
   process 
   begin
		reset_i <= '1';
		wait for 200 ns;	
		reset_i <= '0';
		wait for clk_period*400;		
		wait;
   end process;

end behavior;
