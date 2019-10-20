library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.opcodes.all;
use work.types.all;

entity ALU is
	port
	(
		operation			: in alu_opcode_type;
		left_arg			: in std_logic_vector(7 downto 0);
		right_arg			: in std_logic_vector(7 downto 0);
		carry_in			: in std_logic;
		result				: out std_logic_vector(7 downto 0);
		flags				: out ALU_flags
	);
end ALU;


architecture behaviour of ALU is	
begin
	process (left_arg, right_arg, operation, carry_in)
		variable temp : std_logic_vector(8 downto 0);
		variable mask : std_logic_vector(7 downto 0);
	begin
	
		flags.overflow <= '0';

		case operation is
			when ALU_ADD =>
				temp := ('0' & left_arg) + ('0' & right_arg) + ("00000000" & carry_in);
				
				if left_arg(7)=right_arg(7) then 
					flags.overflow <= (left_arg(7) xor temp(7));
				else 
					flags.overflow <= '0';
				end if;
				
			when ALU_SUB =>
				temp := ('0'&left_arg) - ('0'&right_arg) - ("00000000" & carry_in);
				
				if left_arg(7) /= right_arg(7) then 
					flags.overflow <= (left_arg(7) xor temp(7));
				else
					flags.overflow <= '0';
				end if;

-- 			when ALU_NEG =>
-- 				temp :=  0 - ('0'&left_arg);
-- 
			when ALU_OR =>
				temp := carry_in & (left_arg or right_arg);
				
			when ALU_AND =>
				temp := carry_in & (left_arg and right_arg);

			when ALU_XOR =>
				temp := carry_in & (left_arg xor right_arg);
				
