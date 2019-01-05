--      Arithmetic Logic Unit (ALU)
--      Evan Allen, 7/19/2018, 1:22PM

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use microcontroller_package.all;

entity ALU is
    port (
        A : in T_WORD;
        B : in T_WORD;
        SEL : in T_ALU_SELECT;
        Y : out T_WORD;
        FLAG_CARRY : out STD_LOGIC;
        FLAG_OVERFLOW : out STD_LOGIC;
        FLAG_NEGATIVE : out STD_LOGIC;
        FLAG_ZERO : out STD_LOGIC
        );
end ALU;

architecture behavioral of ALU is
    signal Y_ext : STD_LOGIC_VECTOR(Y'length downto 0); -- Contains one more bit than Y for carry detection
begin
    COMPUTE : process (A, B, SEL)
    begin
        case SEL is
            when SEL_ADD  => Y_ext <= ('0' & A) + B; -- Add
                             Y <= A + B;
            when SEL_SUB  => Y_ext <= ('0' & A) + ((not B) + 1); -- Subtract
                             Y <= A + (not B) + 1;
            when SEL_NEG  => Y <= (not A) + 1; -- Negate (2's Complement)
            when SEL_INC  => Y <= A + 1; -- Increment
            when SEL_DEC  => Y <= A - 1; -- Decrement
            when SEL_PASS => Y <= A;     -- Pass Thru
            when SEL_AND  => Y <= A and B; -- AND
            when SEL_OR   => Y <= A or B; -- OR
            when SEL_XOR  => Y <= A xor B; -- XOR
            when SEL_NOT  => Y <= not A; -- NOT
            when SEL_SHL  => Y <= shl(A, B); -- Shift Left
            when SEL_SHR   => Y <= shr(A, B); -- Shift Right
        end case;
    end process COMPUTE;

    SET_FLAGS : process (Y, Y_ext, SEL)
    begin
        if (SEL = SEL_ADD or SEL = SEL_SUB) then
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