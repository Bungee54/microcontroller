'''Holds important global information/specifications about the
language used during the assembly process. 
'''

# Pairs each instruction to an opcode and two flag bits 
# which depend on the instruction's operands. 
#
# The first element of the value tuple is the opcode, while  
# the second element is another dictionary where each key is a
# tuple of valid operands (specified with their token types,
# such as 'REGISTER') and each value is the corresponding
# set of flag bits for those operands. 
#
# For example, the first seven-bits of an ADD r3, 34 instruction
# would be 00000 01. 
opcode_dict = {
  'ADD':('00000', {('REGISTER', 'REGISTER') :'00', 
                   ('REGISTER', 'NUMBER')   :'01'}),
  'SUB':('00001', {('REGISTER', 'REGISTER') :'00',
                   ('REGISTER', 'NUMBER')   :'01'}),
  'NEG':('00010', {('REGISTER',)            :'00'}),
  'INC':('00011', {('REGISTER',)            :'00'}),
  'DEC':('00100', {('REGISTER',)            :'00'}),
  'AND':('00101', {('REGISTER', 'REGISTER') :'00',
                   ('REGISTER', 'NUMBER')   :'01'}),
  'OR' :('00110', {('REGISTER', 'REGISTER') :'00',
                   ('REGISTER', 'NUMBER')   :'01'}),
  'XOR':('00111', {('REGISTER', 'REGISTER') :'00',
                   ('REGISTER', 'NUMBER')   :'01'}),
  'NOT':('01000', {('REGISTER',)            :'00'}),
  'LSL':('01001', {('REGISTER', 'REGISTER') :'00',
                   ('REGISTER', 'NUMBER')   :'01'}),
  'LSR':('01010', {('REGISTER', 'REGISTER') :'00',
                   ('REGISTER', 'NUMBER')   :'01'}),
  'ASR':('01011', {('REGISTER', 'REGISTER') :'00',
                   ('REGISTER', 'NUMBER')   :'01'}),
  'CMP':('01100', {('REGISTER', 'REGISTER') :'00',
                   ('REGISTER', 'NUMBER')   :'01'}),
  'LDI':('01101', {('REGISTER', 'REGISTER') :'00',
                   ('REGISTER', 'NUMBER')   :'01'}),
  'STO':('01110', {('REGISTER', 'REGISTER') :'00',
                   ('REGISTER', 'NUMBER')   :'01'}),
  'MOV':('01111', {('REGISTER', 'REGISTER') :'00',
                   ('REGISTER', 'NUMBER')   :'01'}),
  'AJMP':('10000',{('REGISTER',)            :'00',
                   ('NUMBER',)              :'01',
                   ('LABEL_REF',)           :'01'}),
  'RET':('11110', {()                       :'00'}),
  'HALT':('11111', {()                      :'00'})
}

# Dictionary holding all instruction aliases; useful for
# instructions that do the same thing but are named differently
# to clarify the code.
instruction_aliases = {'ASL' : 'LSL'}