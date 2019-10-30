LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use work.opcodes.all;
use work.types.all;

ENTITY TB_sync_alu IS
END TB_sync_alu;

ARCHITECTURE behavior OF TB_sync_alu IS 

	component sync_ALU is
		generic (
			nbits	: integer := 8
		);
		port
		(
			clk_i					: std_logic;
			operation_i				: in std_logic_vector(3 downto 0);
			left_arg_high_i			: in std_logic_vector(nbits-1 downto 0);
			left_arg_low_i			: in std_logic_vector(nbits-1 downto 0);
			right_arg_i				: in std_logic_vector(nbits-1 downto 0);
			result_high_o			: out std_logic_vector(nbits-1 downto 0);
			result_low_o			: out std_logic_vector(nbits-1 downto 0);
			flags_o					: out ALU_flags;
			alu_start_i				: in std_logic;
			alu_ready_o				: out std_logic
		);
	end component;

   -- Clock period definitions
	constant clk_period : time := 10 ns; 

    signal clk						: std_logic;
	signal operation				: std_logic_vector(3 downto 0);
	signal left_arg_high			: std_logic_vector(7 downto 0);
	signal left_arg_low				: std_logic_vector(7 downto 0);
	signal right_arg				: std_logic_vector(7 downto 0);
	signal result_high				: std_logic_vector(7 downto 0);
	signal result_low				: std_logic_vector(7 downto 0);
	signal flags					: ALU_flags;
	signal alu_start				: std_logic;
	signal alu_ready				: std_logic;

begin

  -- Component Instantiation
    uut: sync_ALU port map(
		clk_i					=> clk,
		operation_i				=> operation,
		left_arg_high_i			=> left_arg_high,
		left_arg_low_i			=> left_arg_low,
		right_arg_i				=> right_arg,
		result_high_o			=> result_high,
		result_low_o			=> result_low,
		flags_o					=> flags,
		alu_start_i				=> alu_start,
		alu_ready_o				=> alu_ready
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
		operation <= ALU_MUL;
		left_arg_high <= x"00";
		left_arg_low <= x"CA";
		right_arg <= x"23";
		alu_start <= '1';
		wait for clk_period;
		alu_start <= '0';
		wait for clk_period * 4;  -- expected result: 1B 9E

		operation <= ALU_IMUL;
		alu_start <= '1';
		wait for clk_period;
		alu_start <= '0';
		wait for clk_period * 4; -- expected result: F8 9E

		left_arg_low <= x"23";
		right_arg <= x"CA";
		alu_start <= '1';
		wait for clk_period;
		alu_start <= '0';
		wait for clk_period * 4; -- expected result: F8 9E


		left_arg_low <= x"FF";
		right_arg <= x"FF";
		alu_start <= '1';
		wait for clk_period;
		alu_start <= '0';
		wait for clk_period * 4;  -- expected result: 00 01 (thatx minus one times minus one)


		left_arg_high <= x"00";
		left_arg_low <= x"FF";
		right_arg <= x"03";
		operation <= ALU_DIV;
		alu_start <= '1';
		wait for clk_period;
		alu_start <= '0';
		wait for clk_period * 4;  -- expected result: 55 on low, 0 on high

		left_arg_high <= x"00";
		left_arg_low <= x"FE";
		right_arg <= x"03";
		operation <= ALU_DIV;
		alu_start <= '1';
		wait for clk_period;
		alu_start <= '0';
		wait for clk_period * 4;  -- expected result: 54 on low, 2 on high

		left_arg_high <= x"00";
		left_arg_low <= x"FE";
		right_arg <= x"13";
		operation <= ALU_DIV;
		alu_start <= '1';
		wait for clk_period;
		alu_start <= '0';
		wait for clk_period * 4;  -- expected result: D on low, 7 on high


		left_arg_high <= x"04";
		left_arg_low <= x"FE";
		right_arg <= x"13";
		operation <= ALU_DIV;
		alu_start <= '1';
		wait for clk_period;
		alu_start <= '0';
		wait for clk_period * 4;  -- expected result: 43 on low, 5 on high

		left_arg_high <= x"FF";
		left_arg_low <= x"FE";
		right_arg <= x"13";
		operation <= ALU_DIV;
		alu_start <= '1';
		wait for clk_period;
		alu_start <= '0';
		wait for clk_period * 4;  -- expected result: divide by zero error

		left_arg_high <= x"04";
		left_arg_low <= x"FE";
		right_arg <= x"13";
		operation <= ALU_DIV;
		alu_start <= '1';
		wait for clk_period;
		alu_start <= '0';
		wait for clk_period * 4;  -- expected result: 43 on low, 5 on high

		left_arg_high <= x"00";
		left_arg_low <= x"01";
		right_arg <= x"00";
		operation <= ALU_DIV;
		alu_start <= '1';
		wait for clk_period;
		alu_start <= '0';
		wait for clk_period * 4;  -- expected result: divide by zero error


		wait; -- will wait forever
    end process tb;
end;
