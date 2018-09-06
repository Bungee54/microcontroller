-------------------------------------------------------------------------------
--
-- Title       : 
-- Design      : Microcontroller
-- Author      : Evan
-- Company     : Old Dominion University
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Aldec_Designs\test_workspace\Microcontroller\compile\ALU.vhd
-- Generated   : Tue Jul 31 22:58:22 2018
-- From        : c:\My_Aldec_Designs\test_workspace\Microcontroller\graphics\ALU.bde
-- By          : Bde2Vhdl ver. 2.6
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
-- Design unit header --
library ieee;
        use ieee.std_logic_1164.all;
        use ieee.STD_LOGIC_UNSIGNED.all;

entity ALU is
  port(
       A : in STD_LOGIC_VECTOR(7 downto 0);
       B : in STD_LOGIC_VECTOR(7 downto 0);
       OPCODE : in STD_LOGIC_VECTOR(3 downto 0);
       FLAG_CARRY : out STD_LOGIC;
       FLAG_NEGATIVE : out STD_LOGIC;
       FLAG_OVERFLOW : out STD_LOGIC;
       FLAG_ZERO : out STD_LOGIC;
       Y : out STD_LOGIC_VECTOR(7 downto 0)
  );
end ALU;

architecture behavioral of ALU is

---- Signal declarations used on the diagram ----

signal Y_ext : STD_LOGIC_VECTOR(Y'length downto 0);

begin

---- Processes ----

COMPUTE : process (A,B,OPCODE)
                       begin
                         case OPCODE is 
                           when "0000" => 
                              Y_ext <= ('0' & A) + B;
                              Y <= A + B;
                           when "0001" => 
                              Y_ext <= ('0' & A) + ((not B) + 1);
                              Y <= A + (not B) + 1;
                           when "0010" => 
                              Y <= (not A) + 1;
                           when "0011" => 
                              Y <= A + 1;
                           when "0100" => 
                              Y <= A - 1;
                           when "0101" => 
                              Y <= A;
                           when "0110" => 
                              Y <= A and B;
                           when "0111" => 
                              Y <= A or B;
                           when "1000" => 
                              Y <= A xor B;
                           when "1001" => 
                              Y <= not A;
                           when "1010" => 
                              Y <= shl(A,B);
                           when "1011" => 
                              Y <= shr(A,B);
                           when others => 
                              null;
                         end case;
                       end process;
                      

SET_FLAGS : process (Y,Y_ext,OPCODE)
                       begin
                         if (OPCODE = "0000" or OPCODE = "0001") then
                            FLAG_CARRY <= Y_ext(Y_ext'left);
                            if ((A(7) = B(7)) and (Y(7) /= A(7))) then
                               FLAG_OVERFLOW <= '1';
                            else 
                               FLAG_OVERFLOW <= '0';
                            end if;
                         else 
                            FLAG_CARRY <= '0';
                            FLAG_OVERFLOW <= '0';
                         end if;
                         if (Y = 0) then
                            FLAG_ZERO <= '1';
                         else 
                            FLAG_ZERO <= '0';
                         end if;
                         if (Y(7) = '1') then
                            FLAG_NEGATIVE <= '1';
                         else 
                            FLAG_NEGATIVE <= '0';
                         end if;
                       end process;
                      

end behavioral;
