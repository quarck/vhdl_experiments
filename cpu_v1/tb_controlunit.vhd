library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

use work.opcodes.all;
use work.types.all;


entity TB_controlunit is
end TB_controlunit;

architecture behavior of TB_controlunit is
    -- Component Declaration for the Unit Under Test (UUT)
	component controlunit is
		port
		(
			clk_i					: in std_logic;
			reset_i					: in std_logic;
			error_o					: out std_logic;
			
			-- memory interface 
			mem_address_o			: out std_logic_vector(7 downto 0);
			mem_data_i				: in std_logic_vector(7 downto 0);
			mem_data_o				: out std_logic_vector(7 downto 0);
			mem_read_o				: out std_logic;
			mem_write_o				: out std_logic;
			
			-- regfile interface
			reg_read_select_a_o 	: out std_logic_vector(3 downto 0); -- hard-wired to mem_data_i(7 downto 4)
			reg_read_select_b_o 	: out std_logic_vector(3 downto 0); -- hard-wired to mem_data_i(3 downto 0)
			reg_read_select_c_o 	: out std_logic_vector(3 downto 0); -- latched 
			reg_write_select_o 		: out std_logic_vector(3 downto 0); -- latched 
			reg_write_enable_o 		: out std_logic;		
			reg_port_a_data_read_i 	: in std_logic_vector (7 downto 0); 
			reg_port_b_data_read_i 	: in std_logic_vector (7 downto 0); 
			reg_port_c_data_read_i 	: in std_logic_vector (7 downto 0); 
			reg_write_data_o 		: out  std_logic_vector (7 downto 0);

			-- aalu control 
			aalu_opcode_o 			: out std_logic_vector(3 downto 0);
			aalu_carry_in_o			: out std_logic;		
			aalu_right_val_o		: out std_logic_vector(7 downto 0);
			aalu_right_select_o 	: out ALU_arg_select;
			aalu_result_i			: in std_logic_vector(7 downto 0);
			aalu_flags_i			: in ALU_flags;

			-- pio 
			pio_address_o 			: out std_logic_vector(7 downto 0);
			pio_data_o				: out std_logic_vector(7 downto 0); -- data entering IO port 
			pio_data_i				: in std_logic_vector(7 downto 0);
			pio_write_enable_o		: out std_logic;
			pio_read_enable_o		: out std_logic;
			pio_io_ready_i			: in std_logic;
			
			
			-- debug stuff 
			dbg_pc_o				: out std_logic_vector(7 downto 0);
			dbg_ir_o				: out std_logic_vector(7 downto 0); 
			dbg_state_o				: out cpu_state_type;
			dbg_clk_cnt_o			: out std_logic_vector(31 downto 0);
			dbg_inst_cnt_o			: out std_logic_vector(31 downto 0)
			
		);
	end component;	
	
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
	
	
   -- Clock period definitions
    constant clk_period : time := 10 ns; 
   
    signal clk                      : std_logic;
	signal 	reset_i					: std_logic;
	signal 	error_o					: std_logic;

	-- memory interface 
	signal mem_address_o			: std_logic_vector(7 downto 0);
	signal mem_data_i				: std_logic_vector(7 downto 0);
	signal mem_data_o				: std_logic_vector(7 downto 0);
	signal mem_read_o				: std_logic;
	signal mem_write_o				: std_logic;
	
	-- regfile interface
	signal reg_read_select_a_o 	: std_logic_vector(3 downto 0); -- hard-wired to mem_data_i(7 downto 4)
	signal reg_read_select_b_o 	: std_logic_vector(3 downto 0); -- hard-wired to mem_data_i(3 downto 0)
	signal reg_read_select_c_o 	: std_logic_vector(3 downto 0); -- latched 
	signal reg_write_select_o 		: std_logic_vector(3 downto 0); -- latched 
	signal reg_write_enable_o 		: std_logic;		
	signal reg_port_a_data_read_i 	: std_logic_vector (7 downto 0); 
	signal reg_port_b_data_read_i 	: std_logic_vector (7 downto 0); 
	signal reg_port_c_data_read_i 	: std_logic_vector (7 downto 0); 
	signal reg_write_data_o 		:  std_logic_vector (7 downto 0);
    
	-- aalu control 
	signal aalu_opcode_o 			: std_logic_vector(3 downto 0);
	signal aalu_carry_in_o			: std_logic;		
	signal aalu_right_val_o		: std_logic_vector(7 downto 0);
	signal aalu_right_select_o 	: ALU_arg_select;
	signal aalu_result_i			: std_logic_vector(7 downto 0);
	signal aalu_flags_i			: ALU_flags;
    
	-- pio 
	signal pio_address_o 			: std_logic_vector(7 downto 0);
	signal pio_data_o				: std_logic_vector(7 downto 0); -- data entering IO port 
	signal pio_data_i				: std_logic_vector(7 downto 0);
	signal pio_write_enable_o		: std_logic;
	signal pio_read_enable_o		: std_logic;
	signal pio_io_ready_i			: std_logic;
	
	
	-- debug stuff 
	signal dbg_pc_o				: std_logic_vector(7 downto 0);
	signal dbg_ir_o				: std_logic_vector(7 downto 0); 
	signal dbg_state_o				: cpu_state_type;
	signal dbg_clk_cnt_o			: std_logic_vector(31 downto 0);
	signal dbg_inst_cnt_o			: std_logic_vector(31 downto 0);

   type mem_type is array (0 to 255) of std_logic_vector(7 downto 0);
   signal mem: mem_type := (
        OP_LDC & R0, x"fa",
        OP_ST & R0, x"01",
        -- OP_ADD, R0 & R0,
        -- OP_ADD, R0 & R0,
        OP_HLT, x"00",
        others => x"00"
    );

    type regfile_type is array (15 downto 0) of std_logic_vector(7 downto 0);
	signal regfile : regfile_type := (others => (others => '0'));

