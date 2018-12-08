-- Evan Allen, 9/7/2018

library IEEE;
use IEEE.numeric_std.all;

package microcontroller_package is
    constant word_size : NATURAL := 16;
    constant addr_size : NATURAL := word_size;
    constant opcode_size : NATURAL := 7;
    constant reg_addr_size : NATURAL := 3;
    constant num_general_registers : NATURAL := 8;
    constant num_fetch_registers : NATURAL := 2;

    type T_FETCH_TABLE is array(opcode_size - 1 downto 0) of NATURAL;
end microcontroller_package;