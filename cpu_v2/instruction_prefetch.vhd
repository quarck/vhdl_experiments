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

	type state_type is (
		IDLE, 
		R1, 
		R2, R2_A0, 
		R3, R3_A1, 
		R4, R4_A2, 
		R5, R5_A3, 
		W5,
		A4, 
		A5
	);

	signal state : state_type := IDLE;
	signal valid_bytes : integer range 0 to 6 := 0;
	signal last_pc	: std_logic_vector(19 downto 0) := (others => '0');
	signal ir		: std_logic_vector(47 downto 0) := (others => '0');
begin 

	valid_bytes_o <= valid_bytes;
	instruction_register_o <= ir;

	process (clk_i)
		variable pc_delta: integer;
	begin 
		if reset = '1' 
		then
			state <= IDLE;
			valid_bytes <= 0;
			last_pc <= (others => '0');
			ir <=  (others => '0');
			
		elsif rising_edge(clk_i)
		then
			if enable_i = '0' then 
				state <= IDLE; 
			elsif next_pc_i /= last_pc 
			then 
				pc_delta := to_integer(unsigned(next_pc_i)) - to_integer(unsigned(last_pc)); 
				
				if pc_delta > 0 and pc_delta < valid_bytes 
				then 
					-- shuffle over the 'ir' and valid_bytes
					valid_bytes <= valid_bytes - pc_delta;

					case pc_delta is
						when 1 => 	ir(39 downto 0) <= ir(47 downto 8); 
						when 2 => 	ir(31 downto 0) <= ir(47 downto 16); -- 
						when 3 =>  	ir(23 downto 0) <= ir(47 downto 24); -- 
						when 4 => 	ir(15 downto 0) <= ir(47 downto 32); -- 
						when 5 => 	ir(7 downto 0) <= ir(47 downto 40); -- 
						when others => -- should not happen 
					end case;				
					
					-- issue then new read instructions
					mem_address_o <= next_pc_i + valid_bytes - pc_delta;
					last_pc <= next_pc_i;
					
					case valid_bytes - pc_delta is 
						when 1 => state <= R2; -- we are reading R1 now, next - read R2  
						when 2 => state <= R3;
						when 3 => state <= R4;
						when 4 => state <= R5;
						when 5 => state <= W5;
						when others => state <= IDLE; -- should not happen 
					end case;

				else 
					valid_bytes <= 0; 
					mem_address_o <= next_pc_i;
					last_pc <= next_pc_i;
					state <= R1;
				end if;
				
			else -- thus next_pc_i = last_pc - didn't change 
			
				case state is 
					when IDLE =>
						mem_address_o <= last_pc + valid_bytes;
						case valid_bytes is
							when 0 =>  state <= R1;  
							when 1 =>  state <= R2;  
							when 2 =>  state <= R3;
							when 3 =>  state <= R4;
							when 4 =>  state <= R5;
							when 5 =>  state <= W5;
							when others =>  state <= IDLE;
						end case;
						
					when R1 =>
						mem_address_o <= last_pc + 1;
						valid_bytes <= 0; 
						state <= R2_A0;
					
					when R2 => 
						mem_address_o <= last_pc + 2;
						state <= R3_A1;
					when R2_A0 => 
						ir(7 downto 0) <= mem_data_i;
						valid_bytes <= 1;
						mem_address_o <= last_pc + 2;
						state <= R3_A1;

					when R3 =>
						mem_address_o <= last_pc + 3;
						state <= R4_A2;
					when R3_A1 => 					
						ir(15 downto 8) <= mem_data_i;
						valid_bytes <= 2;
						mem_address_o <= last_pc + 3;
						state <= R4_A2;
						
					when R4 => 
						mem_address_o <= last_pc + 4;
						state <= R5_A3;
					when R4_A2 => 
						ir(23 downto 16) <= mem_data_i;
						valid_bytes <= 3;
						mem_address_o <= last_pc + 4;
						state <= R5_A3;

					when R5 => 
						mem_address_o <= last_pc + 5;
						state <= A4;
					when R5_A3 => 
						ir(31 downto 24) <= mem_data_i;
						valid_bytes <= 4;
						mem_address_o <= last_pc + 5;
						state <= A4;
						
					when A4 => 
						ir(39 downto 32) <= mem_data_i;
						valid_bytes <= 5;
						state <= A5;
						
					when W5 => 
						state <= A5;
					when A5 => 
						ir(47 downto 40) <= mem_data_i;
						valid_bytes <= 6;
						state <= IDLE;

				end case;
			
			end if; -- else for enable_i = '0'
			
		end if; -- if rising_edge
		
	end process;

end behavior;