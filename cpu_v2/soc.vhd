library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all ;

use work.opcodes.all;
use work.types.all;

entity soc is 
	port (
		sys_clk				: in std_logic;
		
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
			address_o				: out std_logic_vector(19 downto 0);
			
			-- data buses - multiplexed between port and memory 
			data_i					: in std_logic_vector(7 downto 0);
			data_o					: out std_logic_vector(7 downto 0);

			-- read/write controls for both memory and PIO
			read_enable_o			: out std_logic;
			read_select_o			: out data_select;
			write_enable_o			: out std_logic;
			write_select_o			: out data_select;

			pio_io_ready_i			: in std_logic
		);
	end component;
	
	component mem_map is
		generic (
			video_ram_pattern : std_logic_vector(19 downto 15) := "10111"  -- B8000 is the base for the video memory in text mode 
		);
		port
		(
			-- interface into the CPU
			address_i		: in std_logic_vector(19 downto 0);
			data_i			: in std_logic_vector(7 downto 0); 
			data_o			: out std_logic_vector(7 downto 0);
			write_i			: in std_logic;

			-- connecto this one to the main memory 
			mem_address_o	: out std_logic_vector(19 downto 0);
			mem_data_i		: in std_logic_vector(7 downto 0); 
			mem_data_o		: out std_logic_vector(7 downto 0);
			mem_write_o		: out std_logic;

			-- connecto this one to the video memory 
			vram_address_o	: out std_logic_vector(14 downto 0);
			vram_data_i		: in std_logic_vector(7 downto 0); 
			vram_data_o		: out std_logic_vector(7 downto 0);
			vram_write_o	: out std_logic
		);
	end component;
	
	component memory is
		generic (
			mem_size : integer := 32*1024
		);
		port
		(
			clk_i			: in std_logic;
			address_i		: in std_logic_vector(19 downto 0);
			data_i			: in std_logic_vector(7 downto 0);
			data_o			: out std_logic_vector(7 downto 0);
			mem_write_i		: in std_logic
		);
	end component;

	component pio is 
		port (
			clk_i			: in std_logic;
			rst_i			: in std_logic;
			
			port_address_i	: in std_logic_vector(15 downto 0);
			data_i			: in std_logic_vector(7 downto 0); -- data entering IO port 
			data_o			: out std_logic_vector(7 downto 0);
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
			
			hsync_o			: out std_logic;
			vsync_o			: out std_logic;
		
			red_o			: out std_logic_vector(2 downto 0);
			green_o			: out std_logic_vector(2 downto 0);
			blue_o			: out std_logic_vector(2 downto 1);

			-- video memory access from the CPU 
			vram_address_i	: in std_logic_vector(14 downto 0);
			vram_data_i		: in std_logic_vector(7 downto 0); 
			vram_data_o		: out std_logic_vector(7 downto 0);
			vram_write_i	: in std_logic
		);
	end component;


	signal reset			: std_logic;
	signal error			: std_logic;

	-- address bus - multiplexed between memory and PIO 
	signal address				: std_logic_vector(19 downto 0);
	
	-- data buses - multiplexed between port and memory 
	signal data_i				: std_logic_vector(7 downto 0);
	signal data_o				: std_logic_vector(7 downto 0);
	signal mem_data_r			: std_logic_vector(7 downto 0);
	signal pio_data_r			: std_logic_vector(7 downto 0);

	-- read/write controls for both memory and PIO
	signal read_enable			: std_logic;
	signal read_select			: data_select;
	signal write_enable			: std_logic;
	signal write_select			: data_select;

	signal pio_io_ready			: std_logic;


	signal in_port_1 		: std_logic_vector (7 downto 0);	-- push btns
	signal out_port_4 		: std_logic_vector (7 downto 0); -- individual leds
	signal out_port_6 		: std_logic_vector (7 downto 0); -- 7-segment enable signals 

	signal mem_write_enable	: std_logic;
	signal pio_read_enable	: std_logic;
	signal pio_write_enable	: std_logic;

		-- connecto this one to the main memory 
	signal ram_address		: std_logic_vector(19 downto 0);
	signal ram_data_i		: std_logic_vector(7 downto 0); 
	signal ram_data_o		: std_logic_vector(7 downto 0);
	signal ram_write		: std_logic; 

		-- connecto this one to the video memory 
	signal vram_address		: std_logic_vector(14 downto 0);
	signal vram_data_i		: std_logic_vector(7 downto 0); 
	signal vram_data_o		: std_logic_vector(7 downto 0);
	signal vram_write		: std_logic;

begin 

	mem_write_enable <= '1' when write_enable = '1' and write_select = DS_MEMORY else '0';
	pio_read_enable <= '1' when read_enable = '1' and read_select = DS_PIO else '0';
	pio_write_enable <= '1' when write_enable = '1' and write_select = DS_PIO else '0';

	data_i <= mem_data_r when read_select = DS_MEMORY else pio_data_r;

	c : cpu port map (
		clk_i					=> sys_clk,
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

		pio_io_ready_i			=> pio_io_ready
	);

	mm: mem_map port map (
		-- interface into the CPU
		address_i		=> address,
		data_i			=> data_o,
		data_o			=> mem_data_r,
		write_i			=> mem_write_enable,

		-- connecto this one to the main memory 
		mem_address_o	=> ram_address,
		mem_data_i		=> ram_data_i,
		mem_data_o		=> ram_data_o, 
		mem_write_o		=> ram_write, 

		-- connecto this one to the video memory 
		vram_address_o	=> vram_address, 
		vram_data_i		=> vram_data_i,
		vram_data_o		=> vram_data_o,
		vram_write_o	=> vram_write
	);

	m: memory port map (
 		clk_i			=> sys_clk,
 		address_i		=> address,
 		data_i			=> ram_data_o,
 		data_o			=> ram_data_i,
 		mem_write_i		=> ram_write
	);
	
	v: vga port map (
		clk_i			=> sys_clk,
		
		hsync_o			=> HSync,
		vsync_o			=> VSync,
		red_o			=> Red,
		green_o			=> Green,
		blue_o			=> Blue, 
		
		-- video memory access from the CPU 
		vram_address_i	=> vram_address,
		vram_data_i		=> vram_data_o,
		vram_data_o		=> vram_data_i,
		vram_write_i	=> vram_write
	);
	 
	p: pio port map (
		clk_i					=> sys_clk,
		rst_i					=> reset,
			
		port_address_i			=> address(15 downto 0),
		data_i					=> data_o,
		data_o					=> pio_data_r,
		write_enable_i			=> pio_write_enable,
		read_enable_i			=> pio_read_enable,
		io_ready_o				=> pio_io_ready,
			
		gpio_0_i				=> DPSwitch,
		gpio_1_i				=> in_port_1,
		gpio_2_i				=> IO_P6,
		gpio_3_i				=> IO_P7,
 
		gpio_4_o				=> out_port_4,
		gpio_5_o				=> SevenSegment,
		gpio_6_o				=> out_port_6, 
		gpio_7_o				=> IO_P8,
		gpio_8_o				=> IO_P9
	);

	-- Finally - some manual signal wirings 
	reset <= not Switch(5); -- it is pull up
	
	in_port_1 <= "000" & (not Switch(4 downto 0));
	
	LED(7) <= Switch(5);
	LED(6) <= error;
	LED(5 downto 0) <= out_port_4(5 downto 0);
	
	SevenSegmentEnable(2 downto 0) <= out_port_6(2 downto 0);

end structural;
