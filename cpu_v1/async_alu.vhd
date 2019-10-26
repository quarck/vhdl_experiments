library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.opcodes.all;
use work.types.all;

entity async_ALU is
    generic (
        nbits   : integer := 8
    );
    port
    (
        operation_i               : in std_logic_vector(3 downto 0);
        regfile_read_port_a_i     : in std_logic_vector(nbits-1 downto 0);
        regfile_read_port_b_i     : in std_logic_vector(nbits-1 downto 0);
        direct_arg_port_b_i       : in std_logic_vector(nbits-1 downto 0);
        b_val_select_i            : in ALU_arg_select;
        carry_i                   : in std_logic;
        result_o                  : out std_logic_vector(nbits-1 downto 0);
        flags_o                   : out ALU_flags
    );
end async_ALU;


architecture behaviour of async_ALU is  
    constant all_zeroes : std_logic_vector(nbits-1 downto 0) := (others => '0');
    constant all_ones : std_logic_vector(nbits-1 downto 0) := (others => '1');
    constant one : std_logic_vector(nbits-1 downto 0) := (0 => '1', others => '0');
    constant minus_one : std_logic_vector(nbits-1 downto 0) := (0 => '0', others => '1');
    
    signal left_arg : std_logic_vector (nbits-1 downto 0);
    signal right_arg : std_logic_vector (nbits-1 downto 0);
    
begin

    left_arg <= regfile_read_port_a_i;
    
    with b_val_select_i select
        right_arg <= regfile_read_port_b_i when reg_port,
                    direct_arg_port_b_i when others;
                    
    process (left_arg, right_arg, operation_i, carry_i)
        variable temp : std_logic_vector(nbits downto 0);
        variable mask : std_logic_vector(nbits-1 downto 0);
        variable left_as_uint: integer;
        variable right_as_uint: integer;
    begin
    
        flags_o.overflow <= '0';
        
        left_as_uint := to_integer(unsigned(left_arg));
        right_as_uint := to_integer(unsigned(right_arg));

        case operation_i is
            when ALU_ADD | ALU_ADDC =>
                temp := ('0' & left_arg) + ('0' & right_arg);

                if operation_i = ALU_ADDC 
                then 
                    temp := temp + (all_zeroes & carry_i);
                end if;
                
                if left_arg(nbits-1)=right_arg(nbits-1) then 
                    flags_o.overflow <= (left_arg(nbits-1) xor temp(nbits-1));
                else 
                    flags_o.overflow <= '0';
                end if;
                
            when ALU_SUB | ALU_SUBC =>
                temp := ('0'&left_arg) - ('0'&right_arg);

                if operation_i = ALU_SUBC 
                then 
                    temp := temp - (all_zeroes & carry_i);
                end if;
                
                if left_arg(nbits-1) /= right_arg(nbits-1) then 
                    flags_o.overflow <= (left_arg(nbits-1) xor temp(nbits-1));
                else
                    flags_o.overflow <= '0';
                end if;

            when ALU_NEG =>
                temp :=  carry_i & (all_zeroes - left_arg);
 
            when ALU_OR =>
                temp := carry_i & (left_arg or right_arg);
                
            when ALU_AND =>
                temp := carry_i & (left_arg and right_arg);

            when ALU_XOR =>
                temp := carry_i & (left_arg xor right_arg);
                
            when ALU_NOT =>
                temp := carry_i & (not left_arg);
            
            when ALU_SHR =>         
                if right_as_uint >= 0 and right_as_uint <= nbits then 
                    temp := carry_i & std_logic_vector(shift_right(unsigned(left_arg), right_as_uint));
                else 
                    temp := carry_i & all_zeroes;
                end if;
                
            when ALU_SHAR => 
                -- a bit wordy...
                if left_arg(nbits-1) = '1' then 
                    mask := all_ones;
                else 
                    mask := all_zeroes;
                end if;

                if right_as_uint >= 0 and right_as_uint <= nbits then 
                    mask := std_logic_vector(shift_left(unsigned(mask), nbits-right_as_uint));
                    temp := carry_i & (mask or std_logic_vector(shift_left(unsigned(left_arg), right_as_uint)));
                else 
                    temp := carry_i & all_zeroes;
                end if;
                            
            when ALU_SHL => 
                if right_as_uint >= 0 and right_as_uint <= nbits then 
                    temp := carry_i & std_logic_vector(shift_left(unsigned(left_arg), right_as_uint));
                else 
                    temp := carry_i & all_zeroes;
                end if;

            when others =>
                temp := '0' & all_zeroes;
        end case;

        if temp(nbits-1 downto 0) = all_zeroes then 
            flags_o.zero <= '1';
        else 
            flags_o.zero <= '0';
        end if;     
        
        flags_o.carry_out <= temp(nbits);
        flags_o.negative <= temp(nbits-1);

        result_o <= temp(nbits-1 downto 0);
        
    end process;
    
end behaviour;
