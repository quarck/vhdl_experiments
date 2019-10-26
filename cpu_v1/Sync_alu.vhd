library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.opcodes.all;
use work.types.all;

entity sync_ALU is
    generic (
        bits    : integer := 8
    );
    port
    (
        clk_i                   : std_logic;
        operation               : in std_logic_vector(3 downto 0);
        regfile_read_port_a     : in std_logic_vector(nbits-1 downto 0);
        regfile_read_port_b     : in std_logic_vector(nbits-1 downto 0);
        direct_arg_port_a       : in std_logic_vector(nbits-1 downto 0);
        direct_arg_port_b       : in std_logic_vector(nbits-1 downto 0);
        a_val_select            : in ALU_arg_select;
        b_val_select            : in ALU_arg_select;
        right_arg               : in std_logic_vector(nbits-1 downto 0);
        result                  : out std_logic_vector(nbits-1 downto 0);
        flags                   : out ALU_flags
    );
end sync_ALU;


architecture behaviour of sync_ALU is   
    constant all_zeroes : std_logic_vector(nbits-1 downto 0) := (others => '0');
    constant all_ones : std_logic_vector(nbits-1 downto 0) := (others => '1');
    constant one : std_logic_vector(nbits-1 downto 0) := (0 => '1', others => '0');
    constant minus_one : std_logic_vector(nbits-1 downto 0) := (0 => '0', others => '1');
    
    signal left_arg : std_logic_vector (nbits-1 downto 0);
    signal left_arg_high : std_logic_vector (nbits-1 downto 0); -- only for division 
    signal right_arg : std_logic_vector (nbits-1 downto 0);
    
begin

    with a_val_select select
        left_arg <= regfile_read_port_a when reg_port,
                    direct_arg_port_a when others;

    with b_val_select select
        right_arg <= regfile_read_port_b when reg_port,
                    direct_arg_port_b when others;
                    
    process (left_arg, right_arg, operation, carry_in)
        variable temp : std_logic_vector(nbits downto 0);
        variable mask : std_logic_vector(nbits-1 downto 0);
        variable left_as_uint: integer;
        variable right_as_uint: integer;
    begin
    
        flags.overflow <= '0';
        
        left_as_uint := to_integer(unsigned(left_arg));
        right_as_uint := to_integer(unsigned(right_arg));

        result2 <= all_zeroes; -- default value 

        case operation is
            when ALU_MUL =>
                temp := all_zeroes;

            when others =>
                temp := all_zeroes;
        end case;

        if temp(nbits-1 downto 0) = all_zeroes then 
            flags.zero <= '1';
        else 
            flags.zero <= '0';
        end if;     
        
        flags.carry_out <= temp(nbits);
        flags.negative <= temp(nbits-1);

        result <= temp(nbits-1 downto 0);
        
    end process;
    
end behaviour;
