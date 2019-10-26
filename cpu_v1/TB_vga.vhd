--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   21:34:53 10/14/2019
-- Design Name:   
-- Module Name:   /home/ise/Xilinx_vm/vhdl_experiments/cpu_v1/TB_vga.vhd
-- Project Name:  hwcpu
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: vga
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
 
ENTITY TB_vga IS
END TB_vga;
 
ARCHITECTURE behavior OF TB_vga IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT vga
    PORT(
         clk_i : IN  std_logic;
         hsync_o : OUT  std_logic;
         vsync_o : OUT  std_logic;
         red_o : OUT  std_logic_vector(2 downto 0);
         green_o : OUT  std_logic_vector(2 downto 0);
         blue_o : OUT  std_logic_vector(2 downto 1)
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';

 	--Outputs
   signal hsync_o : std_logic;
   signal vsync_o : std_logic;
   signal red_o : std_logic_vector(2 downto 0);
   signal green_o : std_logic_vector(2 downto 0);
   signal blue_o : std_logic_vector(2 downto 1);

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: vga PORT MAP (
          clk_i => clk_i,
          hsync_o => hsync_o,
          vsync_o => vsync_o,
          red_o => red_o,
          green_o => green_o,
          blue_o => blue_o
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_i_period*10000;

      -- insert stimulus here 

      wait;
   end process;

END;
