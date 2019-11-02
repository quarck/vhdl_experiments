LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use work.opcodes.all;
use work.types.all;

ENTITY TB_sync_alu IS
END TB_sync_alu;

ARCHITECTURE behavior OF TB_sync_alu IS 

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
	    carry_i				=> '0',
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
		rst <= '1';
		wait for clk_period * 4;
		rst <= '0';
	
		operation <= ALU_MUL;
		left_arg_high <= x"00";
		left_arg_low <= x"CA";
		right_arg <= x"23";
		wait for clk_period;
		operation <= ALU_NOP;
		wait for clk_period*10;  -- expected result: 1B 9E

		operation <= ALU_IMUL;
		wait for clk_period;
		operation <= ALU_NOP;
		wait for clk_period*10; -- expected result: F8 9E

		left_arg_low <= x"23";
		right_arg <= x"CA";
		operation <= ALU_IMUL;
		wait for clk_period;
		operation <= ALU_NOP;
		wait for clk_period*10; -- expected result: F8 9E


		left_arg_low <= x"FF";
		right_arg <= x"FF";
		operation <= ALU_IMUL;
		wait for clk_period;
		operation <= ALU_NOP;
		wait for clk_period*10; -- expected result: 00 01 


		left_arg_high <= x"00";
		left_arg_low <= x"FF";
		right_arg <= x"03";
		operation <= ALU_DIV;
		wait for clk_period;
		operation <= ALU_NOP;
		wait for clk_period*10;  -- expected result: 55 on low, 0 on high

		left_arg_high <= x"00";
		left_arg_low <= x"FE";
		right_arg <= x"03";
		operation <= ALU_DIV;
		wait for clk_period;
		operation <= ALU_NOP;
		wait for clk_period*10;  -- expected result: 54 on low, 2 on high

		left_arg_high <= x"00";
		left_arg_low <= x"FE";
		right_arg <= x"13";
		operation <= ALU_DIV;
		wait for clk_period;
		operation <= ALU_NOP;
		wait for clk_period*10;  -- expected result: D on low, 7 on high


		left_arg_high <= x"04";
		left_arg_low <= x"FE";
		right_arg <= x"13";
		operation <= ALU_DIV;
		wait for clk_period;
		operation <= ALU_NOP;
		wait for clk_period*10;  -- expected result: 43 on low, 5 on high

		left_arg_high <= x"FF";
		left_arg_low <= x"FE";
		right_arg <= x"13";
		operation <= ALU_DIV;
		wait for clk_period;
		operation <= ALU_NOP;
		wait for clk_period*10;  -- expected result: divide by zero error

		left_arg_high <= x"04";
		left_arg_low <= x"FE";
		right_arg <= x"13";
		operation <= ALU_DIV;
		wait for clk_period;
		operation <= ALU_NOP;
		wait for clk_period*10;  -- expected result: 43 on low, 5 on high

		left_arg_high <= x"00";
		left_arg_low <= x"01";
		right_arg <= x"00";
		operation <= ALU_DIV;
		wait for clk_period;
		operation <= ALU_NOP;
		wait for clk_period*10;  -- expected result: divide by zero error


		wait; -- will wait forever
    end process tb;
end;
