library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
 
use work.opcodes.all;

entity memory is
    generic (
        mem_size : integer := 256
    );
    port
    (
        clk_i           : in std_logic; 
        rst_i           : in std_logic;
        address_i       : in std_logic_vector(7 downto 0);
        data_i          : in std_logic_vector(7 downto 0);
        data_o          : out std_logic_vector(7 downto 0);
        mem_read_i      : in std_logic;
        mem_write_i     : in std_logic
    );
end memory;

architecture rtl of memory is

    type mem_type is array (0 to mem_size-1) of std_logic_vector(7 downto 0);

    signal mem: mem_type:= (
--0: start:
		 OP_LDC & R0, x"0d",
		 OP_LDC & R1, x"07",
		 OP_LDC & R2, x"44",
		 
		 OP_SETXY, R0 & R1,
		 OP_SETC, R2 & R2,
		 
		 OP_AALU_RV & ALU_ADD, R0 & x"5",
		 OP_AALU_RV & ALU_ADD, R1 & x"3",
		 OP_AALU_RV & ALU_ADD, R2 & x"1",
		 
		 -- OP_WAIT, x"FF",

		 OP_JMP_A_UNCOND, x"06",
		 
		 others => x"00"
	);
	
	attribute ram_style: string;
	attribute ram_style of mem : signal is "block";

begin
    process (clk_i)
    begin
        if rising_edge(clk_i) 
        then
            if mem_write_i = '1' 
            then 
                mem(to_integer(unsigned(address_i))) <= data_i;
                data_o <= data_i;
            elsif mem_read_i = '1' 
            then
                data_o <= mem(to_integer(unsigned(address_i)));
            end if;
        end if;

    end process;
end rtl;
