--      Register File
--      Evan Allen, 7/19/2018, 3:02PM

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use microcontroller_package.all;

entity register_file is
    port (
        i_raddr1 : in STD_LOGIC_VECTOR(2 downto 0); -- First address to be read
        i_raddr2 : in STD_LOGIC_VECTOR(2 downto 0); -- Second address to be read
        i_waddr : in STD_LOGIC_VECTOR(2 downto 0); -- Address to be written to
        i_data : in T_WORD; -- Data to write to register at `i_waddr`
        i_rw : in STD_LOGIC; -- '0' => read, '1' => write
        o_data1 : out T_WORD; -- Contents of address @ first register
        o_data2 : out T_WORD -- Contents of address @ second register
        );
end register_file;

architecture behavioral of register_file is
    type REGISTER_FILE_T is array(0 to num_general_registers - 1) of STD_LOGIC_VECTOR(word_size-1 downto 0); -- r0, r1, ..., r6, r7
    signal registers : REGISTER_FILE_T := (others => (0 => '1', others => '0'));
begin
    process (i_rw, i_waddr, i_data)
    begin
        if (i_rw = '1') then
            registers(to_integer(unsigned(i_waddr))) <= i_data;
        --else
            --registers <= (others => "ZZZZZZZZ");
        end if;
    end process;

    o_data1 <= registers(to_integer(unsigned(i_raddr1)));
    o_data2 <= registers(to_integer(unsigned(i_raddr2)));
end behavioral;