library ieee ;
use ieee.std_logic_1164.all ;

entity pio is 
	port (
		clk				: in std_logic;
		clk_unscaled	: in std_logic;
		rst 			: in std_logic;
		address 		: in std_logic_vector(7 downto 0);
		data_w			: in std_logic_vector(7 downto 0); -- data entering IO port 
		data_r			: out std_logic_vector(7 downto 0);
		write_enable	: in std_logic;
		read_enable		: in std_logic;
		io_ready		: out std_logic;
		
		in_port_0		: in std_logic_vector (7 downto 0); -- dp switches 
		in_port_1		: in std_logic_vector (7 downto 0);	-- push btns
		in_port_2		: in std_logic_vector (7 downto 0); -- pin header 6
		in_port_3		: in std_logic_vector (7 downto 0); -- pin header 7

		out_port_4		: out std_logic_vector (7 downto 0); -- individual leds
		out_port_5		: out std_logic_vector (7 downto 0); -- 7-segment digits 
		out_port_6		: out std_logic_vector (7 downto 0); -- 7-segment enable signals 
		out_port_7		: out std_logic_vector (7 downto 0); -- pin header 8
		out_port_8		: out std_logic_vector (7 downto 0) -- pin header 9
	);
end pio;

architecture beh of pio is 

	component sevenseg is
		generic (
			num_segments: integer := 3  -- up to 8
		);
		port
		(
			clk						: in std_logic; 
			rst						: in std_logic;
			segment_select			: in std_logic_vector(7 downto 0); -- binary encoded 
			segment_led_mask		: in std_logic_vector(7 downto 0);
			sel_port_out			: out std_logic_vector(7 downto 0);
			data_port_out			: out std_logic_vector(7 downto 0)
		);
	end component;


	type io_state_type is (IO_IDLE, IO_BUSY);		
	signal state : io_state_type := IO_IDLE;
	
	signal segment_select	: std_logic_vector(7 downto 0); -- binary encoded 
	signal segment_led_mask	: std_logic_vector(7 downto 0);

begin
	ss: sevenseg port map
		(
			clk						=> clk_unscaled, 
			rst						=> rst,
			segment_select			=> segment_select,
			segment_led_mask		=> segment_led_mask,
			sel_port_out			=> out_port_6,
			data_port_out			=> out_port_5
		);

	process (clk, data_w, write_enable, read_enable)
	begin
		if rising_edge(clk) then
				
			case state is 
				when IO_IDLE => 

					if write_enable = '1' then 
						case address is 
							when "00000100" => out_port_4 <= data_w;
							when "00000101" => segment_led_mask <= data_w;
							when "00000110" => segment_select <= data_w;
							when "00000111" => out_port_7 <= data_w;
							when "00001000" => out_port_8 <= data_w;
							when others		=> 
						end case;
						
						state <= IO_BUSY;
						
					elsif read_enable = '1' then 
						case address is 
							when "00000000" => data_r <= in_port_0;
							when "00000001" => data_r <= in_port_1;
							when "00000010" => data_r <= in_port_2;
							when "00000011" => data_r <= in_port_3;
							when others		=> data_r <= "00000000";
						end case;
						
						state <= IO_BUSY;
					end if;
					
				when others => 
					state <= IO_IDLE;
			end case;			
		end if;
	end process;
	
	io_ready <= '1' when state = IO_IDLE else '0';
	
end beh;