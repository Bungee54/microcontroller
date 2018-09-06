SetActiveLib -work
comp -include "$dsn\src\register_file.vhd" 
comp -include "$dsn\src\TestBench\register_file_TB.vhd" 
asim +access +r TESTBENCH_FOR_register_file 
wave 
wave -noreg i_raddr1
wave -noreg i_raddr2
wave -noreg i_waddr
wave -noreg i_data
wave -noreg i_rw
wave -noreg o_data1
wave -noreg o_data2
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$dsn\src\TestBench\register_file_TB_tim_cfg.vhd" 
# asim +access +r TIMING_FOR_register_file 
