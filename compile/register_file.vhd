-------------------------------------------------------------------------------
--
-- Title       : 
-- Design      : Microcontroller
-- Author      : Evan
-- Company     : Old Dominion University
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Aldec_Designs\test_workspace\Microcontroller\compile\register_file.vhd
-- Generated   : Fri Jan  4 17:38:50 2019
-- From        : c:\My_Aldec_Designs\test_workspace\Microcontroller\src\register_file.bde
-- By          : Bde2Vhdl ver. 2.6
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
-- Design unit header --
library microcontroller;
        use microcontroller.microcontroller_package.all;
library ieee;
        use ieee.std_logic_1164.all;
        use ieee.NUMERIC_STD.all;

entity register_file is
  port(
       i_rw : in STD_LOGIC;
       i_data : in STD_LOGIC_VECTOR(word_size - 1 downto 0);
       i_raddr1 : in STD_LOGIC_VECTOR(2 downto 0);
       i_raddr2 : in STD_LOGIC_VECTOR(2 downto 0);
       i_waddr : in STD_LOGIC_VECTOR(2 downto 0);
       o_data1 : out STD_LOGIC_VECTOR(word_size - 1 downto 0);
       o_data2 : out STD_LOGIC_VECTOR(word_size - 1 downto 0)
  );
end register_file;

architecture behavioral of register_file is

---- Architecture declarations -----
--Added by Active-HDL. Do not change code inside this section.
type REGISTER_FILE_T is array (0 to num_general_registers - 1) of STD_LOGIC_VECTOR(word_size - 1 downto 0);
--End of extra code.


---- Signal declarations used on the diagram ----

signal registers : REGISTER_FILE_T := (others => (0 => '1', others => '0'));

begin

---- Processes ----

process (i_rw,i_waddr)
                       begin
                         if (i_rw = '1') then
                            registers(to_integer(unsigned(i_waddr))) <= i_data;
                         end if;
                       end process;
                      

---- User Signal Assignments ----
o_data1 <= registers(to_integer(unsigned(i_raddr1)));
o_data2 <= registers(to_integer(unsigned(i_raddr2)));

end behavioral;
