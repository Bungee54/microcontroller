import assembler

data = ''' 
          ADD r3, 0x30
label1:   SUB r2, 0x34f
          OR r2, r5
          ASL r4, 3
label2:   STO r3, 0x34F8
          AJMP <label1>
          HALT 
'''

print("%s\n=========================\n" % data)

machine_code = assembler.assemble(data, debug=True)

print(machine_code)