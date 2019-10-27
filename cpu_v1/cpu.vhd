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

			-- aalu control 
			aalu_opcode_o           : out std_logic_vector(3 downto 0);
			aalu_left_o 	        : out std_logic_vector(7 downto 0);
			aalu_right_o	        : out std_logic_vector(7 downto 0);
			aalu_carry_in_o	 	    : out std_logic;
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
			

			dbg_lr_o				: out std_logic_vector(7 downto 0);
			dbg_rr_o				: out std_logic_vector(7 downto 0);
			dbg_rv_o 				: out std_logic_vector(7 downto 0);	
			dbg_state_o             : out cpu_state_type;
			dbg_pc_o          		: out std_logic_vector(7 downto 0);	
			dbg_f_o                 : out ALU_flags := (others => '0');
			dbg_ir_o       			: out std_logic_vector(7 downto 0)
			
		);
    end component;  
    
    component async_ALU is
		generic (
			nbits   : integer := 8
		);
		port
		(
			operation_i				: in std_logic_vector(3 downto 0);
			left_arg_i				: in std_logic_vector(nbits-1 downto 0);
			right_arg_i				: in std_logic_vector(nbits-1 downto 0);
			carry_i 				: in std_logic;
			result_o				: out std_logic_vector(nbits-1 downto 0);
			flags_o 				: out ALU_flags
		);
    end component;

    -- aalu control 
    signal aalu_opcode           : std_logic_vector(3 downto 0);
    signal aalu_carry_in         : std_logic;        
    signal aalu_left 	         : std_logic_vector(7 downto 0);
	signal aalu_right 	         : std_logic_vector(7 downto 0);
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
        
		aalu_opcode_o          => aalu_opcode,
		aalu_left_o 	       => aalu_left,
		aalu_right_o	       => aalu_right,
		aalu_carry_in_o		   => aalu_carry_in,
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
		
		dbg_lr_o          		=> open,
		dbg_rr_o				=> open,
		dbg_rv_o 				=> open,
		dbg_state_o				=> open,
		dbg_pc_o   				=> open,
		dbg_f_o    				=> open,
		dbg_ir_o   				=> open
    );
    
    a: async_ALU port map (
        operation_i             => aalu_opcode,
        left_arg_i  			=> aalu_left,  
        right_arg_i 			=> aalu_right,
        carry_i                 => aalu_carry_in,
        result_o                => aalu_result,
        flags_o                 => aalu_flags		
    );
    
end structural;
