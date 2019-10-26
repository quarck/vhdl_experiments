library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all ;

use work.opcodes.all;
use work.types.all;

entity soc is 
    port (
        clk : in std_logic; 

        DPSwitch_0 : in std_logic; -- pull up by default 
        DPSwitch_1 : in std_logic; -- pull up by default 
        DPSwitch_2 : in std_logic; -- pull up by default 
        DPSwitch_3 : in std_logic; -- pull up by default 
        DPSwitch_4 : in std_logic; -- pull up by default 
        DPSwitch_5 : in std_logic; -- pull up by default 
        DPSwitch_6 : in std_logic; -- pull up by default 
        DPSwitch_7 : in std_logic; -- pull up by default 
        Switch_5 : in std_logic; -- pull up by default
        Switch_4 : in std_logic; -- pull up by default
        Switch_3 : in std_logic; -- pull up by default
        Switch_2 : in std_logic; -- pull up by default
        Switch_1 : in std_logic; -- pull up by default
        Switch_0 : in std_logic; -- pull up by default

        LED_7 : out std_logic;
        LED_6 : out std_logic;
        LED_5 : out std_logic;
        LED_4 : out std_logic;
        LED_3 : out std_logic;
        LED_2 : out std_logic;
        LED_1 : out std_logic;
        LED_0 : out std_logic;

        SevenSegment_7  : out std_logic;    -- a
        SevenSegment_6  : out std_logic;    -- b
        SevenSegment_5  : out std_logic;    -- c
        SevenSegment_4  : out std_logic;    -- d
        SevenSegment_3  : out std_logic;    -- e
        SevenSegment_2  : out std_logic;    -- f
        SevenSegment_1  : out std_logic;    -- g
        SevenSegment_0  : out std_logic;    -- dot   
        SevenSegmentEnable_2 : out std_logic;
        SevenSegmentEnable_1 : out std_logic;
        SevenSegmentEnable_0 : out std_logic;

        IO_P6_7 : in std_logic;  --  #Pin 1
        IO_P6_6 : in std_logic;  --  #Pin 2
        IO_P6_5 : in std_logic;  --  #Pin 3
        IO_P6_4 : in std_logic;  --  #Pin 4
        IO_P6_3 : in std_logic;  --  #Pin 5
        IO_P6_2 : in std_logic;  --  #Pin 6
        IO_P6_1 : in std_logic;  --  #Pin 7
        IO_P6_0 : in std_logic;  --  #Pin 8
        IO_P7_7 : in std_logic;  --  #Pin 1
        IO_P7_6 : in std_logic;  --  #Pin 2
        IO_P7_5 : in std_logic;  --  #Pin 3
        IO_P7_4 : in std_logic;  --  #Pin 4
        IO_P7_3 : in std_logic;  --  #Pin 5
        IO_P7_2 : in std_logic;  --  #Pin 6
        IO_P7_1 : in std_logic;  --  #Pin 7
        IO_P7_0 : in std_logic;  --  #Pin 8

        IO_P8_7 : out std_logic;  --  #Pin 1
        IO_P8_6 : out std_logic;  --  #Pin 2
        IO_P8_5 : out std_logic;  --  #Pin 3
        IO_P8_4 : out std_logic;  --  #Pin 4
        IO_P8_3 : out std_logic;  --  #Pin 5
        IO_P8_2 : out std_logic;  --  #Pin 6
        IO_P8_1 : out std_logic;  --  #Pin 7
        IO_P8_0 : out std_logic;  --  #Pin 8
        IO_P9_7 : out std_logic;  --  #Pin 1
        IO_P9_6 : out std_logic;  --  #Pin 2
        IO_P9_5 : out std_logic;  --  #Pin 3
        IO_P9_4 : out std_logic;  --  #Pin 4
        IO_P9_3 : out std_logic;  --  #Pin 5
        IO_P9_2 : out std_logic;  --  #Pin 6
        IO_P9_1 : out std_logic;  --  #Pin 7
        IO_P9_0 : out std_logic;  --  #Pin 8

        HSync   : out std_logic;
        VSync   : out std_logic;
        Red_2   : out std_logic;
        Red_1   : out std_logic;
        Red_0   : out std_logic;
        Green_2 : out std_logic;
        Green_1 : out std_logic;
        Green_0 : out std_logic;
        Blue_2  : out std_logic;
        Blue_1  : out std_logic
        );
end soc;

