LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use work.opcodes.all;
use work.types.all;

ENTITY TB_async_alu IS
END TB_async_alu;

ARCHITECTURE behavior OF TB_async_alu IS 

	component ALU is
		generic (
			nbits	: integer := 8
		);
		port
		(
			clk_i				: in std_logic;
			rst_i				: in std_logic; 
			operation_i			: in std_logic_vector(4 downto 0);
			left_h_i			: in std_logic_vector(nbits-1 downto 0);
			left_l_i			: in std_logic_vector(nbits-1 downto 0);
			right_l_i			: in std_logic_vector(nbits-1 downto 0);
			carry_i				: in std_logic;
			result_h_o			: out std_logic_vector(nbits-1 downto 0);
			result_l_o			: out std_logic_vector(nbits-1 downto 0);
			flags_o				: out ALU_flags;
			sync_ready_o		: out std_logic
		);
	end component;


   -- Clock period definitions
	constant clk_period : time := 10 ns; 

   signal clk						: std_logic;
	signal rst						: std_logic;
	signal operation				: std_logic_vector(4 downto 0);
	signal left_arg_high			: std_logic_vector(7 downto 0);
	signal left_arg_low				: std_logic_vector(7 downto 0);
	signal right_arg				: std_logic_vector(7 downto 0);
	signal result_high				: std_logic_vector(7 downto 0);
	signal result_low				: std_logic_vector(7 downto 0);
	signal flags					: ALU_flags;
	signal carry_in				: std_logic;
	signal alu_ready				: std_logic;

begin

  -- Component Instantiation
    uut: ALU port map(
		clk_i				=> clk,
	    rst_i				=> rst,
	    operation_i			=> operation,
	    left_h_i			=> left_arg_high,
	    left_l_i			=> left_arg_low,
	    right_l_i			=> right_arg,
	    carry_i				=> carry_in,
	    result_h_o			=> result_high,
	    result_l_o			=> result_low,
	    flags_o				=> flags,
	    sync_ready_o		=> alu_ready
	);

clock_process: 
	process -- clock generator process 
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

tb:
    process
    begin
        operation <= ALU_ADD;
        left_arg_low <= x"33";
        right_arg <= x"55";
        carry_in <= '0';
        
        wait for 10 ns; 

        wait; -- will wait forever
    end process tb;
end;
