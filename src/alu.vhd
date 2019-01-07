--      Arithmetic Logic Unit (ALU)
--      Evan Allen, 7/19/2018, 1:22PM

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
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
    subtype T_WORD_EXT is STD_LOGIC_VECTOR(Y'length downto 0);
    signal Y_ext : T_WORD_EXT; -- Contains one more bit than Y for carry detection
begin
    COMPUTE : process (A, B, SEL)
    begin
        case SEL is
            when SEL_ADD  => Y_ext <= T_WORD_EXT( unsigned('0' & A) + unsigned('0' & B) ); -- Add
                             Y <= T_WORD( unsigned(A) + unsigned(B) );
            when SEL_SUB  => Y_ext <= T_WORD_EXT( unsigned('0' & A) + unsigned(not ('0' & B)) + 1 ); -- Subtract
                             Y <= T_WORD( unsigned(A) + unsigned(not B) + 1 );
            when SEL_NEG  => Y <= T_WORD( unsigned(not A) + 1); -- Negate (2's Complement)
            when SEL_INC  => Y <= T_WORD( unsigned(A) + 1 ); -- Increment
            when SEL_DEC  => Y <= T_WORD( unsigned(A) - 1 ); -- Decrement
            when SEL_PASS => Y <= A;     -- Pass Thru
            when SEL_AND  => Y <= A and B; -- AND
            when SEL_OR   => Y <= A or B; -- OR
            when SEL_XOR  => Y <= A xor B; -- XOR
            when SEL_NOT  => Y <= not A; -- NOT
            when SEL_LSL  => Y <= T_WORD( shift_left( unsigned(A), to_integer(unsigned(B))) ); -- Logical Shift Left
            when SEL_LSR  => Y <= T_WORD( shift_right( unsigned(A), to_integer(unsigned(B))) ); -- Logical Shift Right
            when SEL_ASR  => Y <= T_WORD( shift_right( signed(A), to_integer(unsigned(B))) ); -- Arithmetic Shift Right
            when others => NULL;
        end case;
    end process COMPUTE;

    SET_FLAGS : process (Y, Y_ext, SEL)
    begin
        if (SEL = SEL_ADD) then
            FLAG_CARRY <= Y_ext(Y_ext'left);
            if ((A(A'left) = B(B'left)) and (Y(Y'left) /= A(A'left))) then
                FLAG_OVERFLOW <= '1';
            else
                FLAG_OVERFLOW <= '0';
            end if;
        elsif (SEL = SEL_SUB) then -- Separate case because we need to negate B before checking
            FLAG_CARRY <= Y_ext(Y_ext'left);
            if ((A(A'left) /= B(B'left)) and (Y(Y'left) /= A(A'left))) then
                FLAG_OVERFLOW <= '1';
            else
                FLAG_OVERFLOW <= '0';
            end if;
        else
            FLAG_CARRY <= '0';
            FLAG_OVERFLOW <= '0';
        end if;

        if (unsigned(Y) = 0) then
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