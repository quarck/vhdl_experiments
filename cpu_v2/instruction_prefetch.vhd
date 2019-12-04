library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity instruction_prefetch is 
	port (
		clk_i					: in std_logic;
		reset					: in std_logic;
		enable_i 				: in std_logic;
		next_pc_i				: in std_logic_vector(19 downto 0); 
		valid_bytes_o		 	: out integer range 0 to 6; 
		instruction_register_o	: out std_logic_vector(47 downto 0); -- up to 6 bytes 
		
		mem_address_o			: out std_logic_vector(19 downto 0);
		mem_data_i				: in std_logic_vector(7 downto 0)
	);
end instruction_prefetch;

architecture behavior of instruction_prefetch is 

	type state_type is (IDLE, R1, R2_A0, R3_A1, R4_A2, R5_A3, A4, A5);

	signal state : state_type := IDLE;
	signal valid_bytes : integer range 0 to 6 := 0;
	signal last_pc	: std_logic_vector(19 downto 0) := (others => '0');
	signal ir		: std_logic_vector(47 downto 0) := (others => '0');
begin 

	valid_bytes_o <= valid_bytes;
	instruction_register_o <= ir;

	process (clk_i)
	begin 
		if reset = '1' 
		then
			state <= IDLE;
			valid_bytes <= 0;
			last_pc <= (others => '0');
			ir <=  (others => '0');
			
		elsif rising_edge(clk_i)
		then
		
			case state is 
				when IDLE =>
					if enable_i = '1'
					then
						if next_pc_i /= last_pc or valid_bytes /= 6  
						then 
							valid_bytes <= 0; 
							mem_address_o <= next_pc_i;
							last_pc <= next_pc_i;
							state <= R1;
						end if;				
					else
						state <= IDLE;
					end if;
					
				when R1 =>
					if enable_i = '1'
					then
						if next_pc_i = last_pc
						then 
							mem_address_o <= last_pc + 1;
							state <= R2_A0;
						else 
							valid_bytes <= 0; 
							mem_address_o <= next_pc_i;
							last_pc <= next_pc_i;
							state <= R1;						
						end if;				
					else
						state <= IDLE;
					end if;

				
				when R2_A0 => 
					if enable_i = '1'
					then
						if next_pc_i = last_pc
						then 
							ir(7 downto 0) <= mem_data_i;
							valid_bytes <= 1;
							mem_address_o <= last_pc + 2;
							state <= R3_A1;
						else 
							valid_bytes <= 0; 
							mem_address_o <= next_pc_i;
							last_pc <= next_pc_i;
							state <= R1;						
						end if;				
					else
						state <= IDLE;
					end if;

				when R3_A1 => 
				
					if enable_i = '1'
					then
						if next_pc_i = last_pc
						then 
							ir(15 downto 8) <= mem_data_i;
							valid_bytes <= 2;
							mem_address_o <= last_pc + 3;
							state <= R4_A2;
						else 
							valid_bytes <= 0; 
							mem_address_o <= next_pc_i;
							last_pc <= next_pc_i;
							state <= R1;						
						end if;				
					else
						state <= IDLE;
					end if;
					
				when R4_A2 => 
					if enable_i = '1'
					then
						if next_pc_i = last_pc
						then 
							ir(23 downto 16) <= mem_data_i;
							valid_bytes <= 3;
							mem_address_o <= last_pc + 4;
							state <= R5_A3;
						else 
							valid_bytes <= 0; 
							mem_address_o <= next_pc_i;
							last_pc <= next_pc_i;
							state <= R1;						
						end if;				
					else
						state <= IDLE;
					end if;

				when R5_A3 => 
					if enable_i = '1'
					then
						if next_pc_i = last_pc
						then 
							ir(31 downto 24) <= mem_data_i;
							valid_bytes <= 4;
							mem_address_o <= last_pc + 5;
							state <= A4;
						else 
							valid_bytes <= 0; 
							mem_address_o <= next_pc_i;
							last_pc <= next_pc_i;
							state <= R1;						
						end if;				
					else
						state <= IDLE;
					end if;
					
				when A4 => 
					if enable_i = '1'
					then
						if next_pc_i = last_pc
						then 
							ir(39 downto 32) <= mem_data_i;
							valid_bytes <= 5;
							state <= A5;
						else 
							valid_bytes <= 0; 
							mem_address_o <= next_pc_i;
							last_pc <= next_pc_i;
							state <= R1;						
						end if;				
					else
						state <= IDLE;
					end if;
					
				when A5 => 
					if enable_i = '1'
					then
						if next_pc_i = last_pc
						then 
							ir(47 downto 40) <= mem_data_i;
							valid_bytes <= 6;
							state <= IDLE;
						else 
							valid_bytes <= 0; 
							mem_address_o <= next_pc_i;
							last_pc <= next_pc_i;
							state <= R1;						
						end if;				
					else
						state <= IDLE;
					end if;

			end case;
			
		end if; -- if rising_edge
		
	end process;

end behavior;