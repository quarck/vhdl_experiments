library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all ;

use work.opcodes.all;
use work.types.all;

entity soc is 
	port (
		clk : in std_logic; 
		rst_n		: in std_logic;
		
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

		SevenSegment_7	: out std_logic;	-- a
		SevenSegment_6	: out std_logic;	-- b
		SevenSegment_5	: out std_logic;	-- c
		SevenSegment_4	: out std_logic;	-- d
		SevenSegment_3	: out std_logic;	-- e
		SevenSegment_2	: out std_logic;	-- f
		SevenSegment_1	: out std_logic;	-- g
		SevenSegment_0	: out std_logic;	-- dot   
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
		IO_P9_0 : out std_logic  --  #Pin 8

		);
end soc;

architecture structural of soc is 

	component cpu is
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
	end component;
	
	component memory is
		port
		(
			clk			: in std_logic; 
			address_bus	: in std_logic_vector(7 downto 0);
			data_write	: in std_logic_vector(7 downto 0);
			data_read	: out std_logic_vector(7 downto 0);
			mem_read	: in std_logic;
			mem_write	: in std_logic;
			rst			: in std_logic
		);
	end component;

	component pio is 
		port (
			clk			: in std_logic;
			clk_unscaled	: in std_logic;
			rst			: in std_logic;
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

	signal reset 			: std_logic;
	signal error 			: std_logic;

	signal mem_address		: std_logic_vector(7 downto 0);
	signal data_from_mem_to_cpu	: std_logic_vector(7 downto 0);
	signal data_from_cpu_to_mem	: std_logic_vector(7 downto 0);
	signal mem_read			: std_logic;
	signal mem_write		: std_logic;

	signal pio_address 		: std_logic_vector(7 downto 0);
	signal data_from_cpu_to_pio		: std_logic_vector(7 downto 0); -- data entering IO port 
	signal data_from_pio_to_cpu		: std_logic_vector(7 downto 0);
	signal pio_write_enable	: std_logic;
	signal pio_read_enable	: std_logic;
	signal pio_io_ready		: std_logic;

	signal in_port_0 : std_logic_vector (7 downto 0); -- dp switches 
	signal in_port_1 : std_logic_vector (7 downto 0);	-- push btns
	signal in_port_2 : std_logic_vector (7 downto 0); -- pin header 6
	signal in_port_3 : std_logic_vector (7 downto 0); -- pin header 7

	signal out_port_4 : std_logic_vector (7 downto 0); -- individual leds
	signal out_port_5 : std_logic_vector (7 downto 0); -- 7-segment digits 
	signal out_port_6 : std_logic_vector (7 downto 0); -- 7-segment enable signals 
	signal out_port_7 : std_logic_vector (7 downto 0); -- pin header 8
	signal out_port_8 : std_logic_vector (7 downto 0); -- pin header 9
	
	-- signal cnt : std_logic_vector(27 downto 0) := (others => '0');
	
begin 

	--cnt <= cnt + 1 when rising_edge(clk);

	c : cpu port map (
			clk				=> clk,
			reset			=> reset,
			error			=> error,

			mem_address		=> mem_address,
			mem_data_r		=> data_from_mem_to_cpu,
			mem_data_w		=> data_from_cpu_to_mem,
			mem_read		=> mem_read,
			mem_write		=> mem_write,
		
			pio_address 	=> pio_address,
			pio_data_w		=> data_from_cpu_to_pio,
			pio_data_r		=> data_from_pio_to_cpu,
			pio_write_enable	=> pio_write_enable,
			pio_read_enable		=> pio_read_enable,
			pio_io_ready		=> pio_io_ready
	);
	
	p: pio port map (
		clk					=> clk,
		clk_unscaled		=> clk, 
		rst					=> reset,
		address 				=> pio_address,
		data_w				=> data_from_cpu_to_pio,
		data_r				=> data_from_pio_to_cpu,
		write_enable		=> pio_write_enable,
		read_enable			=> pio_read_enable,
		io_ready				=> pio_io_ready,
		
		in_port_0			=> in_port_0,
		in_port_1			=> in_port_1,
		in_port_2			=> in_port_2,
		in_port_3			=> in_port_3,

		out_port_4			=> out_port_4,
		out_port_5			=> out_port_5,
		out_port_6			=> out_port_6, 
		out_port_7			=> out_port_7,
		out_port_8			=> out_port_8
	);
	
	m: memory port map (
		clk					=> clk,
		address_bus			=> mem_address,
		data_write			=> data_from_cpu_to_mem,
		data_read			=> data_from_mem_to_cpu,
		mem_read			=> mem_read,
		mem_write			=> mem_write,
		rst					=> reset
	);
	
	-- Finally - manual signal wirings 
	reset <= not Switch_5; -- it is pull up
	
	in_port_1(7 downto 5) <= "000"; -- NC really
	in_port_1(4) <= not Switch_4;
	in_port_1(3) <= not Switch_3;
	in_port_1(2) <= not Switch_2;
	in_port_1(1) <= not Switch_1;
	in_port_1(0) <= not Switch_0;
	
	LED_7 <= out_port_4(7);
	LED_6 <= out_port_4(6);
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

end structural;
