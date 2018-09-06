-------------------------------------------------------------------------------
--
-- Title       : 
-- Design      : Microcontroller
-- Author      : Evan
-- Company     : Old Dominion University
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Aldec_Designs\test_workspace\Microcontroller\compile\cpu.vhd
-- Generated   : Tue Jul 31 22:58:29 2018
-- From        : c:\My_Aldec_Designs\test_workspace\Microcontroller\src\cpu.bde
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
        use ieee.NUMERIC_STD.all;
        use ieee.STD_LOGIC_UNSIGNED.all;

entity cpu is
  port(
       i_clk : in STD_LOGIC;
       i_rst : in STD_LOGIC;
       i_input : in STD_LOGIC_VECTOR(7 downto 0);
       o_output : out STD_LOGIC_VECTOR(7 downto 0)
  );
end cpu;

architecture rtl of cpu is

---- Component declarations -----

component alu
  port (
       A : in STD_LOGIC_VECTOR(7 downto 0);
       B : in STD_LOGIC_VECTOR(7 downto 0);
       OPCODE : in STD_LOGIC_VECTOR(3 downto 0);
       FLAG_CARRY : out STD_LOGIC;
       FLAG_NEGATIVE : out STD_LOGIC;
       FLAG_OVERFLOW : out STD_LOGIC;
       FLAG_ZERO : out STD_LOGIC;
       Y : out STD_LOGIC_VECTOR(7 downto 0)
  );
end component;
component register_file
  port (
       i_data : in STD_LOGIC_VECTOR(7 downto 0);
       i_raddr1 : in STD_LOGIC_VECTOR(2 downto 0);
       i_raddr2 : in STD_LOGIC_VECTOR(2 downto 0);
       i_rw : in STD_LOGIC;
       i_waddr : in STD_LOGIC_VECTOR(2 downto 0);
       o_data1 : out STD_LOGIC_VECTOR(7 downto 0);
       o_data2 : out STD_LOGIC_VECTOR(7 downto 0)
  );
end component;
component synchronous_ram
  port (
       i_address : in STD_LOGIC_VECTOR(7 downto 0);
       i_clk : in STD_LOGIC;
       i_rw : in STD_LOGIC;
       io_data : inout STD_LOGIC_VECTOR
  );
end component;

---- Architecture declarations -----
constant c_STATE_MAX : unsigned(ctrl_state'range) := to_unsigned(1,ctrl_state'left + 1);



---- Signal declarations used on the diagram ----

signal regf_rw : STD_LOGIC;
signal sram_rw : STD_LOGIC;
signal alu_in1 : STD_LOGIC_VECTOR(7 downto 0);
signal alu_in2 : STD_LOGIC_VECTOR(7 downto 0);
signal alu_opcode : STD_LOGIC_VECTOR(3 downto 0);
signal alu_output : STD_LOGIC_VECTOR(7 downto 0);
signal ctrl_state : UNSIGNED(3 downto 0);
signal regf_raddr1 : STD_LOGIC_VECTOR(2 downto 0);
signal regf_raddr2 : STD_LOGIC_VECTOR(2 downto 0);
signal regf_rdata1 : STD_LOGIC_VECTOR(7 downto 0);
signal regf_rdata2 : STD_LOGIC_VECTOR(7 downto 0);
signal regf_waddr : STD_LOGIC_VECTOR(2 downto 0);
signal regf_wdata : STD_LOGIC_VECTOR(7 downto 0);
signal r_ir : STD_LOGIC_VECTOR(15 downto 0);
signal r_pc : STD_LOGIC_VECTOR(7 downto 0);
signal r_status : STD_LOGIC_VECTOR(7 downto 0);
signal sram_addr : STD_LOGIC_VECTOR(7 downto 0);
signal sram_data : STD_LOGIC_VECTOR(7 downto 0);

begin

---- Processes ----

RUN : process (i_clk,i_rst)
                       begin
                         if (rising_edge(i_rst)) then
                            r_status <= "ZZZZ0000";
                            r_pc <= (others => '0');
                            r_ir <= (others => '0');
                            alu_in1 <= (others => '0');
                            alu_in2 <= (others => '0');
                            alu_opcode <= (others => '0');
                            sram_addr <= (others => '0');
                            sram_data <= (others => 'Z');
                            sram_rw <= '0';
                            regf_raddr1 <= (others => '0');
                            regf_raddr2 <= (others => '0');
                            regf_waddr <= (others => '0');
                            regf_wdata <= (others => '0');
                            regf_rw <= '0';
                            ctrl_state <= to_unsigned(0,ctrl_state'left + 1);
                         end if;
                         if (rising_edge(i_clk) and (not rising_edge(i_rst))) then
                            if (ctrl_state = 0) then
                               sram_addr <= r_pc;
                               sram_data <= "ZZZZZZZZ";
                               sram_rw <= '0';
                            elsif (ctrl_state = 1) then
                               r_pc <= r_pc + 1;
                            end if;
                            if (ctrl_state = c_STATE_MAX) then
                               ctrl_state <= to_unsigned(0,ctrl_state'left + 1);
                            else 
                               ctrl_state <= ctrl_state + 1;
                            end if;
                         end if;
                       end process;
                      

----  Component instantiations  ----

comp_ALU : alu
  port map(
       A => alu_in1,
       B => alu_in2,
       FLAG_CARRY => r_status(6),
       FLAG_NEGATIVE => r_status(5),
       FLAG_OVERFLOW => r_status(4),
       FLAG_ZERO => r_status(7),
       OPCODE => alu_opcode,
       Y => alu_output
  );

comp_REGFILE : register_file
  port map(
       i_data => regf_wdata,
       i_raddr1 => regf_raddr1,
       i_raddr2 => regf_raddr2,
       i_rw => regf_rw,
       i_waddr => regf_waddr,
       o_data1 => regf_rdata1,
       o_data2 => regf_rdata2
  );

comp_SRAM : synchronous_ram
  port map(
       i_address => sram_addr,
       i_clk => i_clk,
       i_rw => sram_rw,
       io_data => sram_data
  );


end rtl;
