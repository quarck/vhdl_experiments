LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use work.opcodes.all;
use work.types.all;

ENTITY TB_async_alu IS
END TB_async_alu;

ARCHITECTURE behavior OF TB_async_alu IS 

	component async_ALU is
		generic (
			nbits	: integer := 8
		);
		port
		(
			operation				: in std_logic_vector(3 downto 0);
			regfile_read_port_a		: in std_logic_vector(nbits-1 downto 0);
			regfile_read_port_b		: in std_logic_vector(nbits-1 downto 0);
			direct_arg_port_b		: in std_logic_vector(nbits-1 downto 0);
			b_val_select 			: in ALU_arg_select;
			carry_in				: in std_logic;
			result					: out std_logic_vector(nbits-1 downto 0);
			flags					: out ALU_flags
		);
	end component;


	signal operation				: std_logic_vector(3 downto 0) := "0000";
	signal regfile_read_port_a		: std_logic_vector(7 downto 0) := (others => '0');
	signal regfile_read_port_b		: std_logic_vector(7 downto 0) := (others => '0');
	signal direct_arg_port_b		: std_logic_vector(7 downto 0) := (others => '0');
	signal b_val_select 			: ALU_arg_select := reg_port;
	signal carry_in					: std_logic;
	signal result					: std_logic_vector(7 downto 0);
	signal flags					: ALU_flags;

BEGIN

  -- Component Instantiation
	uut: async_ALU 
		port map(
			operation			=> operation			,
			regfile_read_port_a	=> regfile_read_port_a	,
			regfile_read_port_b	=> regfile_read_port_b	,
			direct_arg_port_b	=> direct_arg_port_b	,
			b_val_select 		=> b_val_select 		,
			carry_in			=> carry_in			    ,
			result				=> result				,
			flags				=> flags				
		);

     tb : PROCESS
     BEGIN
	 
        operation <= ALU_ADD;
        regfile_read_port_a <= x"33";
        regfile_read_port_b <= x"55";
        direct_arg_port_b <= x"aa";
        carry_in <= '0';

        wait for 10 ns; 

        b_val_select <= value_port; 
        
        wait for 10 ns; 

        wait; -- will wait forever
     END PROCESS tb;
  --  End Test Bench 

END;