architecture structural of soc is 

    -- component cpu is
    --     port
    --     (
    --         clk_i                   : in std_logic;
    --         reset_i                 : in std_logic;
    --         error_o                 : out std_logic;
    --         
    --         -- memory interface 
    --         mem_address_o           : out std_logic_vector(7 downto 0);
    --         mem_data_i              : in std_logic_vector(7 downto 0);
    --         mem_data_o              : out std_logic_vector(7 downto 0);
    --         mem_read_o              : out std_logic;
    --         mem_write_o             : out std_logic;
    --         
    --         -- pio 
    --         pio_address_o           : out std_logic_vector(7 downto 0);
    --         pio_data_o              : out std_logic_vector(7 downto 0); -- data entering IO port 
    --         pio_data_i              : in std_logic_vector(7 downto 0);
    --         pio_write_enable_o      : out std_logic;
    --         pio_read_enable_o       : out std_logic;
    --         pio_io_ready_i          : in std_logic;
	-- 		
	-- 		-- direct access to the video adapter 
	-- 		vga_pos_x_o				: out std_logic_vector(6 downto 0); -- 0-79 - enough 7 bits 
	-- 		vga_pos_y_o				: out std_logic_vector(4 downto 0); -- 0-29 - enough 5 bits
	-- 		vga_chr_o				: out std_logic_vector(7 downto 0); 
	-- 		vga_clr_o				: out std_logic_vector(7 downto 0); 
	-- 		vga_write_enable_o		: out std_logic
	-- 		
    --     );
    -- end component;
    
    -- component memory is
    --     generic (
    --         mem_size : integer := 256
    --     );
    --     port
    --     (
    --         clk_i           : in std_logic; 
    --         rst_i           : in std_logic;
    --         address_i       : in std_logic_vector(7 downto 0);
    --         data_i          : in std_logic_vector(7 downto 0);
    --         data_o          : out std_logic_vector(7 downto 0);
    --         mem_read_i      : in std_logic;
    --         mem_write_i     : in std_logic
    --     );
    -- end component;

--     component pio is 
--         port (
--             clk_i           : in std_logic;
--             rst_i           : in std_logic;
--             
--             port_address_i  : in std_logic_vector(7 downto 0);
--             data_i          : in std_logic_vector(7 downto 0); -- data entering IO port 
--             data_o          : out std_logic_vector(7 downto 0);
--             write_enable_i  : in std_logic;
--             read_enable_i   : in std_logic;
--             io_ready_o      : out std_logic;
--             
--             gpio_0_i        : in std_logic_vector (7 downto 0); -- dp switches 
--             gpio_1_i        : in std_logic_vector (7 downto 0); -- push btns
--             gpio_2_i        : in std_logic_vector (7 downto 0); -- pin header 6
--             gpio_3_i        : in std_logic_vector (7 downto 0); -- pin header 7
--                             
--             gpio_4_o        : out std_logic_vector (7 downto 0); -- individual leds
--             gpio_5_o        : out std_logic_vector (7 downto 0); -- 7-segment digits 
--             gpio_6_o        : out std_logic_vector (7 downto 0); -- 7-segment enable signals 
--             gpio_7_o        : out std_logic_vector (7 downto 0); -- pin header 8
--             gpio_8_o        : out std_logic_vector (7 downto 0) -- pin header 9
--         );
--     end component;


    component vga is
		port(
			clk_i     		: in std_logic;
			
			pos_x_i			: in std_logic_vector(6 downto 0); -- 0-79 - enough 7 bits 
			pos_y_i			: in std_logic_vector(4 downto 0); -- 0-29 - enough 5 bits
			chr_i			: in std_logic_vector(7 downto 0); 
			clr_i			: in std_logic_vector(7 downto 0); 
			write_enable_i	: in std_logic;

			hsync_o       	: out std_logic;
			vsync_o       	: out std_logic;
		
			red_o         	: out std_logic_vector(2 downto 0);
			green_o       	: out std_logic_vector(2 downto 0);
			blue_o        	: out std_logic_vector(2 downto 1)
		);
	end component;


    signal reset            : std_logic;
    signal error            : std_logic;

    signal mem_address      : std_logic_vector(7 downto 0);
    signal data_from_mem_to_cpu : std_logic_vector(7 downto 0);
    signal data_from_cpu_to_mem : std_logic_vector(7 downto 0);
    signal mem_read         : std_logic;
    signal mem_write        : std_logic;

    signal pio_address      : std_logic_vector(7 downto 0);
    signal data_from_cpu_to_pio     : std_logic_vector(7 downto 0); -- data entering IO port 
    signal data_from_pio_to_cpu     : std_logic_vector(7 downto 0);
    signal pio_write_enable : std_logic;
    signal pio_read_enable  : std_logic;
    signal pio_io_ready     : std_logic;

    signal in_port_0 : std_logic_vector (7 downto 0); -- dp switches 
    signal in_port_1 : std_logic_vector (7 downto 0);   -- push btns
    signal in_port_2 : std_logic_vector (7 downto 0); -- pin header 6
    signal in_port_3 : std_logic_vector (7 downto 0); -- pin header 7

    signal out_port_4 : std_logic_vector (7 downto 0); -- individual leds
    signal out_port_5 : std_logic_vector (7 downto 0); -- 7-segment digits 
    signal out_port_6 : std_logic_vector (7 downto 0); -- 7-segment enable signals 
    signal out_port_7 : std_logic_vector (7 downto 0); -- pin header 8
    signal out_port_8 : std_logic_vector (7 downto 0); -- pin header 9

    signal red         : std_logic_vector(2 downto 0);
    signal green       : std_logic_vector(2 downto 0);
    signal blue        : std_logic_vector(2 downto 1);
    
	signal v_pos_x		: std_logic_vector(6 downto 0);
	signal v_pos_y		: std_logic_vector(4 downto 0);
	signal v_chr			: std_logic_vector(7 downto 0); 
	signal v_clr			: std_logic_vector(7 downto 0); 
	signal v_write_enable	: std_logic;

	
