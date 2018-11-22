'''Holds useful classes and methods for the assembler.
'''

# Lists every type of operand that requires an extension
# word attached to an instruction. 
# For example, an instruction taking a 'NUMBER' and a 
# 'REGISTER' operand would require one extension word,
# since it has one operand whose type is in this list.
extension_operand_types = [
  'NUMBER',
  'LABEL_REF'
]

class InstructionLine:
  '''Holds all relevant information about each line of assembly.
  Contains: name of instruction, operands, any associated label, and 
  useful utility functions.
  '''
  def __init__(self, instruction_name, operand_list, label_name=None):
    self.instruction_name = instruction_name
    self.operand_list = operand_list
    self.label_name = label_name

    verify_valid_operands(self)
  

  def __repr__(self):
    return str(
      (self.instruction_name, self.operand_list, self.label_name))


  # Returns the length (in 16-bit words) of an instruction
  # and its operands given as an instruction tuple of the
  # form:
  # (label_name, (instruction_name, operand_list))
  def getInstructionLength(self):
    '''Returns the length (in 16-bit words) of the assembled
    instruction line, complete with the base instruction template
    and any necessary extension words. 
    Essentially returns 1 + (number_of_operands_needing_extensions).
    '''
    length = 1;
    for operand in self.operand_list:
      if operand.name in extension_operand_types:
        length += 1
    return length


class Operand:
  '''Holds basic properties of operands.
  '''
  def __init__(self, name, value):
    self.name = name
    self.value = value
  
  
  def __repr__(self):
    return str((self.name, self.value))


def verify_valid_operands(instruction_line):
  i_name = instruction_line.instruction_name
  op_list = instruction_line.operand_list
  operand_names = tuple([operand.name for operand in op_list])

  # Make sure we aren't violating the specification by somehow using >3
  # registers.
  assert (operand_names.count('REGISTER') <= 3), \
    "!!! ERROR: Too many registers (%d) specified for instruction `%s`" % (operand_names.count('REGISTER'), i_name)

  for operand in op_list:
    if operand.name == 'REGISTER':
      assert (operand.value in range(0, 8)), \
        "!!! ERROR: Register out of bounds (%d) for operation %s" % (operand.value, instruction_line)
    elif operand.name == 'NUMBER':
      assert(operand.value in range(0, 65536)), \
        "!!! ERROR: Number out of bounds (%d) for operation %s" % (operand.value, instruction_line)