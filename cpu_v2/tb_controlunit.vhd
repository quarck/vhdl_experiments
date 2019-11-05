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
	
	component pio is 
		port (
			  clk_i			  : in std_logic;
			  rst_i			  : in std_logic;
			  
			  port_address_i  : in std_logic_vector(15 downto 0);
			  data_i		  : in std_logic_vector(15 downto 0); -- data entering IO port 
			  data_o		  : out std_logic_vector(15 downto 0);
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
	signal reset_i					: std_logic;
	signal error_o					: std_logic;

	signal cu_address				: std_logic_vector(15 downto 0);

	signal cu_data_i				: std_logic_vector(15 downto 0);
	signal cu_data_o				: std_logic_vector(15 downto 0);
	
	signal pio_cu_data_i		: std_logic_vector(15 downto 0);
	signal mem_cu_data_i		: std_logic_vector(15 downto 0);

	signal cu_read_enable			: std_logic;
	signal cu_read_select			: data_select;
	signal cu_write_enable			: std_logic;
	signal cu_write_select			: data_select;
	signal cu_pio_io_ready			: std_logic;

	signal alu_operation		: std_logic_vector(4 downto 0);
	signal alu_sync_select		: std_logic; -- latched MSB of operation_i
	signal alu_left_h			: std_logic_vector(15 downto 0);
	signal alu_left_l			: std_logic_vector(15 downto 0);
	signal alu_right_l			: std_logic_vector(15 downto 0);
	signal alu_carry			: std_logic;
	signal alu_result_h			: std_logic_vector(15 downto 0);
	signal alu_result_l			: std_logic_vector(15 downto 0);
	signal alu_flags_in			: ALU_flags;
	signal alu_sync_ready		: std_logic;

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
		
	signal dbg_lr				: std_logic_vector(15 downto 0);
	signal dbg_rr				: std_logic_vector(15 downto 0);
	signal dbg_rv				: std_logic_vector(15 downto 0);	
	signal dbg_state			: cpu_state_type;
	signal dbg_pc				: std_logic_vector(15 downto 0);	
	signal dbg_f				: ALU_flags := (others => '0');
	signal dbg_ir				: std_logic_vector(15 downto 0);


   type mem_type is array (0 to 65535) of std_logic_vector(15 downto 0);
   signal mem: mem_type := (
	
		OP_LDC & R0 & x"01", -- A0 
		OP_LDC & R1 & x"00", -- A1
		
		OP_LDC & R2 & x"01", -- B0
		OP_LDC & R3 & x"00", -- B1
		
		OP_LDC & R4 & x"00", -- C0
		OP_LDC & R5 & x"00", -- C1

		OP_LDC & R6 & x"01", -- current X pos
		OP_LDC & R7 & x"4f", -- max X pos 
		OP_LDC & R8 & x"01", -- current Y pos
		OP_LDC & R9 & x"1D", -- max Y pos
		OP_LDC & R10& x"03", -- current direction, XY, by two LSB bits 

--0x16: loop: 
		OP_MOVE_RR & R4 & R0,  -- C0 = A0
		OP_ADD & R4 & R2, -- C0 = A0 + B0
		OP_MOVE_RR & R5 & R1,  -- C1 = A1
		OP_ADDC & R5 & R3, -- C1 = A1 + B1 + carry

		OP_MOVE_RR & R0 & R2, 
		OP_MOVE_RR & R1 & R3,	 
		OP_MOVE_RR & R2 & R4, 
		OP_MOVE_RR & R3 & R5, 

		-- now - display the thing	
		OP_LDC & R15 & x"00",
		OP_OUT_GROUP & R15 & x"06",
		OP_MOVE_RR & R15 & R4,
		OP_SEVENSEGTRANSLATE & R15 & x"0",
		OP_OUT_GROUP & R15 & x"05",
		OP_LDC & R15 & x"01",
		OP_OUT_GROUP & R15 & x"06",
		OP_MOVE_RR & R15 & R4,
		OP_SEVENSEGTRANSLATE & R15 & x"4",
		OP_OUT_GROUP & R15 & x"05",
		OP_LDC & R15 & x"02",
		OP_OUT_GROUP & R15 & x"06",
		OP_MOVE_RR & R15 & R5,
		OP_SEVENSEGTRANSLATE & R15 & x"0",
		OP_OUT_GROUP & R15 & x"05",
	
		-- display a tiny dot on a VGA screen
		
		-- now - increment the position 
		OP_TEST_V & R10 & x"2", -- check the x direction 
		OP_JMP_REL_Z & x"0a", -- negative_vx
		
		OP_ADD_V & R6 & x"1",
		OP_CMP & R6 & R7, 
		OP_JMP_REL_NZ & x"02", -- non-eq 
		OP_XOR_V & R10 & x"2", -- invert x direction		
		OP_JMP_REL_UNCOND & x"06",	-- do_y

-- negative_vx:

		OP_SUB_V & R6 & x"1",
		OP_JMP_REL_NZ & x"02", 
		OP_XOR_V & R10 & x"2", -- invert x direction
-- do_y:

		OP_TEST_V & R10 & x"1", -- check the x direction 
		OP_JMP_REL_Z & x"0a", -- negative_vy
		
		OP_ADD_V & R8 & x"1",
		OP_CMP & R8 & R9, 
		OP_JMP_REL_NZ & x"02", -- non-eq 
		OP_XOR_V & R10 & x"1", -- invert x direction		
		OP_JMP_REL_UNCOND & x"06",	-- do_display

-- negative_vy:
		OP_SUB_V & R8 & x"1",
		OP_JMP_REL_NZ & x"02", 
		OP_XOR_V & R10 & x"1", -- invert x direction

-- do_display: 

		-- finally - dispay the new dot
		OP_SETXY & R6 & R8,
		OP_SETC & R4 & R5,

		-- sleep loop 
		OP_WAIT & x"01",
	
		OP_JMP_A_UNCOND & x"16",		-- go loop in all other cases	  

		others => x"0000"
	);

	signal pio_read_enable : std_logic;
	signal pio_write_enable : std_logic;

begin
	-- Instantiate the Unit(s) Under Test (UUT)
	c: controlunit port map(

		clk_i					=> clk,
		reset_i					=> reset_i,
		error_o					=> error_o,
		
		address_o				=> cu_address,
		
		data_i					=> cu_data_i,
		data_o					=> cu_data_o,

		read_enable_o			=> cu_read_enable,
		read_select_o			=> cu_read_select,
		write_enable_o			=> cu_write_enable,
		write_select_o			=> cu_write_select,
		
		pio_io_ready_i			=> cu_pio_io_ready,

		alu_operation_o			=> alu_operation,
		alu_sync_select_o		=> alu_sync_select,
		alu_left_h_o			=> alu_left_h,
		alu_left_l_o			=> alu_left_l,
		alu_right_l_o			=> alu_right_l,
		alu_carry_o				=> alu_carry,
		alu_result_h_i			=> alu_result_h,
		alu_result_l_i			=> alu_result_l,
		alu_flags_i				=> alu_flags_in,
		alu_sync_ready_i		=> alu_sync_ready,
		
		vga_pos_x_o				=> vga_pos_x,
		vga_pos_y_o				=> vga_pos_y,
		vga_chr_o				=> vga_chr,
		vga_clr_o				=> vga_clr,
		vga_write_enable_o		=> vga_write_enable,

		dbg_state_o				=> dbg_state,
		dbg_pc_o				=> dbg_pc,
		dbg_f_o					=> dbg_f,
		dbg_ir_o				=> dbg_ir	
	);

	a: ALU port map (
		clk_i				=> clk,
		rst_i				=> reset_i,
		operation_i			=> alu_operation,
		sync_select_i		=> alu_sync_select,
		left_h_i			=> alu_left_h	,
		left_l_i			=> alu_left_l	,
		right_l_i			=> alu_right_l	,
		carry_i				=> alu_carry	,
		result_h_o			=> alu_result_h	,
		result_l_o			=> alu_result_l	,
		flags_o				=> alu_flags_in	,
		sync_ready_o		=> alu_sync_ready
	);


m: 
	process (clk)
	begin
		if rising_edge(clk)
		then 
			if cu_write_enable = '1' and cu_write_select = DS_MEMORY
			then 
				mem(to_integer(unsigned(cu_address))) <= cu_data_o;
				mem_cu_data_i <= cu_data_o;
			elsif cu_read_enable = '1' and cu_read_select = DS_MEMORY
			then
				mem_cu_data_i <= mem(to_integer(unsigned(cu_address)));
			end if;
		end if;
	end process;


	pio_read_enable <= '1' when cu_read_enable = '1' and cu_read_select = DS_PIO else '0'; 
	pio_write_enable <= '1' when cu_write_enable = '1' and cu_write_select = DS_PIO else '0';
	
 	p: pio port map (
 		clk_i			 => clk, 
 		rst_i			 => reset_i,
 
 		port_address_i	=> cu_address,
 		data_i			=> cu_data_o,
 		data_o			=> pio_cu_data_i,
 		write_enable_i	=> pio_write_enable,
 		read_enable_i	=> pio_read_enable,
 		io_ready_o		=>cu_pio_io_ready,
 
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
	
	cu_data_i <= mem_cu_data_i when cu_read_select = DS_MEMORY else pio_cu_data_i;
 
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
