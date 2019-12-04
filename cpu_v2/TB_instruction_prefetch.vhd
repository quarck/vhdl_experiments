LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use work.opcodes.all;
use work.types.all;

ENTITY TB_instruction_prefetch IS
END TB_instruction_prefetch;

ARCHITECTURE behavior OF TB_instruction_prefetch IS 

	component instruction_prefetch is 
		port (
			clk_i					: in std_logic;
			reset					: in std_logic;
			enable_i 				: in std_logic;
			next_pc_i				: in std_logic_vector(19 downto 0); 
			valid_bytes_o		 	: out integer range 0 to 6; 
			instruction_register_o	: out std_logic_vector(47 downto 0); -- up to 6 bytes 
			
			mem_address_o			: out std_logic_vector(19 downto 0);
			mem_data_i				: in std_logic_vector(7 downto 0)
		);
	end component;

   -- Clock period definitions
	constant clk_period : time := 10 ns; 

	signal clk						: std_logic;
	signal rst						: std_logic;

	signal enable 					: std_logic;
	signal next_pc					: std_logic_vector(19 downto 0); 
	signal valid_bytes			 	: integer range 0 to 6; 
	signal instruction_register		: std_logic_vector(47 downto 0); -- up to 6 bytes 

	signal mem_address				: std_logic_vector(19 downto 0);
	signal mem_data					: std_logic_vector(7 downto 0);

   type mem_type is array (0 to 65535) of std_logic_vector(7 downto 0);
   signal mem: mem_type := (
		x"11", x"22", x"33", x"44", x"55", x"66", x"77", x"88",  
		x"21", x"32", x"43", x"54", x"65", x"76", x"87", x"98",  
		x"31", x"42", x"53", x"64", x"75", x"86", x"97", x"a8", 
		others => x"00"
	);

begin

	-- Component Instantiation
    uut: instruction_prefetch port map(
		clk_i					=> clk,
		reset					=> rst,
		enable_i 				=> enable,
		next_pc_i				=> next_pc,
		valid_bytes_o		 	=> valid_bytes,
		instruction_register_o	=> instruction_register,
		mem_address_o			=> mem_address,
		mem_data_i				=> mem_data
	);

	clock: process 
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process clock;
	
	
	memory: process (clk)
	begin
		if rising_edge(clk)
		then 
			mem_data <= mem(to_integer(unsigned(mem_address)));
		end if;
	end process memory;


	testbench: process	
    begin
		rst <= '1'; 
		wait for 4 * clk_period; 
		rst <= '0'; 
		next_pc <= x"00000";
		enable <= '1';
		wait for clk_period;
		
		wait until valid_bytes = 6;
		wait for clk_period;
		next_pc <= x"00001";
		wait for 4 * clk_period;
		enable <= '0';
		wait for 4 * clk_period;
		enable <= '1';
		wait until valid_bytes = 6;
		wait for clk_period;
		
		-- do something now.. 
		
		wait for 14 * clk_period;

		wait; -- will wait forever
    end process testbench;
end;
