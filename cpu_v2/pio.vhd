library ieee ;
use ieee.std_logic_1164.all ;

entity pio is 
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
end pio;

architecture beh of pio is 

	 component sevenseg is
		 generic (
			 num_segments: integer := 3	 -- up to 8
		 );
		 port
		 (
			 clk_i				 : in std_logic; 
			 rst_i				 : in std_logic;
			 sw_select_i		 : in std_logic_vector(7 downto 0); -- binary encoded 
			 sw_led_mask_i		 : in std_logic_vector(7 downto 0);
			 sel_gpio_o			 : out std_logic_vector(7 downto 0);
			 data_gpio_o		 : out std_logic_vector(7 downto 0)
		 );
	 end component;

	type io_state_type is (IO_IDLE, IO_BUSY);		
	signal state : io_state_type := IO_IDLE;
	
	signal sw_seg_select	: std_logic_vector(7 downto 0); -- binary encoded 
	signal sw_led_mask		: std_logic_vector(7 downto 0);

begin

	ss: sevenseg port map (
		clk_i			=> clk_i, 
		rst_i			=> rst_i,
		sw_select_i		=> sw_seg_select,
		sw_led_mask_i	=> sw_led_mask,
		sel_gpio_o		=> gpio_6_o,
		data_gpio_o		=> gpio_5_o
	);
 
	process (clk_i, rst_i)
	begin
		if rst_i = '1' 
		then 
			data_o <= (others => '0');
			gpio_4_o <= (others => '0');
			sw_led_mask <= (others => '0');
			sw_seg_select <= (others => '0');
			gpio_7_o <= (others => '0');
			gpio_8_o <= (others => '0');
		elsif rising_edge(clk_i) 
		then
			 case state is 
				 when IO_IDLE =>  
					 if write_enable_i = '1' then 
						 case port_address_i(7 downto 0) is 
							 when "00000100" => gpio_4_o <= data_i(7 downto 0);
							 when "00000101" => sw_led_mask <= data_i(7 downto 0);
							 when "00000110" => sw_seg_select <= data_i(7 downto 0);
							 when "00000111" => gpio_7_o <= data_i(7 downto 0);
							 when "00001000" => gpio_8_o <= data_i(7 downto 0);
							 when others	 => 
						 end case;
						 state <= IO_BUSY;
						 
					 elsif read_enable_i = '1' then 
						 case port_address_i(7 downto 0) is 
							 when "00000000" => data_o <= "00000000" & gpio_0_i;
							 when "00000001" => data_o <= "00000000" & gpio_1_i;
							 when "00000010" => data_o <= "00000000" & gpio_2_i;
							 when "00000011" => data_o <= "00000000" & gpio_3_i;
							 when others	 => data_o <= "0000000000000000";
						 end case;
						 
						 state <= IO_BUSY;
					 end if;
					 
				 when others => 
					 state <= IO_IDLE;
			 end case;			 
		 end if;
	end process;
	 
	io_ready_o <= '1' when state = IO_IDLE else '0';
	 
end beh;