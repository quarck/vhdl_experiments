library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all ;

use work.opcodes.all;
use work.types.all;

entity soc is 
	port (
		sys_clk				: in std_logic; 

		mcb3_dram_dq        : inout  std_logic_vector(15 downto 0);
		mcb3_dram_a         : out std_logic_vector(12 downto 0);
		mcb3_dram_ba		: out std_logic_vector(1 downto 0);
		mcb3_dram_cke       : out std_logic;
		mcb3_dram_ras_n     : out std_logic;
		mcb3_dram_cas_n     : out std_logic;
		mcb3_dram_we_n      : out std_logic;
		mcb3_dram_dm        : out std_logic;
		mcb3_dram_udqs      : inout  std_logic;
		mcb3_rzq            : inout  std_logic;
		mcb3_dram_udm       : out std_logic;
		mcb3_dram_dqs       : inout  std_logic;
--		mcb3_dram_ck        : out std_logic;
--		mcb3_dram_ck_n      : out std_logic;

		
		DPSwitch 			: in std_logic_vector(7 downto 0); -- pull up by default 		
		Switch 				: in std_logic_vector(5 downto 0); -- pull up by default

		LED 				: out std_logic_vector(7 downto 0);
		SevenSegment		: out std_logic_vector(7 downto 0);	-- a to g and dot 
		SevenSegmentEnable 	: out std_logic_vector(2 downto 0);

		IO_P6 				: in std_logic_vector(7 downto 0);	
		IO_P7 				: in std_logic_vector(7 downto 0);
		IO_P8 				: out std_logic_vector(7 downto 0);	
		IO_P9 				: out std_logic_vector(7 downto 0);	

		HSync				: out std_logic;
		VSync				: out std_logic;
		Red					: out std_logic_vector(2 downto 0);
		Green 				: out std_logic_vector(2 downto 0);
		Blue				: out std_logic_vector(2 downto 1)
		);
end soc;