begin 

--     c : cpu port map (
--         clk_i                   => clk,
--         reset_i                 => reset,
--         error_o                 => error,
--         
--         mem_address_o           => mem_address,
--         mem_data_i              => data_from_mem_to_cpu,
--         mem_data_o              => data_from_cpu_to_mem,
--         mem_read_o              => mem_read,
--         mem_write_o             => mem_write,
--             
--         pio_address_o           => pio_address,
--         pio_data_o              => data_from_cpu_to_pio,
--         pio_data_i              => data_from_pio_to_cpu,
--         pio_write_enable_o      => pio_write_enable,
--         pio_read_enable_o       => pio_read_enable,
--         pio_io_ready_i          => pio_io_ready,
-- 		
-- 		vga_pos_x_o				=> v_pos_x,
-- 		vga_pos_y_o				=> v_pos_y,
-- 		vga_chr_o				=> v_chr,
-- 		vga_clr_o				=> v_clr,
-- 		vga_write_enable_o		=> v_write_enable
-- 		
--     );
    
	
	  
        mem_address            <= (others => '0');
        data_from_cpu_to_mem   <= (others => '0');
        mem_read               <= '0';
        mem_write              <= '0';
        pio_address            <= (others => '0');
        data_from_cpu_to_pio   <= (others => '0');
        pio_write_enable	  <= '0';
        pio_read_enable       <= '0';
 			
