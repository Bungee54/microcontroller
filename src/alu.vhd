--      Arithmetic Logic Unit (ALU)
--      Evan Allen, 7/19/2018, 1:22PM

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use microcontroller_package.all;

entity ALU is
    port (
        A : in STD_LOGIC_VECTOR(word_size - 1 downto 0);
        B : in STD_LOGIC_VECTOR(word_size - 1 downto 0);
        OPCODE : in STD_LOGIC_VECTOR(3 downto 0);
        Y : out STD_LOGIC_VECTOR(word_size - 1 downto 0);
        FLAG_CARRY : out STD_LOGIC;
        FLAG_OVERFLOW : out STD_LOGIC;
        FLAG_NEGATIVE : out STD_LOGIC;
        FLAG_ZERO : out STD_LOGIC
        );
end ALU;

architecture behavioral of ALU is
    signal Y_ext : STD_LOGIC_VECTOR(Y'length downto 0); -- Contains one more bit than Y for carry detection
begin
    COMPUTE : process (A, B, OPCODE)
    begin
        case OPCODE is
            when "0000" => Y_ext <= ('0' & A) + B; -- Add
                           Y <= A + B;
            when "0001" => Y_ext <= ('0' & A) + ((not B) + 1); -- Subtract
                           Y <= A + (not B) + 1;
            when "0010" => Y <= (not A) + 1; -- Negate (2's Complement)
            when "0011" => Y <= A + 1; -- Increment
            when "0100" => Y <= A - 1; -- Decrement
            when "0101" => Y <= A;     -- Pass Thru
            when "0110" => Y <= A and B; -- AND
            when "0111" => Y <= A or B; -- OR
            when "1000" => Y <= A xor B; -- XOR
            when "1001" => Y <= not A; -- NOT
            when "1010" => Y <= shl(A, B); -- Shift Left
            when "1011" => Y <= shr(A, B); -- Shift Right
            when others => NULL;
        end case;
    end process COMPUTE;

    SET_FLAGS : process (Y, Y_ext, OPCODE)
    begin
        if (OPCODE = "0000" or OPCODE = "0001") then
            FLAG_CARRY <= Y_ext(Y_ext'left);
            if ((A(A'left) = B(B'left)) and (Y(Y'left) /= A(A'left))) then
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

        if (Y(Y'left) = '1') then
            FLAG_NEGATIVE <= '1';
        else
            FLAG_NEGATIVE <= '0';
        end if;
    end process SET_FLAGS;
end behavioral;