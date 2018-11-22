# MyMicroAssembly Parser
import ply.yacc as yacc
import asm_utility
from asm_lexer import tokens, lexer   # *DO NOT REMOVE* asm_lexer.tokens; yacc.py uses it under the hood. 

'''
Grammar specification
Top-level grammar rule returns tuple: 
(label_name, (instruction_name, [operands]))
  --> label_name is the name of any LABEL_DEF that exists on the 
      line; if none exists, label_name = None.
  --> where each operand is a tuple in the form of
      (operand_type, operand_value)
  --> For REGISTER operands, the value is the number of the register
  --> For NUMBER operands, the value is just the number (integer)
Other notes about yacc.py (from PLY library):
  --> Function docstrings specify grammar rules. 
  --> Each function takes argument `p` which is a tuple of all
      values in the rule
    --> Example: Docstring is r'line : INSTRUCTION operandlist'
        p = (line.value, INSTRUCTION.value, operandlist.value)
  --> Value of each element of `p` is determined by previous
      functions, or is the value of the token if the element is a
      "terminal" one (meaning it is a raw token from the lexer, 
      such as NUMBER or REGISTER).
-----------------------
This tuple is converted into the InstructionLine object after
parsing. 
'''

# ==================================================================

def p_line_labeldef_instruction_operandlist(p):
  r'line : LABEL_DEF INSTRUCTION operandlist'
  p[0] = (p[1], (p[2], p[3]))

def p_line_instruction_operandlist(p):
  r'line : INSTRUCTION operandlist'
  p[0] = (None, (p[1], p[2]))

def p_line_instruction(p):
  r'line : INSTRUCTION'
  p[0] = (None, (p[1], [])) # Tuple of (label_name, (instruction, blank_operandlist)

def p_operandlist_comma_operand(p):
  r'operandlist : operandlist COMMA operand'
  p[1].append(p[3])
  p[0] = p[1]
  
def p_operandlist_operand(p):
  r'operandlist : operand'
  p[0] = [p[1]]

def p_operand_register(p):
  r'operand : REGISTER'
  p[0] = asm_utility.Operand('REGISTER', p[1])

def p_operand_number(p):
  r'operand : NUMBER'
  p[0] = asm_utility.Operand('NUMBER', p[1]) # Tuple containing `type` and `value` fields

def p_operand_labelref(p):
  r'operand : LABEL_REF'
  p[0] = asm_utility.Operand('LABEL_REF', p[1])

def p_error(p):
    print("Syntax error in input!")

# ================================================================

parser = yacc.yacc() # Build parser

def parse_data(data):
  '''Returns list of InstructionLine objects for each line of
  assembly.
  '''
  
  data = data.strip()
  instruction_lines = []

  for text_line in data.splitlines():
    parsed_tuple = parser.parse(text_line.strip())
    instruction_line = asm_utility.InstructionLine(
      parsed_tuple[1][0],
      parsed_tuple[1][1],
      parsed_tuple[0]
    )
    instruction_lines.append(instruction_line)
  
  return instruction_lines


def debug_parse_data(data):
  '''
  Equivalent to parse_data but prints debug information instead of returning a list of instruction tuples.
  '''

  data = data.strip() # Necessary so the parser isn't confused by a newline at the beginning.

  # DEBUG
  print(data)
  print()

  # Print lexer output to compare with parser output. 
  for line in data.splitlines():
    line = line.strip()
    lexer.input(line)
    for tok in lexer:
      print(tok)

  print()
  # END DEBUG

  instruction_lines = parse_data(data)
  for tup in instruction_lines:
    print(tup)
