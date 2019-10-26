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
            clk_i                   : in std_logic;
            reset_i                 : in std_logic;
            error_o                 : out std_logic;
            
            -- memory interface 
            mem_address_o           : out std_logic_vector(7 downto 0);
            mem_data_i              : in std_logic_vector(7 downto 0);
            mem_data_o              : out std_logic_vector(7 downto 0);
            mem_read_o              : out std_logic;
            mem_write_o             : out std_logic;
            
            -- regfile interface
            reg_read_select_a_o     : out std_logic_vector(3 downto 0); -- hard-wired to mem_data_i(7 downto 4)
            reg_read_select_b_o     : out std_logic_vector(3 downto 0); -- hard-wired to mem_data_i(3 downto 0)
            reg_read_select_c_o     : out std_logic_vector(3 downto 0); -- latched 
            reg_write_select_o      : out std_logic_vector(3 downto 0); -- latched 
            reg_write_enable_o      : out std_logic;        
            reg_port_a_data_read_i  : in std_logic_vector (7 downto 0); 
            reg_port_b_data_read_i  : in std_logic_vector (7 downto 0); 
            reg_port_c_data_read_i  : in std_logic_vector (7 downto 0); 
            reg_write_data_o        : out  std_logic_vector (7 downto 0);

            -- aalu control 
            aalu_opcode_o           : out std_logic_vector(3 downto 0);
            aalu_carry_in_o         : out std_logic;        
            aalu_right_val_o        : out std_logic_vector(7 downto 0);
            aalu_right_select_o     : out ALU_arg_select;
            aalu_result_i           : in std_logic_vector(7 downto 0);
            aalu_flags_i            : in ALU_flags;

            -- pio 
            pio_address_o           : out std_logic_vector(7 downto 0);
            pio_data_o              : out std_logic_vector(7 downto 0); -- data entering IO port 
            pio_data_i              : in std_logic_vector(7 downto 0);
            pio_write_enable_o      : out std_logic;
            pio_read_enable_o       : out std_logic;
            pio_io_ready_i          : in std_logic;
            
            
            -- debug stuff 
            dbg_pc_o                : out std_logic_vector(7 downto 0);
            dbg_ir_o                : out std_logic_vector(7 downto 0); 
            dbg_state_o             : out cpu_state_type;
            dbg_clk_cnt_o           : out std_logic_vector(31 downto 0);
            dbg_inst_cnt_o          : out std_logic_vector(31 downto 0)
            
        );
    end component;  
    
    component async_ALU is
        generic (
            nbits   : integer := 8
        );
        port
        (
            operation_i               : in std_logic_vector(3 downto 0);
            regfile_read_port_a_i     : in std_logic_vector(nbits-1 downto 0);
            regfile_read_port_b_i     : in std_logic_vector(nbits-1 downto 0);
            direct_arg_port_b_i       : in std_logic_vector(nbits-1 downto 0);
            b_val_select_i            : in ALU_arg_select;
            carry_i                   : in std_logic;
            result_o                  : out std_logic_vector(nbits-1 downto 0);
            flags_o                   : out ALU_flags
        );
    end component;
    
    
   -- Clock period definitions
    constant clk_period : time := 10 ns; 
   
    signal clk                      : std_logic;
    signal  reset_i                 : std_logic;
    signal  error_o                 : std_logic;

    -- memory interface 
    signal mem_address_o            : std_logic_vector(7 downto 0);
    signal mem_data_i               : std_logic_vector(7 downto 0);
    signal mem_data_o               : std_logic_vector(7 downto 0);
    signal mem_read_o               : std_logic;
    signal mem_write_o              : std_logic;
    
    -- regfile interface
    signal reg_read_select_a_o  : std_logic_vector(3 downto 0); -- hard-wired to mem_data_i(7 downto 4)
    signal reg_read_select_b_o  : std_logic_vector(3 downto 0); -- hard-wired to mem_data_i(3 downto 0)
    signal reg_read_select_c_o  : std_logic_vector(3 downto 0); -- latched 
    signal reg_write_select_o       : std_logic_vector(3 downto 0); -- latched 
    signal reg_write_enable_o       : std_logic;        
    signal reg_port_a_data_read_i   : std_logic_vector (7 downto 0); 
    signal reg_port_b_data_read_i   : std_logic_vector (7 downto 0); 
    signal reg_port_c_data_read_i   : std_logic_vector (7 downto 0); 
    signal reg_write_data_o         :  std_logic_vector (7 downto 0);
    
    -- aalu control 
    signal aalu_opcode_o            : std_logic_vector(3 downto 0);
    signal aalu_carry_in_o          : std_logic;        
    signal aalu_right_val_o     : std_logic_vector(7 downto 0);
    signal aalu_right_select_o  : ALU_arg_select;
    signal aalu_result_i            : std_logic_vector(7 downto 0);
    signal aalu_flags_i         : ALU_flags;
    
    -- pio 
    signal pio_address_o            : std_logic_vector(7 downto 0);
    signal pio_data_o               : std_logic_vector(7 downto 0); -- data entering IO port 
    signal pio_data_i               : std_logic_vector(7 downto 0);
    signal pio_write_enable_o       : std_logic;
    signal pio_read_enable_o        : std_logic;
    signal pio_io_ready_i           : std_logic;
    
    
    -- debug stuff 
    signal dbg_pc_o             : std_logic_vector(7 downto 0);
    signal dbg_ir_o             : std_logic_vector(7 downto 0); 
    signal dbg_state_o              : cpu_state_type;
    signal dbg_clk_cnt_o            : std_logic_vector(31 downto 0);
    signal dbg_inst_cnt_o           : std_logic_vector(31 downto 0);

   type mem_type is array (0 to 255) of std_logic_vector(7 downto 0);
   signal mem: mem_type := (
		--0: start:
			 OP_LDC & R0, x"01", -- A0 
			 OP_LDC & R1, x"00", -- A1
			 
			 OP_LDC & R2, x"01", -- B0
			 OP_LDC & R3, x"00", -- B1
			 
			 OP_LDC & R4, x"00", -- C0
			 OP_LDC & R5, x"00", -- C1
			 
			
		--0x0c: loop: 

			 OP_MOVE_RR, R4 & R0,  -- C0 = A0
			 OP_AALU_RR & ALU_ADD, R4 & R2, -- C0 = A0 + B0

			 OP_MOVE_RR, R5 & R1,  -- C1 = A1
			 OP_AALU_RR & ALU_ADDC, R5 & R3, -- C1 = A1 + B1 + carry
			 
			 OP_MOVE_RR, R0 & R2, 
			 OP_MOVE_RR, R1 & R3,     
			 OP_MOVE_RR, R2 & R4, 
			 OP_MOVE_RR, R3 & R5, 

		-- 28
			-- now - display the thing 	
			 OP_LDC & R15, x"00",
			 OP_OUT_GROUP & R15, x"06",
			 OP_MOVE_RR, R15 & R4,
			 OP_SEVENSEGTRANSLATE, R15 & x"0",
			 OP_OUT_GROUP & R15, x"05",

			 OP_LDC & R15, x"01",
			 OP_OUT_GROUP & R15, x"06",
			 OP_MOVE_RR, R15 & R4,
			 OP_SEVENSEGTRANSLATE, R15 & x"4",
			 OP_OUT_GROUP & R15, x"05",

			 OP_LDC & R15, x"02",
			 OP_OUT_GROUP & R15, x"06",
			 OP_MOVE_RR, R15 & R5,
			 OP_SEVENSEGTRANSLATE, R15 & x"0",
			 OP_OUT_GROUP & R15, x"05",
				
		--58:
			OP_LDC & R6, x"0f",
			 OP_LDC & R7, x"00",
			 OP_LDC & R8, x"00",
			 
		-- 0x40: sleep_loop: 
			 OP_AALU_RV & ALU_SUB, R6 & x"1",
			 OP_AALU_RV & ALU_SUBC, R7 & x"0",
			 OP_AALU_RV & ALU_SUBC, R8 & x"0",
			 
			 OP_JMP_A_NZ, x"40", -- SLEEP OFFSET
			 
			 OP_MOVE_RR, R15 & R8,
			 OP_LDC & R14, x"F0",
			 OP_AALU_RR & ALU_AND, R15 & R14,
			 
			 OP_JMP_A_NZ,         x"00", 		-- go start if Acc != 0 (12-bit ovflow)						
			 OP_JMP_A_UNCOND,    x"0c", 		-- go loop in all other cases     
			 
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

        mem_address_o           => mem_address_o            ,
        mem_data_i              => mem_data_i               ,
        mem_data_o              => mem_data_o               ,
        mem_read_o              => mem_read_o               ,
        mem_write_o             => mem_write_o              ,
        reg_read_select_a_o         => reg_read_select_a_o      ,
        reg_read_select_b_o         => reg_read_select_b_o      ,
        reg_read_select_c_o         => reg_read_select_c_o      ,
        reg_write_select_o      => reg_write_select_o       ,
        reg_write_enable_o      => reg_write_enable_o       ,
        reg_port_a_data_read_i  => reg_port_a_data_read_i   ,
        reg_port_b_data_read_i  => reg_port_b_data_read_i   ,
        reg_port_c_data_read_i  => reg_port_c_data_read_i   ,
        reg_write_data_o        => reg_write_data_o         ,
        aalu_opcode_o           => aalu_opcode_o            ,
        aalu_carry_in_o         => aalu_carry_in_o          ,
        aalu_right_val_o            => aalu_right_val_o         ,
        aalu_right_select_o         => aalu_right_select_o      ,
        aalu_result_i           => aalu_result_i            ,
        aalu_flags_i                => aalu_flags_i             ,
        pio_address_o           => pio_address_o            ,
        pio_data_o              => pio_data_o               ,
        pio_data_i              => pio_data_i               ,
        pio_write_enable_o      => pio_write_enable_o       ,
        pio_read_enable_o       => pio_read_enable_o        ,
        pio_io_ready_i          => pio_io_ready_i           ,
        dbg_pc_o                    => dbg_pc_o                 ,
        dbg_ir_o                    => dbg_ir_o                 ,
        dbg_state_o             => dbg_state_o              ,
        dbg_clk_cnt_o           => dbg_clk_cnt_o            ,
        dbg_inst_cnt_o          => dbg_inst_cnt_o           
    );

    a: async_ALU
        port map
        (
            operation_i               => aalu_opcode_o,
            regfile_read_port_a_i     => reg_port_a_data_read_i,
            regfile_read_port_b_i     => reg_port_b_data_read_i,
            direct_arg_port_b_i       => aalu_right_val_o,
            b_val_select_i            => aalu_right_select_o,
            carry_i                   => aalu_carry_in_o,
            result_o                  => aalu_result_i,
            flags_o                   => aalu_flags_i
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
        wait for 200 ns;    
        reset_i <= '0';
        wait for clk_period*400;        
        wait;
   end process;

end behavior;
