library ieee ;
use ieee.std_logic_1164.all;
use work.opcodes.all;
use work.types.all;

entity cpu is
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
        
        -- pio 
        pio_address_o           : out std_logic_vector(7 downto 0);
        pio_data_o              : out std_logic_vector(7 downto 0); -- data entering IO port 
        pio_data_i              : in std_logic_vector(7 downto 0);
        pio_write_enable_o      : out std_logic;
        pio_read_enable_o       : out std_logic;
        pio_io_ready_i          : in std_logic;

		-- direct access to the video adapter 
		vga_pos_x_o				: out std_logic_vector(6 downto 0); -- 0-79 - enough 7 bits 
		vga_pos_y_o				: out std_logic_vector(4 downto 0); -- 0-29 - enough 5 bits
		vga_chr_o				: out std_logic_vector(7 downto 0); 
		vga_clr_o				: out std_logic_vector(7 downto 0); 
		vga_write_enable_o		: out std_logic
    );
end cpu;

architecture structural of cpu is 

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
            
			-- direct access to the video adapter 
			vga_pos_x_o				: out std_logic_vector(6 downto 0); -- 0-79 - enough 7 bits 
			vga_pos_y_o				: out std_logic_vector(4 downto 0); -- 0-29 - enough 5 bits
			vga_chr_o				: out std_logic_vector(7 downto 0); 
			vga_clr_o				: out std_logic_vector(7 downto 0); 
			vga_write_enable_o		: out std_logic;
            
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

    component regfile is
        generic (
            nreg    : integer := 4; -- 2**nreg is the number of registers generated 
            bits    : integer := 8
        );
        port ( 
            clk_i                   : in std_logic;
            rst_i                   : in std_logic;
            read_select_a_i         : in std_logic_vector(nreg-1 downto 0); 
            read_select_b_i         : in std_logic_vector(nreg-1 downto 0); 
            read_select_c_i         : in std_logic_vector(nreg-1 downto 0); 
            
            write_select_i          : in std_logic_vector(nreg-1 downto 0);
            write_enable_i          : in std_logic;
            
            port_a_data_read_o      : out std_logic_vector (bits-1 downto 0); 
            port_b_data_read_o      : out std_logic_vector (bits-1 downto 0); 
            port_c_data_read_o      : out std_logic_vector (bits-1 downto 0); 

            write_data_i            : in  std_logic_vector (bits-1 downto 0)
        );
    end component;

    -- regfile interface
    signal reg_read_select_a     : std_logic_vector(3 downto 0); 
    signal reg_read_select_b     : std_logic_vector(3 downto 0); 
    signal reg_read_select_c     : std_logic_vector(3 downto 0); 
    signal reg_write_select      : std_logic_vector(3 downto 0); 
    signal reg_write_enable      : std_logic;        
    signal reg_port_a_data_read  : std_logic_vector (7 downto 0); 
    signal reg_port_b_data_read  : std_logic_vector (7 downto 0); 
    signal reg_port_c_data_read  : std_logic_vector (7 downto 0); 
    signal reg_write_data        : std_logic_vector (7 downto 0);

    -- aalu control 
    signal aalu_opcode           : std_logic_vector(3 downto 0);
    signal aalu_carry_in         : std_logic;        
    signal aalu_right_val        : std_logic_vector(7 downto 0);
    signal aalu_right_select     : ALU_arg_select;
    signal aalu_result           : std_logic_vector(7 downto 0);
    signal aalu_flags            : ALU_flags;

begin
    c: controlunit port map(
        clk_i                  => clk_i,
        reset_i                => reset_i,
        error_o                => error_o,
        
        -- memory interface   
        mem_address_o          => mem_address_o,
        mem_data_i             => mem_data_i,
        mem_data_o             => mem_data_o,
        mem_read_o             => mem_read_o,
        mem_write_o            => mem_write_o,
        
        -- regfile interface   
        reg_read_select_a_o    => reg_read_select_a,
        reg_read_select_b_o    => reg_read_select_b,
        reg_read_select_c_o    => reg_read_select_c,
        reg_write_select_o     => reg_write_select,
        reg_write_enable_o     => reg_write_enable,
        reg_port_a_data_read_i => reg_port_a_data_read,
        reg_port_b_data_read_i => reg_port_b_data_read,
        reg_port_c_data_read_i => reg_port_c_data_read,
        reg_write_data_o       => reg_write_data,

        -- aalu control 
        aalu_opcode_o          => aalu_opcode,
        aalu_carry_in_o        => aalu_carry_in,
        aalu_right_val_o       => aalu_right_val,
        aalu_right_select_o    => aalu_right_select,
        aalu_result_i          => aalu_result,
        aalu_flags_i           => aalu_flags,

        -- pio   
        pio_address_o          => pio_address_o,
        pio_data_o             => pio_data_o,
        pio_data_i             => pio_data_i,
        pio_write_enable_o     => pio_write_enable_o,
        pio_read_enable_o      => pio_read_enable_o,
        pio_io_ready_i         => pio_io_ready_i,

		vga_pos_x_o				=> vga_pos_x_o,
		vga_pos_y_o				=> vga_pos_y_o,
		vga_chr_o				=> vga_chr_o,
		vga_clr_o				=> vga_clr_o,
		vga_write_enable_o		=> vga_write_enable_o,


        -- debug stuff 
        dbg_pc_o               => open,
        dbg_ir_o               => open,
        dbg_state_o            => open,
        dbg_clk_cnt_o          => open,
        dbg_inst_cnt_o         => open
    );
    
    a: async_ALU port map (
        operation_i            => aalu_opcode,
        regfile_read_port_a_i  => reg_port_a_data_read,  -- direct connection to 
        regfile_read_port_b_i  => reg_port_b_data_read,  -- the register file
        direct_arg_port_b_i    => aalu_right_val,
        b_val_select_i         => aalu_right_select,
        carry_i                => aalu_carry_in,
        result_o               => aalu_result,
        flags_o                => aalu_flags
    );
    
    r: regfile port map ( 
        clk_i                   => clk_i,
        rst_i                   => reset_i,

        read_select_a_i         => reg_read_select_a,
        read_select_b_i         => reg_read_select_b,
        read_select_c_i         => reg_read_select_c,
                
        write_select_i          => reg_write_select,
        write_enable_i          => reg_write_enable,
                
        port_a_data_read_o      => reg_port_a_data_read,
        port_b_data_read_o      => reg_port_b_data_read,
        port_c_data_read_o      => reg_port_c_data_read,
        
        write_data_i            => reg_write_data
    );

end structural;
