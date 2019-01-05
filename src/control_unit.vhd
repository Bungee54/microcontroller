-------------------------------------------------------------------------------
--
-- Title       : control_unit
-- Design      : Microcontroller
-- Author      : Evan
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use microcontroller_package.all;

entity control_unit is
    port (
        i_clk : in STD_LOGIC;
        i_rst : in STD_LOGIC;
        i_BUS0 : in T_WORD;
        i_BUS1 : in T_WORD;

        i_FLAG_CARRY : in STD_LOGIC;
        i_FLAG_OVERFLOW : in STD_LOGIC;
        i_FLAG_NEGATIVE : in STD_LOGIC;
        i_FLAG_ZERO : in STD_LOGIC;

        i_num_fetches : in UNSIGNED(1 downto 0);
        out_opcode7 : out T_OPCODE;

        out_BUS0_sel : out T_BUS_SELECT;
        out_BUS1_sel : out T_BUS_SELECT;

        out_ALU_loadA : out T_LOAD;
        out_ALU_loadB : out T_LOAD;
        out_RAM_loadAddr : out T_LOAD;
        out_RAM_loadData : out T_LOAD;
        out_regf_loadWData : out T_LOAD;

        out_ALU_sel : out T_ALU_SELECT;
        out_regf_raddr1 : out T_REGF_ADDR;
        out_regf_raddr2 : out T_REGF_ADDR;
        out_regf_waddr : out T_REGF_ADDR;
        out_regf_rw : out STD_LOGIC;
        out_ROM_addr : out T_WORD
        );
end control_unit;

architecture control_unit of control_unit is

    signal ctrl_state : T_CPU_STATE;
    signal ctrl_substate : T_SUBSTATE;
    signal ctrl_fetches_remaining : UNSIGNED(1 downto 0);
    signal ctrl_fetches_completed : UNSIGNED(1 downto 0);

    signal ctrl_ROM_addr : T_WORD;

    signal r_status : STD_LOGIC_VECTOR(7 downto 0); -- Status register (zero, carry, neg, overflow, TBD, TBD, TBD, TBD) <- word_size - 1 downto 0
    signal r_pc : T_WORD; -- Program counter

    signal r_ir : T_WORD; -- Instruction register

    signal ir_opcode : T_OPCODE; -- Points to opcode section of r_ir (first few bits of instruction)

    -- Points to section of r_ir (instruction register) storing each register argument
    signal ir_addr_rA : T_REGF_ADDR;
    signal ir_addr_rB : T_REGF_ADDR;
    signal ir_addr_rC : T_REGF_ADDR;

    signal r_fetch : T_FETCH_REGFILE; -- Holds extra information such as immediate addresses and their contents
                                                   -- Space for 2 words of information.

    -- Used to load a value from a bus onto a component in the main CPU (but not
    -- in the main control unit, since this module has direct access to the bus
    -- signals). Establishes a real-time connection; does not need to wait for
    -- the clock signal for the component specified by `loading_signal` to load
    -- the bus's value.
    procedure CONNECT_FROM_BUS (bus_num : in STD_LOGIC; signal loading_signal : out T_LOAD) is
    begin
        if (bus_num = '0') then
            loading_signal(0) <= '0';
        else
            loading_signal(0) <= '1';
        end if;
        loading_signal(1) <= '1';
    end CONNECT_FROM_BUS;

    -- Stop updating a component with values from a bus.
    procedure DISCONNECT_FROM_BUS (signal loading_signal : out T_LOAD) is
    begin
        loading_signal(1) <= '0';
    end DISCONNECT_FROM_BUS;

    -- Procedure that conducts a computation in which two registers send values
    -- to the ALU, and the result is put into the second.
    -- The first argument specifies which ALU operation to complete; the rest
    -- are simply to allow the procedure's function.
    procedure REG_REG_ALU_OPERATION (
        ALU_selector : in T_ALU_SELECT;
        signal ctrl_substate : inout T_SUBSTATE;
        ir_addr_rA : in T_REGF_ADDR;
        ir_addr_rB : in T_REGF_ADDR;
        signal out_regf_raddr1 : out T_REGF_ADDR;
        signal out_regf_raddr2 : out T_REGF_ADDR;
        signal out_regf_waddr : OUT T_REGF_ADDR;
        signal out_BUS0_sel : out T_BUS_SELECT;
        signal out_BUS1_sel : out T_BUS_SELECT;
        signal out_ALU_loadA : out T_LOAD;
        signal out_ALU_loadB : out T_LOAD;
        signal out_ALU_sel : out T_ALU_SELECT;
        signal out_regf_loadWData : out T_LOAD;
        signal out_regf_rw : out STD_LOGIC;
        signal ctrl_state : out T_CPU_STATE
    ) is
    begin
        if (ctrl_substate = 0) then
            out_regf_raddr1 <= ir_addr_rA; -- Ask regfile for the registers we need
            out_regf_raddr2 <= ir_addr_rB;
            out_BUS0_sel <= SEL_REGF_RDATA1; -- Put those registers' data on buses
            out_BUS1_sel <= SEL_REGF_RDATA2;
            CONNECT_FROM_BUS('0', out_ALU_loadA); -- Connect ALU inputs to buses
            CONNECT_FROM_BUS('1', out_ALU_loadB);
            out_ALU_sel <= ALU_selector; -- Tell ALU which operation to execute
            out_regf_waddr <= ir_addr_rB; -- Tell regfile where to put result
            ctrl_substate <= 1; -- Next state
        elsif (ctrl_substate = 1) then
            DISCONNECT_FROM_BUS(out_ALU_loadA); -- Clean up
            DISCONNECT_FROM_BUS(out_ALU_loadB);
            out_BUS0_sel <= SEL_ALU_OUT; -- Put ALU output on bus
            CONNECT_FROM_BUS('0', out_regf_loadWData); -- Connect regfile to that bus
            out_regf_rw <= '1'; -- Write it!
            ctrl_substate <= 2;
        elsif (ctrl_substate = 2) then
            DISCONNECT_FROM_BUS(out_regf_loadWData); -- Clean up
            out_regf_rw <= '0';
            ctrl_substate <= 0;
            ctrl_state <= FETCH_REQ_INSTRUCTION; -- Back to the beginning!
        end if;
    end REG_REG_ALU_OPERATION;