architecture structural of soc is 

	component cpu is
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
	end component;
	
	component memory is
		generic (
			mem_size : integer := 65535
		);
		port
		(
			clk_i			: in std_logic;
			address_i		: in std_logic_vector(15 downto 0);
			data_i			: in std_logic_vector(15 downto 0);
			data_o			: out std_logic_vector(15 downto 0);
			mem_read_i		: in std_logic;
			mem_write_i		: in std_logic
		);
	end component;

	component pio is 
		port (
			clk_i			: in std_logic;
			rst_i			: in std_logic;
			
			port_address_i	: in std_logic_vector(15 downto 0);
			data_i			: in std_logic_vector(15 downto 0); -- data entering IO port 
			data_o			: out std_logic_vector(15 downto 0);
			write_enable_i	: in std_logic;
			read_enable_i	: in std_logic;
			io_ready_o		: out std_logic;
			
			gpio_0_i		: in std_logic_vector (7 downto 0); -- dp switches 
			gpio_1_i		: in std_logic_vector (7 downto 0); -- push btns
			gpio_2_i		: in std_logic_vector (7 downto 0); -- pin header 6
			gpio_3_i		: in std_logic_vector (7 downto 0); -- pin header 7
							
			gpio_4_o		: out std_logic_vector (7 downto 0); -- individual leds
			gpio_5_o		: out std_logic_vector (7 downto 0); -- 7-segment digits 
			gpio_6_o		: out std_logic_vector (7 downto 0); -- 7-segment enable signals 
			gpio_7_o		: out std_logic_vector (7 downto 0); -- pin header 8
			gpio_8_o		: out std_logic_vector (7 downto 0) -- pin header 9
		);
	end component;

	component vga is
		port(
			clk_i			: in std_logic;
			
			pos_x_i			: in std_logic_vector(6 downto 0); -- 0-79 - enough 7 bits 
			pos_y_i			: in std_logic_vector(4 downto 0); -- 0-29 - enough 5 bits
			chr_i			: in std_logic_vector(7 downto 0); 
			clr_i			: in std_logic_vector(7 downto 0); 
			write_enable_i	: in std_logic;

			hsync_o			: out std_logic;
			vsync_o			: out std_logic;
		
			red_o			: out std_logic_vector(2 downto 0);
			green_o			: out std_logic_vector(2 downto 0);
			blue_o			: out std_logic_vector(2 downto 1)
		);
	end component;

	component clocks is
	generic (
		PERIOD_PICOS 	: integer := 2500;
		CLK_DIV_0   	: integer := 2;		-- 200MHz, 0 deg
		CLK_DIV_1   	: integer := 2;		-- 200MHz, 180 deg
		CLK_DIV_2   	: integer := 16;	-- 25MHz, 0 deg 
		CLK_DIV_3   	: integer := 8;		-- 50MHz, 0 deg
		CLK_DIV_4   	: integer := 4;		-- 100MHz, 0 deg
		
		BUF_OUT_MULT 	: integer := 4;
		DIVCLK_DIV  	: integer := 1
	);
	port (
		sys_clk     	  : in std_logic;
		sys_rst 	      : in std_logic;
		
		sync_reset_out       : out std_logic; -- sync_reset_out
		async_reset_out      : out std_logic;

		clk_100_mhz_0       : out std_logic; 
		clk_25_mhz_0        : out std_logic; -- clk0 
		clk_200_mhz_0     	: out std_logic; -- sysclk_2x
		clk_200_mhz_180   	: out std_logic; -- sysclk_2x_180
		clk_50_mhz_0       	: out std_logic; -- _mcb_drp_clk
		pll_ce_0          	: out std_logic;
		pll_ce_90         	: out std_logic;
		pll_lock          	: out std_logic
	);
	end component;


	signal reset			: std_logic;
	signal error			: std_logic;

	-- address bus - multiplexed between memory and PIO 
	signal address				: std_logic_vector(15 downto 0);
	
	-- data buses - multiplexed between port and memory 
	signal data_i				: std_logic_vector(15 downto 0);
	signal data_o				: std_logic_vector(15 downto 0);
	signal mem_data_r			: std_logic_vector(15 downto 0);
	signal pio_data_r			: std_logic_vector(15 downto 0);

	-- read/write controls for both memory and PIO
	signal read_enable			: std_logic;
	signal read_select			: data_select;
	signal write_enable			: std_logic;
	signal write_select			: data_select;

	signal pio_io_ready			: std_logic;


	signal in_port_0 		: std_logic_vector (7 downto 0); -- dp switches 
	signal in_port_1 		: std_logic_vector (7 downto 0);	-- push btns
	signal in_port_2 		: std_logic_vector (7 downto 0); -- pin header 6
	signal in_port_3 		: std_logic_vector (7 downto 0); -- pin header 7

	signal out_port_4 		: std_logic_vector (7 downto 0); -- individual leds
	signal out_port_5 		: std_logic_vector (7 downto 0); -- 7-segment digits 
	signal out_port_6 		: std_logic_vector (7 downto 0); -- 7-segment enable signals 
	signal out_port_7 		: std_logic_vector (7 downto 0); -- pin header 8
	signal out_port_8 		: std_logic_vector (7 downto 0); -- pin header 9

	signal v_red			: std_logic_vector(2 downto 0);
	signal v_green	   		: std_logic_vector(2 downto 0);
	signal v_blue			: std_logic_vector(2 downto 1);
	
	signal v_pos_x			: std_logic_vector(6 downto 0);
	signal v_pos_y			: std_logic_vector(4 downto 0);
	signal v_chr			: std_logic_vector(7 downto 0); 
	signal v_clr			: std_logic_vector(7 downto 0); 
	signal v_write_enable	: std_logic;

	signal mem_read_enable 	: std_logic;
	signal mem_write_enable	: std_logic;
	signal pio_read_enable	: std_logic;
	signal pio_write_enable	: std_logic;

	signal sync_reset_out 		: std_logic; -- sync_reset_out
	signal async_reset_out		: std_logic;
	signal clk_100_mhz_0  		: std_logic; 
	signal clk_25_mhz_0   		: std_logic; -- clk0 
	signal clk_200_mhz_0     	: std_logic; -- sysclk_2x
	signal clk_200_mhz_180   	: std_logic; -- sysclk_2x_180
	signal clk_50_mhz_0      	: std_logic; -- _mcb_drp_clk
	signal pll_ce_0          	: std_logic;
	signal pll_ce_90         	: std_logic;
	signal pll_lock          	: std_logic;
	