--     p: pio port map (
--         clk_i                   => clk,
--         rst_i                   => reset,
--             
--         port_address_i          => pio_address,
--         data_i                  => data_from_cpu_to_pio,
--         data_o                  => data_from_pio_to_cpu,
--         write_enable_i          => pio_write_enable,
--         read_enable_i           => pio_read_enable,
--         io_ready_o              => pio_io_ready,
--             
--         gpio_0_i                => in_port_0,
--         gpio_1_i                => in_port_1,
--         gpio_2_i                => in_port_2,
--         gpio_3_i                => in_port_3,
-- 
--         gpio_4_o                => out_port_4,
--         gpio_5_o                => out_port_5,
--         gpio_6_o                => out_port_6, 
--         gpio_7_o                => out_port_7,
--         gpio_8_o                => out_port_8
--     );
    
		out_port_4 <= (others => '0');
        out_port_5 <= "01010101"; 
        out_port_6 <= "01010101"; 
        out_port_7 <= (others => '0');
        out_port_8 <= (others => '0');
		data_from_pio_to_cpu <= (others => '0');
		pio_io_ready <= '1';
	
    -- m: memory port map (
    --     clk_i           => clk,
    --     rst_i           => reset,        
    --     address_i       => mem_address,
    --     data_i          => data_from_cpu_to_mem,
    --     data_o          => data_from_mem_to_cpu,
    --     mem_read_i      => mem_read,
    --     mem_write_i     => mem_write
    -- );
	
	data_from_mem_to_cpu <= (others => '0');

    v: vga port map (
        clk_i       => clk,
		
--		pos_x_i			=> v_pos_x,
		--pos_y_i			=> v_pos_y,
		--chr_i			=> v_chr,
		--clr_i			=> v_clr,
		--write_enable_i	=> v_write_enable,
		
	pos_x_i			=> (others => '0'),
		pos_y_i			=> (others => '0'),
		chr_i			=> (others => '0'),
		clr_i			=> (others => '0'),
		write_enable_i	=> '0',		
		
        hsync_o     => HSync,
        vsync_o     => VSync,
        red_o       => red,
        green_o     => green,
        blue_o      => blue
     );
    
    -- Finally - manual signal wirings 
    reset <= not Switch_5; -- it is pull up
    
    in_port_1(7 downto 5) <= "000"; -- NC really
    in_port_1(4) <= not Switch_4;
    in_port_1(3) <= not Switch_3;
    in_port_1(2) <= not Switch_2;
    in_port_1(1) <= not Switch_1;
    in_port_1(0) <= not Switch_0;
    
	 LED_7 <= Switch_5;
	 LED_6 <= not Switch_5;
	 
    -- LED_7 <= out_port_4(7);
    -- LED_6 <= out_port_4(6);
    LED_5 <= out_port_4(5);
    LED_4 <= out_port_4(4);
    LED_3 <= out_port_4(3);
    LED_2 <= out_port_4(2);
    LED_1 <= out_port_4(1);
    LED_0 <= out_port_4(0);
    
    in_port_0(0) <= DPSwitch_0;
    in_port_0(1) <= DPSwitch_1;
    in_port_0(2) <= DPSwitch_2;
    in_port_0(3) <= DPSwitch_3;
    in_port_0(4) <= DPSwitch_4;
    in_port_0(5) <= DPSwitch_5;
    in_port_0(6) <= DPSwitch_6;
    in_port_0(7) <= DPSwitch_7;

    in_port_2(0) <= IO_P6_7;
    in_port_2(1) <= IO_P6_6;
    in_port_2(2) <= IO_P6_5;
    in_port_2(3) <= IO_P6_4;
    in_port_2(4) <= IO_P6_3;
    in_port_2(5) <= IO_P6_2;
    in_port_2(6) <= IO_P6_1;
    in_port_2(7) <= IO_P6_0;

    in_port_3(0) <= IO_P7_7;
    in_port_3(1) <= IO_P7_6;
    in_port_3(2) <= IO_P7_5;
    in_port_3(3) <= IO_P7_4;
    in_port_3(4) <= IO_P7_3;
    in_port_3(5) <= IO_P7_2;
    in_port_3(6) <= IO_P7_1;
    in_port_3(7) <= IO_P7_0;

    SevenSegment_7 <= out_port_5(7);
    SevenSegment_6 <= out_port_5(6);
    SevenSegment_5 <= out_port_5(5);
    SevenSegment_4 <= out_port_5(4);
    SevenSegment_3 <= out_port_5(3);
    SevenSegment_2 <= out_port_5(2);
    SevenSegment_1 <= out_port_5(1);
    SevenSegment_0 <= out_port_5(0);   
        
    SevenSegmentEnable_2 <= out_port_6(2);
    SevenSegmentEnable_1 <= out_port_6(1);
    SevenSegmentEnable_0 <= out_port_6(0);

    IO_P8_7 <= out_port_7(0);
    IO_P8_6 <= out_port_7(1);
    IO_P8_5 <= out_port_7(2);
    IO_P8_4 <= out_port_7(3);
    IO_P8_3 <= out_port_7(4);
    IO_P8_2 <= out_port_7(5);
    IO_P8_1 <= out_port_7(6);
    IO_P8_0 <= out_port_7(7);
    
    IO_P9_7 <= out_port_8(0);
    IO_P9_6 <= out_port_8(1);
    IO_P9_5 <= out_port_8(2);
    IO_P9_4 <= out_port_8(3);
    IO_P9_3 <= out_port_8(4);
    IO_P9_2 <= out_port_8(5);
    IO_P9_1 <= out_port_8(6);
    IO_P9_0 <= out_port_8(7);

    Red_2  <= red(2);
    Red_1  <= red(1);
    Red_0  <= red(0);
    Green_2<= green(2);
    Green_1<= green(1);
    Green_0<= green(0);
    Blue_2 <= blue(2);
    Blue_1 <= blue(1);


end structural;