begin

    ir_opcode <= r_ir((r_ir'left) downto (r_ir'left - (opcode_size - 1)));
    out_opcode7 <= ir_opcode;

    -- Just points to different registers in ir_opcode. See
    -- instruction specification for more details.
    ir_addr_rA <= r_ir(reg_addr_size*3 - 1 downto reg_addr_size*2);
    ir_addr_rB <= r_ir(reg_addr_size*2 - 1 downto reg_addr_size);
    ir_addr_rC <= r_ir(reg_addr_size - 1   downto 0);

    out_ROM_addr <= ctrl_ROM_addr;

    RUN : process (i_clk, i_rst)
    begin
        -------------------------------------------------------------------------------------
        -- RESET logic (active low; in case of power loss, for example).
        -------------------------------------------------------------------------------------
        if (falling_edge(i_rst)) then
            out_BUS0_sel <= SEL_ALU_OUT;
            out_BUS1_sel <= SEL_ALU_OUT;
            out_ALU_loadA <= (others => '0');
            out_ALU_loadB <= (others => '0');
            out_RAM_loadAddr <= (others => '0');
            out_RAM_loadData <= (others => '0');
            out_regf_loadWData <= (others => '0');

            out_ALU_sel <= SEL_ADD;
            out_regf_raddr1 <= (others => '0');
            out_regf_raddr2 <= (others => '0');
            out_regf_waddr <= (others => '0');
            out_regf_rw <= '0';

            ctrl_state <= FETCH_REQ_INSTRUCTION;
            ctrl_substate <= 0;
            ctrl_fetches_remaining <= to_unsigned(0, 2);
            ctrl_fetches_completed <= to_unsigned(0, 2);
            ctrl_ROM_addr <= (others => '0');
            r_status <= (others => '0');
            r_pc <= (others => '0');
            r_ir <= (others => '0');
            r_fetch <= (others => (others => '0'));


        -------------------------------------------------------------------------------------
        --
        -- CPU CONTROL LOGIC
        --
        -------------------------------------------------------------------------------------
        elsif (rising_edge(i_clk)) then
            case ctrl_state is

                when HALT => NULL;-- Do nothing; we're done!

                -------------------------------------------------------------------------------------
                -- FETCH Phase
                -------------------------------------------------------------------------------------
                when FETCH_REQ_INSTRUCTION =>
                    ctrl_ROM_addr <= r_pc;                 -- Ask ROM for instruction
                    out_BUS0_sel <= SEL_ROM_DATA;
                    r_pc <= T_WORD( unsigned(r_pc) + 1 );
                    ctrl_state <= FETCH_READ_INSTRUCTION;
                when FETCH_READ_INSTRUCTION =>
                    r_ir <= i_BUS0;                       -- Read instruction from ROM next cycle and prepare to decode
                    ctrl_fetches_remaining <= i_num_fetches;
                    ctrl_fetches_completed <= to_unsigned(0, ctrl_fetches_completed'length);
                    if (ctrl_fetches_remaining = 0) then
                        ctrl_state <= EXECUTE_INSTRUCTION;
                    else
                        ctrl_state <= DECODE_REQ_EXTENSION;
                    end if;

                -------------------------------------------------------------------------------------
                -- DECODE Phase
                -------------------------------------------------------------------------------------
                when DECODE_REQ_EXTENSION =>
                    ctrl_ROM_addr <= T_WORD( unsigned(ctrl_ROM_addr) + 1); -- NOT r_pc; We're just looking for the next word
                    out_BUS0_sel <= SEL_ROM_DATA;
                    ctrl_state <= DECODE_READ_EXTENSION;
                when DECODE_READ_EXTENSION =>
                    r_fetch(to_integer(ctrl_fetches_completed)) <= i_BUS0; -- Load extension word into fetch register
                    ctrl_fetches_completed <= ctrl_fetches_completed + 1; -- Needed to move to next fetch register
                    ctrl_fetches_remaining <= ctrl_fetches_remaining - 1;
                    if (ctrl_fetches_remaining = 0) then
                        ctrl_state <= EXECUTE_INSTRUCTION;
                    else
                        ctrl_state <= DECODE_REQ_EXTENSION;
                    end if;

                -------------------------------------------------------------------------------------
                -- EXECUTE Phase
                -------------------------------------------------------------------------------------
                when EXECUTE_INSTRUCTION =>
                        case ir_opcode is

                            -- ADD rA, rB
                            when "00000" & "00" =>
                                REG_REG_ALU_OPERATION(
                                    SEL_ADD,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, ctrl_state);

                            -- SUB rA, rB
                            when "00001" & "00" =>
                                REG_REG_ALU_OPERATION(
                                    SEL_SUB,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, ctrl_state);

                            -- HALT
                            when "11111" & "00" =>
                                ctrl_state <= HALT;

                            when others =>                      -- Nothing
                        end case;

                when others => -- Nothing

            end case;
        end if;
    end process RUN;


end control_unit;