begin 

	cl: clocks generic map (
		PERIOD_PICOS 	=> 2500,
		CLK_DIV_0   	=> 2,		-- 200MHz, 0 deg
		CLK_DIV_1   	=> 2,		-- 200MHz, 180 deg
		CLK_DIV_2   	=> 16,	-- 25MHz, 0 deg 
		CLK_DIV_3   	=> 8,		-- 50MHz, 0 deg
		CLK_DIV_4   	=> 4,		-- 100MHz, 0 deg
		BUF_OUT_MULT 	=> 4,
		DIVCLK_DIV  	=> 1
	)
	port map (
		sys_clk     	  => sys_clk,
		sys_rst 	      => reset,
		
		sync_reset_out    => sync_reset_out,
		async_reset_out   => async_reset_out,
		clk_100_mhz_0     => clk_100_mhz_0,
		clk_25_mhz_0      => clk_25_mhz_0, 
		clk_200_mhz_0     => clk_200_mhz_0,  
		clk_200_mhz_180   => clk_200_mhz_180,
		clk_50_mhz_0      => clk_50_mhz_0,
		pll_ce_0          => pll_ce_0,  
		pll_ce_90         => pll_ce_90,      
		pll_lock          => pll_lock      
	);

	mem_read_enable <= '1' when read_enable = '1' and read_select = DS_MEMORY else '0';
	mem_write_enable <= '1' when write_enable = '1' and write_select = DS_MEMORY else '0';
	pio_read_enable <= '1' when read_enable = '1' and read_select = DS_PIO else '0';
	pio_write_enable <= '1' when write_enable = '1' and write_select = DS_PIO else '0';

	data_i <= mem_data_r when read_select = DS_MEMORY else pio_data_r;

	c : cpu port map (
		clk_i					=> clk_100_mhz_0,
		reset_i					=> reset,
		error_o					=> error,

		-- address bus - multiplexed between memory and PIO 
		address_o				=> address,
		
		-- data buses - multiplexed between port and memory 
		data_i					=> data_i,
		data_o					=> data_o,

		-- read/write controls for both memory and PIO
		read_enable_o			=> read_enable,
		read_select_o			=> read_select,
		write_enable_o			=> write_enable,
		write_select_o			=> write_select,

		pio_io_ready_i			=> pio_io_ready,


		-- direct access to the video adapter 
		-- todo - remove this later in favour of using I/O ports 
		-- (even if we use dedicated opcodes for VGA, we can just use particular 
		-- port numbers for these 
		vga_pos_x_o				=> v_pos_x,
		vga_pos_y_o				=> v_pos_y,
		vga_chr_o				=> v_chr,
		vga_clr_o				=> v_clr,
		vga_write_enable_o		=> v_write_enable
	);

	m: memory port map (
		clk_i			=> clk_100_mhz_0,
		address_i		=> address,
		data_i			=> data_o,
		data_o			=> mem_data_r,
		mem_read_i		=> mem_read_enable,
		mem_write_i		=> mem_write_enable
	);
					
	p: pio port map (
		clk_i					=> clk_100_mhz_0,
		rst_i					=> reset,
			
		port_address_i			=> address,
		data_i					=> data_o,
		data_o					=> pio_data_r,
		write_enable_i			=> pio_write_enable,
		read_enable_i			=> pio_read_enable,
		io_ready_o				=> pio_io_ready,
			
		gpio_0_i				=> in_port_0,
		gpio_1_i				=> in_port_1,
		gpio_2_i				=> in_port_2,
		gpio_3_i				=> in_port_3,
 
		gpio_4_o				=> out_port_4,
		gpio_5_o				=> out_port_5,
		gpio_6_o				=> out_port_6, 
		gpio_7_o				=> out_port_7,
		gpio_8_o				=> out_port_8
	);
			
	v: vga port map (
		clk_i			=> clk_100_mhz_0,
		
		pos_x_i			=> v_pos_x,
		pos_y_i			=> v_pos_y,
		chr_i			=> v_chr,
		clr_i			=> v_clr,
		write_enable_i	=> v_write_enable,
		
		hsync_o			=> HSync,
		vsync_o			=> VSync,
		red_o			=> v_red,
		green_o			=> v_green,
		blue_o			=> v_blue
	 );
	
	-- Finally - manual signal wirings 
	reset <= not Switch(5); -- it is pull up
	
	in_port_1 <= "000" & (not Switch(4 downto 0));
	
	LED(7) <= Switch(5);
	LED(6) <= error;
	LED(5 downto 0) <= out_port_4(5 downto 0);
	
	in_port_0 <= DPSwitch;

	in_port_2 <= IO_P6;
	in_port_3 <= IO_P7;

	SevenSegment <= out_port_5;

	SevenSegmentEnable(2 downto 0) <= out_port_6(2 downto 0);

	IO_P8 <= out_port_7;
	IO_P9 <= out_port_8;

	Red <= v_red;
	Green <= v_green;
	Blue <= v_blue;

end structural;