begin
 	-- Instantiate the Unit(s) Under Test (UUT)
	c: controlunit port map(

        clk_i                   => clk,
        reset_i                 => reset_i,
        error_o                 => error_o,

        mem_address_o			=> mem_address_o			,
        mem_data_i				=> mem_data_i				,
        mem_data_o				=> mem_data_o				,
        mem_read_o				=> mem_read_o				,
        mem_write_o				=> mem_write_o				,
        reg_read_select_a_o 	    => reg_read_select_a_o 	    ,
        reg_read_select_b_o 	    => reg_read_select_b_o 	    ,
        reg_read_select_c_o 	    => reg_read_select_c_o 	    ,
        reg_write_select_o 		=> reg_write_select_o 		,
        reg_write_enable_o 		=> reg_write_enable_o 		,
        reg_port_a_data_read_i 	=> reg_port_a_data_read_i 	,
        reg_port_b_data_read_i 	=> reg_port_b_data_read_i 	,
        reg_port_c_data_read_i 	=> reg_port_c_data_read_i 	,
        reg_write_data_o 		=> reg_write_data_o 		,
        aalu_opcode_o 			=> aalu_opcode_o 			,
        aalu_carry_in_o			=> aalu_carry_in_o			,
        aalu_right_val_o		    => aalu_right_val_o		    ,
        aalu_right_select_o 	    => aalu_right_select_o 	    ,
        aalu_result_i			=> aalu_result_i			,
        aalu_flags_i			    => aalu_flags_i			    ,
        pio_address_o 			=> pio_address_o 			,
        pio_data_o				=> pio_data_o				,
        pio_data_i				=> pio_data_i				,
        pio_write_enable_o		=> pio_write_enable_o		,
        pio_read_enable_o		=> pio_read_enable_o		,
        pio_io_ready_i			=> pio_io_ready_i			,
        dbg_pc_o				    => dbg_pc_o				    ,
        dbg_ir_o				    => dbg_ir_o				    ,
        dbg_state_o				=> dbg_state_o				,
        dbg_clk_cnt_o			=> dbg_clk_cnt_o			,
        dbg_inst_cnt_o			=> dbg_inst_cnt_o			
	);

	a: async_ALU
        port map
        (
            operation				=> aalu_opcode_o,
            regfile_read_port_a		=> reg_port_a_data_read_i,
            regfile_read_port_b		=> reg_port_b_data_read_i,
            direct_arg_port_b		=> aalu_right_val_o,
            b_val_select 			=> aalu_right_select_o,
            carry_in				=> aalu_carry_in_o,
            result					=> aalu_result_i,
            flags					=> aalu_flags_i
        );


memory: 
    process (clk, mem_address_o, mem_data_o, mem_read_o, mem_write_o)
    begin
        if rising_edge(clk) 
		then
			if mem_write_o = '1' 
			then 
				mem(to_integer(unsigned(mem_address_o))) <= mem_data_o;
				mem_data_i <= mem_data_o;				
			elsif mem_read_o = '1' 
			then 			
				mem_data_i <= mem(to_integer(unsigned(mem_address_o)));
			end if;			
		end if;
    end process;
    
pio: 
    process
    begin
        pio_data_i <= (others => '0');
        pio_io_ready_i <= '1';
        wait;
    end process;

reg: 
    process (clk, 
            reg_read_select_a_o, reg_read_select_b_o, reg_read_select_c_o, 
            reg_write_select_o, reg_write_enable_o, reg_write_data_o)
    begin

        reg_port_a_data_read_i <= regfile(to_integer(unsigned(reg_read_select_a_o)));
        reg_port_b_data_read_i <= regfile(to_integer(unsigned(reg_read_select_b_o)));
        reg_port_c_data_read_i <= regfile(to_integer(unsigned(reg_read_select_c_o)));
        
        if rising_edge(clk) then 
            if reg_write_enable_o = '1' then 
                regfile(to_integer(unsigned(reg_write_select_o))) <= reg_write_data_o;
            end if;
        end if;
    end process;
    
clock_process: 
	process -- clock generator process 
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

stim_proc: 
   process 
   begin
		reset_i <= '1';
		wait for 20 ns;	
		reset_i <= '0';
		wait for clk_period*400;		
		wait;
   end process;

end behavior;
