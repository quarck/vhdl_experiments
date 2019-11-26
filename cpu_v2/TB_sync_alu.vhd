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
			nbits	: integer := 16
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
			ready_o				: out std_logic
		);
	end component;
 
   -- Clock period definitions
	constant clk_period : time := 10 ns; 

	signal clk			: std_logic;
	signal rst			: std_logic;
	signal op			: std_logic_vector(4 downto 0);
	signal lh			: std_logic_vector(15 downto 0);
	signal l			: std_logic_vector(15 downto 0);
	signal r			: std_logic_vector(15 downto 0);
	signal res_high		: std_logic_vector(15 downto 0);
	signal exp_high 	: std_logic_vector(15 downto 0) := (others => '0');
	signal res_low		: std_logic_vector(15 downto 0);
	signal exp_low 		: std_logic_vector(15 downto 0) := (others => '0');
	signal flags		: ALU_flags;
	signal alu_ready	: std_logic;
	
	signal low_equals	: std_logic; 
	signal high_equals 	: std_logic;

begin

	low_equals <= '1' when exp_low = res_low else '0';
	high_equals <= '1' when exp_high = res_high else '0';

  -- Component Instantiation
    uut: ALU port map(
		clk_i				=> clk,
	    rst_i				=> rst,
	    operation_i			=> op,
	    left_h_i			=> lh,
	    left_l_i			=> l,
	    right_l_i			=> r,
	    carry_i				=> '0',
	    result_h_o			=> res_high,
	    result_l_o			=> res_low,
	    flags_o				=> flags,
	    ready_o				=> alu_ready
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
		lh <= x"0000"; 
		
		
		-- various multiplication tests 
	
		-- unsigned mul: 0xcaca * 0x2323 = 0x1BD5579E 
		op <= ALU_MUL; l <= x"CACA"; r <= x"2323"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"1BD5"; exp_low <= x"579E";
		wait for clk_period;

		-- signed mul: 0xcaca * 0x2323 = 0xF8B2579E 
		op <= ALU_IMUL; l <= x"CACA"; r <= x"2323"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"F8B2"; exp_low <= x"579E";
		wait for clk_period;

		-- unsigned mul: 0xcaca * 0xbaba = 0x93EA1AC4 
		op <= ALU_MUL; l <= x"CACA"; r <= x"baba"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"93EA"; exp_low <= x"1AC4";
		wait for clk_period;

		-- signed mul: 0xcaca * 0xbaba = 0x00EAB60C4 
		op <= ALU_IMUL; l <= x"CACA"; r <= x"baba"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0E66"; exp_low <= x"1AC4";
		wait for clk_period;


		-- unsigned mul: 0x0cac * 0x0bac = 0x0093E790 
		op <= ALU_MUL; l <= x"0CAC"; r <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0093"; exp_low <= x"E790";
		wait for clk_period;

		-- signed mul: 0x0cac * 0x0bac = 0x0093E790 
		op <= ALU_IMUL;  l <= x"0CAC"; r <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0093"; exp_low <= x"E790";
		wait for clk_period;
		

		-- unsigned mul: 0x0000 * 0x0bac = 0x00000000 
		op <= ALU_MUL; l <= x"0000"; r <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0000"; exp_low <= x"0000";
		wait for clk_period;

		-- signed mul: 0x0000 * 0x0bac = 0x00000000 
		op <= ALU_IMUL; l <= x"0000"; r <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0000"; exp_low <= x"0000";
		wait for clk_period;
		

		-- unsigned mul: 0x0001 * 0x5bac = 0x00005bac 
		op <= ALU_MUL; l <= x"0001"; r <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0000"; exp_low <= x"0bac";
		wait for clk_period;

		-- signed mul: 0x0001 * 0x5bac = 0x00005bac 
		op <= ALU_IMUL; l <= x"0001"; r <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0000"; exp_low <= x"0bac";
		wait for clk_period;
		

		-- unsigned mul: 0xFFFF * 0x5bac = 0x5BABA454 
		op <= ALU_MUL; l <= x"FFFF"; r <= x"5bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"5BAB"; exp_low <= x"A454";
		wait for clk_period;

		-- signed mul: 0xFFFF * 0x5bac = 0x FFFF A454 
		op <= ALU_IMUL; l <= x"FFFF"; r <= x"5bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"FFFF"; exp_low <= x"A454";
		wait for clk_period;

		
		-- All the same as before, but arguments swapped in places 

		-- unsigned mul: 0xcaca * 0x2323 = 0x1BD5579E 
		op <= ALU_MUL; r <= x"CACA"; l <= x"2323"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"1BD5"; exp_low <= x"579E";
		wait for clk_period;

		-- signed mul: 0xcaca * 0x2323 = 0xF8B2579E 
		op <= ALU_IMUL; r <= x"CACA"; l <= x"2323"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"F8B2"; exp_low <= x"579E";
		wait for clk_period;

		-- unsigned mul: 0xcaca * 0xbaba = 0x93EA1AC4 
		op <= ALU_MUL; r <= x"CACA"; l <= x"baba"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"93EA"; exp_low <= x"1AC4";
		wait for clk_period;

		-- signed mul: 0xcaca * 0xbaba = 0x00EAB60C4 
		op <= ALU_IMUL; r <= x"CACA"; l <= x"baba"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0E66"; exp_low <= x"1AC4";
		wait for clk_period;


		-- unsigned mul: 0x0cac * 0x0bac = 0x0093E790 
		op <= ALU_MUL; r <= x"0CAC"; l <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0093"; exp_low <= x"E790";
		wait for clk_period;

		-- signed mul: 0x0cac * 0x0bac = 0x0093E790 
		op <= ALU_IMUL;  r <= x"0CAC"; l <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0093"; exp_low <= x"E790";
		wait for clk_period;
		

		-- unsigned mul: 0x0000 * 0x0bac = 0x00000000 
		op <= ALU_MUL; r <= x"0000"; l <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0000"; exp_low <= x"0000";
		wait for clk_period;

		-- signed mul: 0x0000 * 0x0bac = 0x00000000 
		op <= ALU_IMUL; r <= x"0000"; l <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0000"; exp_low <= x"0000";
		wait for clk_period;
		

		-- unsigned mul: 0x0001 * 0x5bac = 0x00005bac 
		op <= ALU_MUL; r <= x"0001"; l <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0000"; exp_low <= x"0bac";
		wait for clk_period;

		-- signed mul: 0x0001 * 0x5bac = 0x00005bac 
		op <= ALU_IMUL; r <= x"0001"; l <= x"0bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0000"; exp_low <= x"0bac";
		wait for clk_period;
		

		-- unsigned mul: 0xFFFF * 0x5bac = 0x5BABA454 
		op <= ALU_MUL; r <= x"FFFF"; l <= x"5bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"5BAB"; exp_low <= x"A454";
		wait for clk_period;

		-- signed mul: 0xFFFF * 0x5bac = 0x FFFF A454 
		op <= ALU_IMUL; r <= x"FFFF"; l <= x"5bac"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"FFFF"; exp_low <= x"A454";
		wait for clk_period;


		-- last one for muls .. 

		-- unsigned mul: 0xFFFF * 0xFFFF = 0xFFFE0001 
		op <= ALU_MUL; r <= x"FFFF"; l <= x"FFFF"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"FFFE"; exp_low <= x"0001";
		wait for clk_period;

		-- signed mul: 0xFFFF * 0xFFFF = 0x00000001 
		op <= ALU_IMUL; r <= x"FFFF"; l <= x"FFFF"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0000"; exp_low <= x"0001";
		wait for clk_period;


		-- unsigned mul: 0x0000 * 0x0000 = 0x00000000 
		op <= ALU_MUL; r <= x"0000"; l <= x"0000"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0000"; exp_low <= x"0000";
		wait for clk_period;

		-- signed mul: 0x0000 * 0x0000 = 0x00000000 
		op <= ALU_IMUL; r <= x"0000"; l <= x"0000"; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"0000"; exp_low <= x"0000";
		wait for clk_period;
	

		-- DIVS 
		-- DIVS 
		-- DIVS 
		-- DIVS 
		
		wait for 13 * clk_period;
	


		lh <= x"0000"; l <= x"00FF"; r <= x"0003"; op <= ALU_DIV; wait for clk_period;
		op <= ALU_NOP; wait until alu_ready = '1';
		exp_high <= x"0000"; exp_low <= x"0055";
		wait for clk_period;

		lh <= x"0000"; l <= x"00FE"; r <= x"0003"; op <= ALU_DIV;
		wait for clk_period; op <= ALU_NOP; wait until alu_ready = '1';
		exp_high <= x"0002"; exp_low <= x"0054";
		wait for clk_period;

		lh <= x"1234"; l <= x"5678"; r <= x"3313"; op <= ALU_DIV; wait for clk_period;
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"03CB"; exp_low <= x"5B3F";
		wait for clk_period;

		lh <= x"1234"; l <= x"5678"; r <= x"3313"; op <= ALU_IDIV; wait for clk_period;
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"03CB"; exp_low <= x"5B3F";
		wait for clk_period;


		lh <= x"EDCB"; l <= x"A988"; r <= x"3313"; op <= ALU_IDIV; wait for clk_period;
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"FC35"; exp_low <= x"A4C1";
		wait for clk_period;


		lh <= x"00FF"; l <= x"00FE"; r <= x"0013"; op <= ALU_DIV; wait for clk_period; 
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= (others => 'X'); exp_low <= (others => 'X');
		wait for clk_period;

		lh <= x"EDCB"; l <= x"A988"; r <= x"3313"; op <= ALU_IDIV; wait for clk_period;
		op <= ALU_NOP; wait until alu_ready = '1'; 
		exp_high <= x"FC35"; exp_low <= x"A4C1";
		wait for clk_period;

		lh <= x"0000"; l <= x"0001"; r <= x"0000"; op <= ALU_DIV; wait for clk_period;
		op <= ALU_NOP; wait until alu_ready = '1';  -- expected result: divide by zero error
		exp_high <= (others => 'X'); exp_low <= (others => 'X');
		wait for clk_period;

		wait;		-- will wait forever
    end process tb;
end;
