library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
use ieee.numeric_std.all;

entity sevenseg is
    generic (
        num_segments: integer := 3  -- up to 8
    );
    port
    (
        clk_i               : in std_logic; 
        rst_i               : in std_logic;
        sw_select_i         : in std_logic_vector(7 downto 0); -- binary encoded 
        sw_led_mask_i       : in std_logic_vector(7 downto 0);
        sel_gpio_o          : out std_logic_vector(7 downto 0);
        data_gpio_o         : out std_logic_vector(7 downto 0)
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
        if rst_i = '1' then 
            counter <= 0;
            current_digit <= 0;
        elsif rising_edge(clk_i) then 
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
    process (clk_i, rst_i, sw_select_i, sw_led_mask_i)
        variable idx : integer := 0;
    begin
        if rst_i = '1' then 
            digits <= (others => (others => '0'));
        elsif rising_edge(clk_i) then 

            idx := to_integer(unsigned(sw_select_i));
            if idx >= 0 and idx <= num_segments-1 then 
                digits(idx) <= sw_led_mask_i; 
            end if;
            
        end if;     
    end process;

end behaviour;
