--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   05:53:44 07/09/2019
-- Design Name:   
-- Module Name:   /home/ise/Xilinx_vm/vhdl_intro/source_code/part2/cpu//TB_memory.vhd
-- Project Name:  hwcpu
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: memory
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY TB_memory IS
END TB_memory;
 
ARCHITECTURE behavior OF TB_memory IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT memory
    PORT(
         clk : IN  std_logic;
         address_bus : IN  std_logic_vector(7 downto 0);
         data_write : IN  std_logic_vector(7 downto 0);
         data_read : OUT  std_logic_vector(7 downto 0);
         mem_write : IN  std_logic;
         rst : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal address_bus : std_logic_vector(7 downto 0) := (others => '0');
   signal data_write : std_logic_vector(7 downto 0) := (others => '0');
   signal mem_write : std_logic := '0';
   signal rst : std_logic := '0';

 	--Outputs
   signal data_read : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: memory PORT MAP (
          clk => clk,
          address_bus => address_bus,
          data_write => data_write,
          data_read => data_read,
          mem_write => mem_write,
          rst => rst
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

		

      wait for clk_period*10;

		rst <= '1';
		
		wait for clk_period;
		rst <= '0';
		
		wait for clk_period;

      -- insert stimulus here 
		
		address_bus <= "00000000";
		wait for clk_period;

		address_bus <= "00000001";
		wait for clk_period;

		address_bus <= "00000010";
		wait for clk_period;

		data_write <= "11111111";
		address_bus <= "00000000";
		mem_write <= '1';
		wait for clk_period;
		
		mem_write <= '0';
		
		address_bus <= "00000000";

		wait for clk_period;
		
		wait;
   end process;

END;
