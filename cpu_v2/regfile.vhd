library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile is
    generic (
        nreg    : integer := 4; -- 2**nreg is the number of registers generated 
        bits    : integer := 16
    );
    port ( 
		  -- reads are async, writes are on rising_edge 
		clk_i			: in std_logic; 
		rst_i			: in std_logic;

		sel_a_i			: in std_logic_vector(nreg-1 downto 0); 
		sel_b_i			: in std_logic_vector(nreg-1 downto 0); 		  
		sel_w_i			: in std_logic_vector(nreg-1 downto 1); 	-- wide port sel
	
		wr_sel_i		: in std_logic_vector(nreg-1 downto 0);	-- write port sel
		we_i			: in std_logic;

		data_a_o		: out std_logic_vector (bits-1 downto 0); 
		data_b_o		: out std_logic_vector (bits-1 downto 0); 
		data_w_o		: out std_logic_vector (2*bits-1 downto 0); 
		data_i			: in  std_logic_vector (bits-1 downto 0)
    );
end regfile;

architecture rtl of regfile is

	component reg is
		generic (
			nbits	: integer := 16
		);
		port (
			clk_i		: in std_logic;
			rst_i		: in std_logic;
			we_i		: in std_logic;
			data_o		: out std_logic_vector(nbits-1 downto 0);
			data_i 		: in std_logic_vector(nbits-1 downto 0)
		);
	end component;

	signal write_enable_vec: std_logic_vector(2**nreg-1 downto 0);

    type data_array_type is array (2**nreg-1 downto 0) of std_logic_vector(bits-1 downto 0);
    signal data_out_vec : data_array_type;
	
	signal wide_sel_low : std_logic_vector(nreg-1 downto 0);
	signal wide_sel_high : std_logic_vector(nreg-1 downto 0);
	
begin

gen_registers: 
	for i in 0 to 2**nreg-1 
	generate 
		write_enable_vec(i) <= we_i when to_integer(unsigned(wr_sel_i)) = i 
							else '0';

		r: reg port map(
			clk_i		=> clk_i, 
			rst_i		=> rst_i,
			we_i		=> write_enable_vec(i),
			data_o		=> data_out_vec(i),
			data_i 		=> data_i
		);	
	end generate gen_registers;

	-- output multiplexers 
	data_a_o <= data_out_vec(to_integer(unsigned(sel_a_i)));
	data_b_o <= data_out_vec(to_integer(unsigned(sel_b_i)));

	wide_sel_low <= sel_w_i & '0';
	wide_sel_high <= sel_w_i & '1';
	
	data_w_o <=
		data_out_vec(to_integer(unsigned(wide_sel_high))) 
		& data_out_vec(to_integer(unsigned(wide_sel_low)));

end rtl;

