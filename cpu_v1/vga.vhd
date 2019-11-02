library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all ;

library work;

entity vga is
	port(
		clk_i			: in std_logic;
		
		pos_x_i			: in std_logic_vector(6 downto 0); -- 0-79 - enough 7 bits 
		pos_y_i			: in std_logic_vector(4 downto 0); -- 0-29 - enough 5 bits
		chr_i			: in std_logic_vector(7 downto 0); 
		clr_i			: in std_logic_vector(7 downto 0); 
		write_enable_i	: in std_logic;

		hsync_o			: out std_logic;
		vsync_o			: out std_logic;
	
		red_o			: out std_logic_vector(2 downto 0);
		green_o			: out std_logic_vector(2 downto 0);
		blue_o			: out std_logic_vector(2 downto 1)
	);
end vga;

architecture behavioral of vga is

	component vga_chrg_rom is
		port(
			clk_i	: in std_logic;
			chr_i	: in std_logic_vector(6 downto 0);
			gen_y_i : in integer range 0 to 15 := 0;
			line_o	: out std_logic_vector(0 to 7)
		);
	end component;


	type screen_mem_type is array (0 to 80*30) of std_logic_vector(7 downto 0);

	signal char_memory	: screen_mem_type := (others => x"00");
		
	signal color_memory : screen_mem_type := ( others => x"FF" );

	attribute ram_style: string;
	attribute ram_style of char_memory : signal is "block";
	attribute ram_style of color_memory : signal is "block";

	-- Intermediate register used internally
	signal rgb			 : std_logic_vector(7 downto 0) := x"f0";

	-- Set the resolution of screen
	signal pixel_x		 : integer range 0 to 1023 := 640;
	signal pixel_y		 : integer range 0 to 1023 := 480;

	-- Set the count from where it should start
	signal next_pixel_x	  : integer range 0 to 1023 := 640 + 1;
	signal next_pixel_y	  : integer range 0 to 1023 := 480;	  

	signal chr_x : integer range 0 to 127 := 0;
	signal chr_y : integer range 0 to 31 := 0;

	-- position inside each pixel
	signal gen_x : integer range 0 to 7 := 0;
	signal gen_y : integer range 0 to 15 := 0;

	signal chr : std_logic_vector(7 downto 0);
	signal clr : std_logic_vector(7 downto 0);
	signal chrg_line: std_logic_vector(0 to 7);
	
	
begin
	chr_x <= next_pixel_x / 8;
	gen_x <= next_pixel_x mod 8;

	chr_y <= next_pixel_y / 16; 
	gen_y <= next_pixel_y mod 16;

	rom: vga_chrg_rom port map(
		clk_i	=> clk_i,
		chr_i	=> chr(6 downto 0), 
		gen_y_i	=> gen_y,
		line_o	=> chrg_line
	);
	
write_process: 
	process (clk_i)
		variable offset : integer range 0 to 80 * 40;
		variable x : integer range 0 to 127;
		variable y : integer range 0 to 31;
	begin
		if rising_edge(clk_i)
		then 
			if write_enable_i = '1'
			then
				x := to_integer(unsigned(pos_x_i));
				y := to_integer(unsigned(pos_y_i)); 
				
				if x <= 80 and y <= 30 
				then 
					offset := 64 * y + 16 * y + x;
					char_memory(offset) <= chr_i;
					color_memory(offset) <= clr_i;
				end if;			
			end if;
		end if;		
	end process;
	
generate_signal: 
	process (clk_i)
		variable divide_by_4 : std_logic_vector(1 downto 0) := "00";
		variable vram_line_base : integer range 0 to 40 * 80 := 0;

	begin				
		if rising_edge(clk_i) 
		then
			case divide_by_4 is				
				when "00" => 
					if next_pixel_x = 799
					then
						-- start of the new line					
						next_pixel_x <= 0;
						if next_pixel_y = 524
						then 
							-- start of the new total frame 
							next_pixel_y <= 0;							
							vram_line_base := 0;
						else
							-- move one line down
							next_pixel_y <= next_pixel_y + 1;

							if gen_y = 15 
							then 
								vram_line_base := vram_line_base + 80;
							end if;
						end if;
					else
						-- move to the next pixel on the line 
						next_pixel_x <= pixel_x + 1;
					end if;

				when "01" => 
					if chr_x < 80 and chr_y < 30 
					then 
						chr <= char_memory(vram_line_base + chr_x);
						clr <= color_memory(vram_line_base + chr_x);
					end if;
				
				when "10" => 
					-- skil clock as we wait for data from ROM
				
				when others => 
				
					if chr_x < 80 and chr_y < 30 and chrg_line(gen_x) = '1' 
					then 
						rgb <= clr;
					else 
						rgb <= x"00";
					end if;
					
					-- Maximum Horizontal count is limited to 799 for 640 x 480 display so that it fit's the screen.						
					if pixel_x = 799
					then
						pixel_x <= 0;
						-- Maximum Vertical count is limited to 524 for	 640 x 480 display so that it fit's the screen.						
						if pixel_y = 524
						then
							pixel_y <= 0;
						else
							pixel_y <= pixel_y + 1;
						end if;
					else
						pixel_x <= pixel_x + 1;
					end if;


					if pixel_y >= 490 and pixel_y < 492 
					then 
						vsync_o <= '0';
					else 
						vsync_o <= '1';
					end if;
					
					if pixel_x >= 656 and pixel_x < 752
					then 
						hsync_o <= '0';
					else
						hsync_o <= '1';
					end if;

					if pixel_x < 640 and pixel_y < 480 
					then 
						red_o <= rgb (7 downto 5);
						green_o <= rgb (4 downto 2);
						blue_o <= rgb (1 downto 0);
					else
						red_o <= "000";
						green_o <= "000";
						blue_o <= "00";
					end if;			
			end case;
					
			divide_by_4 := divide_by_4 + 1;
		end if;
	end process;								
end behavioral;
