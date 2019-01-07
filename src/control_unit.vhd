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
        out_fetchLUT_load : out T_LOAD;

        out_ALU_sel : out T_ALU_SELECT;
        out_regf_raddr1 : out T_REGF_ADDR;
        out_regf_raddr2 : out T_REGF_ADDR;
        out_regf_waddr : out T_REGF_ADDR;
        out_regf_rw : out STD_LOGIC;
        out_RAM_rw : out STD_LOGIC;
        out_ROM_addr : out T_WORD;

        out_fetched_word : out T_WORD
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
    -- !!! REMEMBER to DISCONNECT things you CONNECT (see `DISCONNECT_FROM_BUS`) !!!
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

    -- Procedure that conducts a computation between a register and register/number
    -- (or nothing else) and stores the result in the original register.
    -- Works for instructions that take as arguments:
    --      -> REGISTER and REGISTER        (argset = ARGSET_REG_REG)
    --      -> REGISTER and NUMBER          (argset = ARGSET_REG_NUM)
    --      -> REGISTER (by itself)         (argset = ARGSET_REG)
    -- The first argument of this procedure specifies which ALU operation to
    -- complete, the second specifies what sort of arguments the instruction takes;
    -- the rest are simply to allow the procedure's function.
    procedure ALU_OPERATION (
        ALU_selector : in T_ALU_SELECT;
        argset : in T_ARGSET;
        signal ctrl_substate : inout T_SUBSTATE;
        ir_addr_rA : in T_REGF_ADDR;
        ir_addr_rB : in T_REGF_ADDR;
        r_fetch : in T_FETCH_REGFILE;
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
        signal out_fetched_word : out T_WORD;
        signal ctrl_state : out T_CPU_STATE
    ) is
    begin
        if (ctrl_substate = 0) then

            -- Load first argument onto bus.
            out_regf_raddr1 <= ir_addr_rA;  -- Tell regfile which register we want
            out_BUS0_sel <= SEL_REGF_RDATA1; -- Connect bus to that register
            CONNECT_FROM_BUS('0', out_ALU_loadA); -- Connect ALU input A to bus

            -- Load second argument onto bus and put into ALU (input B).
            -- Implementation depends on which arguments we have!
            case argset is
                when ARGSET_REG_REG => -- As above for a second register
                    out_regf_raddr2 <= ir_addr_rB;
                    out_BUS1_sel <= SEL_REGF_RDATA2;
                    CONNECT_FROM_BUS('1', out_ALU_loadB);
                when ARGSET_REG_NUM => -- Use the NUMBER in a fetch register instead.
                    out_fetched_word <= r_fetch(0);
                    out_BUS1_sel <= SEL_FETCH_REG;
                    CONNECT_FROM_BUS('1', out_ALU_loadB);
                when ARGSET_REG => -- We have no second argument to load!
                    NULL;
            end case;

            out_ALU_sel <= ALU_selector; -- Tell ALU which operation to execute
            out_regf_waddr <= ir_addr_rA; -- Tell regfile where to put result
            ctrl_substate <= 1; -- Next state

        elsif (ctrl_substate = 1) then
            DISCONNECT_FROM_BUS(out_ALU_loadA); -- Clean up
            DISCONNECT_FROM_BUS(out_ALU_loadB); -- This is okay even with ARGSET_REG
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
    end ALU_OPERATION;

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
                    CONNECT_FROM_BUS('0', out_fetchLUT_load); -- This is so we can retrieve the # of fetches next cycle
                    ctrl_state <= FETCH_READ_INSTRUCTION;
                when FETCH_READ_INSTRUCTION =>
                    DISCONNECT_FROM_BUS(out_fetchLUT_load);
                    r_ir <= i_BUS0;                       -- Read instruction from ROM next cycle and prepare to decode.
                    if (i_num_fetches = 0) then             -- MUST reference i_num_fetches AND NOT ctrl_fetches_remaining
                        ctrl_state <= EXECUTE_INSTRUCTION;  -- since ctrl_fetches_remaining is set this clock cycle.
                    else
                        ctrl_state <= DECODE_REQ_EXTENSION;
                    end if;
                    ctrl_fetches_remaining <= i_num_fetches;
                    ctrl_fetches_completed <= to_unsigned(0, ctrl_fetches_completed'length);
                    r_pc <= T_WORD( unsigned(r_pc) + 1 + i_num_fetches); -- See above; CANNOT use ctrl_fetches_remaining


                -------------------------------------------------------------------------------------
                -- DECODE Phase
                -------------------------------------------------------------------------------------
                when DECODE_REQ_EXTENSION =>
                    ctrl_ROM_addr <= T_WORD( unsigned(ctrl_ROM_addr) + 1); -- NOT r_pc; We're just looking for the next word
                    out_BUS0_sel <= SEL_ROM_DATA;
                    ctrl_state <= DECODE_READ_EXTENSION;
                when DECODE_READ_EXTENSION =>
                    r_fetch(to_integer(ctrl_fetches_completed)) <= i_BUS0; -- Load extension word into fetch register
                    if (ctrl_fetches_remaining - 1 = 0) then -- REMEMBER that this uses ctrl_fetches_remaining's value BEFORE it's decremented
                        ctrl_state <= EXECUTE_INSTRUCTION;
                    else
                        ctrl_state <= DECODE_REQ_EXTENSION;
                    end if;
                    ctrl_fetches_completed <= ctrl_fetches_completed + 1; -- Even though we update these, we won't see that until next cycle
                    ctrl_fetches_remaining <= ctrl_fetches_remaining - 1;


                -------------------------------------------------------------------------------------
                -- EXECUTE Phase
                -- ALL INSTRUCTION IMPLEMENTATIONS FOUND HERE
                -- !!! LONG SECTION BEWARE !!!
                -------------------------------------------------------------------------------------
                when EXECUTE_INSTRUCTION =>
                        case ir_opcode is

                            -- !!! Most of these instructions call the ALU_OPERATION procedure. !!!
                            -- !!! Because of the way VHDL handles procedures, I had to include !!!
                            -- !!! all the signals it uses in each procedure call (hence why    !!!
                            -- !!! they're so long), but the only arguments that MATTER are the !!!
                            -- !!! `ALU_selector` (first) and `argset` (second) arguments to    !!!
                            -- !!! specify which instruction to execute and how. These are      !!!
                            -- !!! placed on the first line of the procedure call for clarity.  !!!

                            -- ADD rA, rB
                            when "00000" & "00" =>
                                ALU_OPERATION(
                                    SEL_ADD, ARGSET_REG_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- Add rA, NUMBER
                            when "00000" & "01" =>
                                ALU_OPERATION(
                                    SEL_ADD, ARGSET_REG_NUM,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- SUB rA, rB
                            when "00001" & "00" =>
                                ALU_OPERATION(
                                    SEL_SUB, ARGSET_REG_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- SUB rA, NUM
                            when "00001" & "01" =>
                                ALU_OPERATION(
                                    SEL_SUB, ARGSET_REG_NUM,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- NEG rA
                            when "00010" & "00" =>
                                ALU_OPERATION(
                                    SEL_NEG, ARGSET_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- INC rA
                            when "00011" & "00" =>
                                ALU_OPERATION(
                                    SEL_INC, ARGSET_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- DEC rA
                            when "00100" & "00" =>
                                ALU_OPERATION(
                                    SEL_DEC, ARGSET_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- AND rA, rB
                            when "00101" & "00" =>
                                ALU_OPERATION(
                                    SEL_AND, ARGSET_REG_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- AND rA, NUMBER
                            when "00101" & "01" =>
                                ALU_OPERATION(
                                    SEL_AND, ARGSET_REG_NUM,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- OR rA, rB
                            when "00110" & "00" =>
                                ALU_OPERATION(
                                    SEL_OR, ARGSET_REG_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- OR rA, NUMBER
                            when "00110" & "01" =>
                                ALU_OPERATION(
                                    SEL_OR, ARGSET_REG_NUM,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- XOR rA, rB
                            when "00111" & "00" =>
                                ALU_OPERATION(
                                    SEL_XOR, ARGSET_REG_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- XOR rA, NUMBER
                            when "00111" & "01" =>
                                ALU_OPERATION(
                                    SEL_XOR, ARGSET_REG_NUM,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- NOT rA
                            when "01000" & "00" =>
                                ALU_OPERATION(
                                    SEL_NOT, ARGSET_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- LSL rA, rB
                            when "01001" & "00" =>
                                ALU_OPERATION(
                                    SEL_LSL, ARGSET_REG_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- LSL rA, NUMBER
                            when "01001" & "01" =>
                                ALU_OPERATION(
                                    SEL_LSL, ARGSET_REG_NUM,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- LSR rA, rB
                            when "01010" & "00" =>
                                ALU_OPERATION(
                                    SEL_LSR, ARGSET_REG_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- LSR rA, NUMBER
                            when "01010" & "01" =>
                                ALU_OPERATION(
                                    SEL_LSR, ARGSET_REG_NUM,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- ASR rA, rB
                            when "01011" & "00" =>
                                ALU_OPERATION(
                                    SEL_ASR, ARGSET_REG_REG,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- ASR rA, NUMBER
                            when "01011" & "01" =>
                                ALU_OPERATION(
                                    SEL_ASR, ARGSET_REG_NUM,
                                    ctrl_substate, ir_addr_rA, ir_addr_rB, r_fetch, out_regf_raddr1, out_regf_raddr2,
                                    out_regf_waddr, out_BUS0_sel, out_BUS1_sel, out_ALU_loadA, out_ALU_loadB,
                                    out_ALU_sel, out_regf_loadWData, out_regf_rw, out_fetched_word, ctrl_state);

                            -- CMP rA, rB
                            when "01100" & "00" =>
                                -- Acts as a normal ALU subtract operation, but doesn't store the result.
                                -- This is because we only care about the status bits after the computation,
                                -- which are automatically set.
                                -- See procedure ALU_OPERATION above for explanation of the below statements;
                                -- we're just passing two registers to the ALU, telling it to subtract,
                                -- and cleaning up.
                                if (ctrl_substate = 0) then
                                    out_regf_raddr1 <= ir_addr_rA;
                                    out_regf_raddr2 <= ir_addr_rB;
                                    out_BUS0_sel <= SEL_REGF_RDATA1;
                                    out_BUS1_sel <= SEL_REGF_RDATA2;
                                    CONNECT_FROM_BUS('0', out_ALU_loadA);
                                    CONNECT_FROM_BUS('1', out_ALU_loadB);
                                    out_ALU_sel <= SEL_SUB;
                                    ctrl_substate <= 1;
                                elsif (ctrl_substate = 1) then
                                    DISCONNECT_FROM_BUS(out_ALU_loadA);
                                    DISCONNECT_FROM_BUS(out_ALU_loadB);
                                    ctrl_substate <= 0;
                                    ctrl_state <= FETCH_REQ_INSTRUCTION;
                                end if;

                            -- CMP rA, NUMBER
                            when "01100" & "01" =>
                                -- See CMP rA, rB. This works the same, but takes a NUMBER from the fetch
                                -- register instead of a second register argument.
                                if (ctrl_substate = 0) then
                                    out_regf_raddr1 <= ir_addr_rA;
                                    out_BUS0_sel <= SEL_REGF_RDATA1;
                                    out_BUS1_sel <= SEL_FETCH_REG; -- << These two lines are the difference!
                                    out_fetched_word <= r_fetch(0); -- << (this sends the fetched NUMBER to the bus)
                                    CONNECT_FROM_BUS('0', out_ALU_loadA);
                                    CONNECT_FROM_BUS('1', out_ALU_loadB);
                                    out_ALU_sel <= SEL_SUB;
                                    ctrl_substate <= 1;
                                elsif (ctrl_substate = 1) then
                                    DISCONNECT_FROM_BUS(out_ALU_loadA);
                                    DISCONNECT_FROM_BUS(out_ALU_loadB);
                                    ctrl_substate <= 0;
                                    ctrl_state <= FETCH_REQ_INSTRUCTION;
                                end if;

                            -- LDI rA, rB
                            when "01101" & "00" =>
                                if (ctrl_substate = 0) then
                                    -- Send address from rB to RAM
                                    out_regf_raddr1 <= ir_addr_rB;
                                    out_BUS0_sel <= SEL_REGF_RDATA1;
                                    CONNECT_FROM_BUS('0', out_RAM_loadAddr);
                                    -- Connect RAM's data back to destination register rA
                                    out_regf_waddr <= ir_addr_rA;
                                    out_BUS1_sel <= SEL_RAM_DATA;
                                    CONNECT_FROM_BUS('1', out_regf_loadWData);
                                    out_regf_rw <= '1';
                                    ctrl_substate <= 1;
                                elsif (ctrl_substate = 1) then
                                    -- Clean up
                                    DISCONNECT_FROM_BUS(out_RAM_loadAddr);
                                    DISCONNECT_FROM_BUS(out_regf_loadWData);
                                    out_regf_rw <= '0';
                                    ctrl_substate <= 0;
                                    ctrl_state <= FETCH_REQ_INSTRUCTION;
                                end if;

                            -- LDI rA, NUMBER
                            -- As before (see LDI rA, rB) but with a NUMBER from a fetch register
                            -- rather than a second general-purpose register's value
                            when "01101" & "01" =>
                                if (ctrl_substate = 0) then
                                    out_fetched_word <= r_fetch(0); -- << These two lines are different
                                    out_BUS0_sel <= SEL_FETCH_REG;  -- << from LDI rA, rB
                                    CONNECT_FROM_BUS('0', out_RAM_loadAddr);
                                    out_regf_waddr <= ir_addr_rA;
                                    out_BUS1_sel <= SEL_RAM_DATA;
                                    CONNECT_FROM_BUS('1', out_regf_loadWData);
                                    out_regf_rw <= '1';
                                    ctrl_substate <= 1;
                                elsif (ctrl_substate = 1) then
                                    DISCONNECT_FROM_BUS(out_RAM_loadAddr);
                                    DISCONNECT_FROM_BUS(out_regf_loadWData);
                                    out_regf_rw <= '0';
                                    ctrl_substate <= 0;
                                    ctrl_state <= FETCH_REQ_INSTRUCTION;
                                end if;

                            -- STO rA, rB
                            when "01110" & "00" =>
                                if (ctrl_substate = 0) then
                                    -- Send address from rB to RAM
                                    out_regf_raddr2 <= ir_addr_rB;
                                    out_BUS0_sel <= SEL_REGF_RDATA2;
                                    CONNECT_FROM_BUS('0', out_RAM_loadAddr);
                                    -- Connect RAM's data back to destination register rA
                                    out_regf_raddr1 <= ir_addr_rA;
                                    out_BUS1_sel <= SEL_REGF_RDATA1;
                                    CONNECT_FROM_BUS('1', out_RAM_loadData);
                                    out_RAM_rw <= '1';
                                    ctrl_substate <= 1;
                                elsif (ctrl_substate = 1) then
                                    -- Clean up
                                    DISCONNECT_FROM_BUS(out_RAM_loadAddr);
                                    DISCONNECT_FROM_BUS(out_RAM_loadData);
                                    out_RAM_rw <= '0';
                                    ctrl_substate <= 0;
                                    ctrl_state <= FETCH_REQ_INSTRUCTION;
                                end if;

                            -- STO rA, NUMBER
                            -- As before (see STO rA, rB) but with a NUMBER from a fetch register
                            -- rather than a second general-purpose register's value
                            when "01110" & "01" =>
                                if (ctrl_substate = 0) then
                                    out_fetched_word <= r_fetch(0); -- << These two lines are different
                                    out_BUS0_sel <= SEL_FETCH_REG;  -- <<
                                    CONNECT_FROM_BUS('0', out_RAM_loadAddr);
                                    out_regf_raddr1 <= ir_addr_rA;
                                    out_BUS1_sel <= SEL_REGF_RDATA1;
                                    CONNECT_FROM_BUS('1', out_RAM_loadData);
                                    out_RAM_rw <= '1';
                                    ctrl_substate <= 1;
                                elsif (ctrl_substate = 1) then
                                    DISCONNECT_FROM_BUS(out_RAM_loadAddr);
                                    DISCONNECT_FROM_BUS(out_RAM_loadData);
                                    out_RAM_rw <= '0';
                                    ctrl_substate <= 0;
                                    ctrl_state <= FETCH_REQ_INSTRUCTION;
                                end if;

                            -- MOV rA, rB
                            when "01111" & "00" =>
                                if (ctrl_substate = 0) then
                                    out_regf_raddr1 <= ir_addr_rB;
                                    out_regf_waddr <= ir_addr_rA;
                                    out_regf_rw <= '1';
                                    out_BUS0_sel <= SEL_REGF_RDATA1;
                                    CONNECT_FROM_BUS('0', out_regf_loadWData);
                                    ctrl_substate <= 1;
                                elsif (ctrl_substate = 1) then
                                    DISCONNECT_FROM_BUS(out_regf_loadWData);
                                    out_regf_rw <= '0';
                                    ctrl_substate <= 0;
                                    ctrl_state <= FETCH_REQ_INSTRUCTION;
                                end if;

                            -- MOV rA, NUMBER
                            when "01111" & "01" =>
                                if (ctrl_substate = 0) then
                                    out_regf_waddr <= ir_addr_rA;
                                    out_regf_rw <= '1';
                                    out_fetched_word <= r_fetch(0);
                                    out_BUS0_sel <= SEL_FETCH_REG;
                                    CONNECT_FROM_BUS('0', out_regf_loadWData);
                                    ctrl_substate <= 1;
                                elsif (ctrl_substate = 1) then
                                    DISCONNECT_FROM_BUS(out_regf_loadWData);
                                    out_regf_rw <= '0';
                                    ctrl_substate <= 0;
                                    ctrl_state <= FETCH_REQ_INSTRUCTION;
                                end if;

                            -- AJMP rA
                            when "10000" & "00" =>
                                if (ctrl_substate = 0) then
                                    out_regf_raddr1 <= ir_addr_rA;
                                    out_BUS0_sel <= SEL_REGF_RDATA1;
                                    ctrl_substate <= 1;
                                elsif (ctrl_substate = 1) then
                                    r_pc <= i_BUS0;
                                    ctrl_substate <= 0;
                                    ctrl_state <= FETCH_REQ_INSTRUCTION;
                                end if;

                            -- AJMP rA
                            when "10000" & "01" =>
                                if (ctrl_substate = 0) then
                                    out_fetched_word <= r_fetch(0);
                                    out_BUS0_sel <= SEL_FETCH_REG;
                                    ctrl_substate <= 1;
                                elsif (ctrl_substate = 1) then
                                    r_pc <= i_BUS0;
                                    ctrl_substate <= 0;
                                    ctrl_state <= FETCH_REQ_INSTRUCTION;
                                end if;

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