-- 			when ALU_NOT =>
-- 				temp := carry_in & (not left_arg);
			
			when ALU_SHR => 
				-- a bit wordy...
				case right_arg is 
					when "00000000" => temp := carry_in & left_arg(7 downto 0); 
					when "00000001" => temp := carry_in & "0" & left_arg(7 downto 1); 
					when "00000010" => temp := carry_in & "00" & left_arg(7 downto 2); 
					when "00000011" => temp := carry_in & "000" & left_arg(7 downto 3); 
					when "00000100" => temp := carry_in & "0000" & left_arg(7 downto 4); 
					when "00000101" => temp := carry_in & "00000" & left_arg(7 downto 5); 
					when "00000110" => temp := carry_in & "000000" & left_arg(7 downto 6); 
					when "00000111" => temp := carry_in & "0000000" & left_arg(7); 
					when others 	=> temp := carry_in & "00000000";
				end case;

			when ALU_SHAR => 
				-- a bit wordy...
				if left_arg(7) = '1' then 
					mask := "11111111";
				else 
					mask := "00000000";
				end if;
				
				case right_arg is 
					when "00000000" => temp := carry_in & left_arg(7 downto 0); 
					when "00000001" => temp := carry_in & mask(7)          & left_arg(7 downto 1); 
					when "00000010" => temp := carry_in & mask(7 downto 6) & left_arg(7 downto 2); 
					when "00000011" => temp := carry_in & mask(7 downto 5) & left_arg(7 downto 3); 
					when "00000100" => temp := carry_in & mask(7 downto 4) & left_arg(7 downto 4); 
					when "00000101" => temp := carry_in & mask(7 downto 3) & left_arg(7 downto 5); 
					when "00000110" => temp := carry_in & mask(7 downto 2) & left_arg(7 downto 6); 
					when "00000111" => temp := carry_in & mask(7 downto 1) & left_arg(7); 
					when others 	=> temp := carry_in & "00000000";
				end case;
			
			when ALU_SHL => 
				-- a bit wordy... also... 
				case right_arg is 
					when "00000000" => temp := carry_in & left_arg(7 downto 0);
					when "00000001" => temp := carry_in & left_arg(6 downto 0) & '0';
					when "00000010" => temp := carry_in & left_arg(5 downto 0) & "00";
					when "00000011" => temp := carry_in & left_arg(4 downto 0) & "000";
					when "00000100" => temp := carry_in & left_arg(3 downto 0) & "0000"; 
					when "00000101" => temp := carry_in & left_arg(2 downto 0) & "00000";
					when "00000110" => temp := carry_in & left_arg(1 downto 0) & "000000";
					when "00000111" => temp := carry_in & left_arg(0) 		  & "0000000";
					when others 	=> temp := carry_in & "00000000";
				end case;

			when ALU_ROR => 
				-- a bit wordy...
				case right_arg(2 downto 0) is 
					when "000" 	=> temp := carry_in & left_arg(7 downto 0); 
					when "001" 	=> temp := carry_in & left_arg(0)           & left_arg(7 downto 1); 
					when "010" 	=> temp := carry_in & left_arg(1 downto 0 ) & left_arg(7 downto 2); 
					when "011" 	=> temp := carry_in & left_arg(2 downto 0 ) & left_arg(7 downto 3); 
					when "100" 	=> temp := carry_in & left_arg(3 downto 0 ) & left_arg(7 downto 4); 
					when "101" 	=> temp := carry_in & left_arg(4 downto 0 ) & left_arg(7 downto 5); 
					when "110" 	=> temp := carry_in & left_arg(5 downto 0 ) & left_arg(7 downto 6); 
					when "111" 	=> temp := carry_in & left_arg(6 downto 0 ) & left_arg(7); 
					when others => temp := carry_in & "00000000";
				end case;
			
			when ALU_ROL => 
				-- a bit wordy... also... 
				case right_arg(2 downto 0) is 
					when "000" 	=> temp := carry_in & left_arg(7 downto 0); 
					when "001" 	=> temp := carry_in & left_arg(7 downto 1) & left_arg(0);
					when "010" 	=> temp := carry_in & left_arg(7 downto 2) & left_arg(1 downto 0);
					when "011" 	=> temp := carry_in & left_arg(7 downto 3) & left_arg(2 downto 0);
					when "100" 	=> temp := carry_in & left_arg(7 downto 4) & left_arg(3 downto 0);
					when "101" 	=> temp := carry_in & left_arg(7 downto 5) & left_arg(4 downto 0);
					when "110" 	=> temp := carry_in & left_arg(7 downto 6) & left_arg(5 downto 0);
					when "111" 	=> temp := carry_in & left_arg(7)          & left_arg(6 downto 0);
					when others => temp := carry_in & "00000000";
				end case;

			
			when ALU_RCR => 
				-- a bit wordy...
				case right_arg(2 downto 0) is 
					when "000" 	=> temp := carry_in & left_arg(7 downto 0); 
					when "001" 	=> temp := left_arg(0)           & carry_in & left_arg(7 downto 1); 
					when "010" 	=> temp := left_arg(1 downto 0 ) & carry_in & left_arg(7 downto 2); 
					when "011" 	=> temp := left_arg(2 downto 0 ) & carry_in & left_arg(7 downto 3); 
					when "100" 	=> temp := left_arg(3 downto 0 ) & carry_in & left_arg(7 downto 4); 
					when "101" 	=> temp := left_arg(4 downto 0 ) & carry_in & left_arg(7 downto 5); 
					when "110" 	=> temp := left_arg(5 downto 0 ) & carry_in & left_arg(7 downto 6); 
					when "111" 	=> temp := left_arg(6 downto 0 ) & carry_in & left_arg(7); 
					when others	=> temp := "000000000";
				end case;
			
			when ALU_RCL => 
				-- a bit wordy... also... 
				case right_arg(2 downto 0) is 
					when "000" 	=> temp := carry_in & left_arg(7 downto 0); 
					when "001" 	=> temp := left_arg(7 downto 1) & carry_in & left_arg(0);
					when "010" 	=> temp := left_arg(7 downto 2) & carry_in & left_arg(1 downto 0);
					when "011" 	=> temp := left_arg(7 downto 3) & carry_in & left_arg(2 downto 0);
					when "100" 	=> temp := left_arg(7 downto 4) & carry_in & left_arg(3 downto 0);
					when "101" 	=> temp := left_arg(7 downto 5) & carry_in & left_arg(4 downto 0);
					when "110" 	=> temp := left_arg(7 downto 6) & carry_in & left_arg(5 downto 0);
					when "111" 	=> temp := left_arg(7)          & carry_in & left_arg(6 downto 0);
					when others => temp := "000000000";
				end case;

						
			when others =>
				temp := "000000000";
		end case;

		if temp(7 downto 0) = "00000000" then 
			flags.zero <= '1';
		else 
			flags.zero <= '0';
		end if;		
		
		flags.carry_out <= temp(8);
		flags.negative <= temp(7);

		result <= temp(7 downto 0);
		
	end process;
	
end behaviour;
