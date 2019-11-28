library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
use ieee.numeric_std.all;

-- 				when EXECUTE_7SEG_1 => 
-- 					if alu_ready_i = '1' 
-- 					then
-- 						case alu_result_l_i(3 downto 0) is 
-- 							when "0000" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011111100";
-- 							when "0001" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000001100000";
-- 							when "0010" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011011010";
-- 							when "0011" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011110010"; 
-- 							when "0100" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000001100110";
-- 							when "0101" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000010110110";
-- 							when "0110" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000010111110";
-- 							when "0111" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011100000";
-- 							when "1000" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011111110";
-- 							when "1001" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011110110";
-- 							when "1010" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000011101110";
-- 							when "1011" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000000111110";
-- 							when "1100" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000010011100";
-- 							when "1101" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000001111010";
-- 							when "1110" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000010011110";
-- 							when "1111" => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000010001110";								 
-- 							when others => regfile(conv_integer(instruction_register(7 downto 4))) <= "0000000000000010";
-- 						end case;
-- 						cpu_state <= FETCH_0;
-- 					end if;
-- 

entity sevenseg is
	generic (
		num_segments: integer := 3	-- up to 8
	);
	port
	(
		clk_i				: in std_logic; 
		rst_i				: in std_logic;
		sw_select_i			: in std_logic_vector(7 downto 0); -- binary encoded 
		sw_led_mask_i		: in std_logic_vector(7 downto 0);
		sel_gpio_o			: out std_logic_vector(7 downto 0);
		data_gpio_o			: out std_logic_vector(7 downto 0)
	);
end sevenseg;



architecture behaviour of sevenseg is		
	subtype counter_type is integer range 0 to 65535;
	subtype digit_idx_type is integer range 0 to num_segments-1;		
	type digits_array is array (num_segments-1 downto 0) of std_logic_vector(7 downto 0); 

	signal counter: counter_type := 0;
	signal current_digit: digit_idx_type := 0;
	signal digits : digits_array := (others => (others => '0'));	
begin
	-- first_i process - state machine handling output refreshes
	process (clk_i, rst_i)
		constant lsb_one : unsigned(7 downto 0) := "00000001";
	begin
		if rising_edge(clk_i) 
		then 
			-- signals are active low on the wire
			data_gpio_o <= not digits(current_digit);		  
			sel_gpio_o <= not std_logic_vector(shift_left(lsb_one, current_digit));
			
			if counter = counter_type'high then 
				counter <= 0;				
				if current_digit = digit_idx_type'high 
				then 
					current_digit <= 0; 
				else 
					current_digit <= current_digit + 1; 
				end if;
			else
				counter <= counter + 1;
			end if;
						
		end if;		
	end process;

	-- second process - handling internal register updates 
	process (clk_i, rst_i)
		variable idx : integer := 0;
	begin
		if rising_edge(clk_i)
		then 
			idx := to_integer(unsigned(sw_select_i));
			if idx >= 0 and idx <= num_segments-1 then 
				digits(idx) <= sw_led_mask_i; 
			end if;
			
		end if;		
	end process;

end behaviour;
