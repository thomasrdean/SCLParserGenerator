#+
# File expr.py
#
# this is the expression evaluator. Unlike the
# older java version, we assume that the expression
# is parsed by the SCL parser and given to us as an
# XML represenative of a parser tree
#-

from enum import IntEnum,unique
import xml.etree.ElementTree as ET
from .enums import *
from .concrete import *

@unique
class Opcode(IntEnum):
    AND = 0
    OR = 1
    LT = 2
    LE = 3
    GT = 4
    GE = 5
    EQ = 6
    ADD = 7
    SUB = 8
    MUL = 9
    DIV = 10
    DOT = 11
    CALL = 12
    MOD = 13
    NE = 14
    BITAND = 15
    BITOR = 16

    @staticmethod
    def from_string(str):
        match str:
            case '&&':
                return Opcode.AND
            case '||':
                return Opcode.OR
            case '<':
                return Opcode.LT
            case '<=':
                return Opcode.LE
            case '>':
                return Opcode.GT
            case '>=':
                return Opcode.GE
            case '==':
                return Opcode.EQ
            case '+':
                return Opcode.ADD
            case '-':
                return Opcode.SUB
            case '*':
                return Opcode.MUL
            case '/':
                return Opcode.DIV
            case '()':
                return Opcode.CALL
            case '%':
                return Opcode.MOD
            case '!=':
                return Opcode.NE
            case '|':
                return Opcode.BITOR
            case '&':
                return Opcode.BITAND
            case _:
                raise NotImplementedError

class Expr:
    opcodeNames = [
    'AND', 'OR', 'LT', 'LE', 'GT', 'GE', 'EQ',
    'ADD', 'SUB', 'MUL', 'DIV', 'DOT', 'CALL',
    'MOD', 'NE', 'BITAND', 'BITOR' ]
    opStr = [
    '&&', '||', '<', '<=', '>', '>=', '==',
    '+', '-', '*', '/', '.', '(',
    '%', '!=', '&', '|' ]

    def __init__(self):
        pass

    # convert xml tree in the EXPR tree
    # using appropriate subnodes
    @staticmethod
    def convert(t):
        #print('Tag = ' + t.tag)
        match t.tag:
            case 'exprBinOp':
                binop = ExprBinOp()
                #print('attrib = ' + str(t.attrib['op']))
                binop.opcode = Opcode.from_string(t.attrib['op'])
                binop.op1 = Expr.convert(t[0])
                binop.op2 = Expr.convert(t[1])
                return binop
            case 'exprVal':
                match t.attrib['type']:
                    case 'int':
                        return ExprValue(int(t.text))
                    case 'real':
                        # shjopuld be float or?
                        return ExprValue(float(t.text))
                    case 'string':
                        return ExprValue(t.text)
                    case _:
                        raise NotImplementedError
            case 'exprID':
                return ExprID(t.text)
            case _:
                raise NotImplementedError
        return None


class ExprBinOp(Expr):
    def __init__(self):
        super().__init__()
        self.opcode = None
        self.op1 = None
        self.op2 = None

    def print(self,f):
        self.op1.print(f)
        print(" " + Expr.opStr[self.opcode] + " ", end='', file=f)
        self.op2.print(f)
        if self.opcode == Opcode.CALL:
            print(")", end='', file=f)

    def replaceAndSimplify(self,parent,concreteNode,indent):
        #print(' ' * indent + 'simplify: '+ concreteNode.name)
        # special case for dot operator
        # as we have to check that the field type os a record
        # and that the name matches the left
        if self.opcode != Opcode.DOT:
            self.op1 = self.op1.replaceAndSimplify(self,concreteNode,indent)
            self.op2 = self.op2.replaceAndSimplify(self,concreteNode,indent)
            # if both are ExprValue() then evaluate
            if isinstance(self.op1,ExprValue) and isinstance(self.op2,ExprValue):
                match self.opcode:
                    case Opcode.EQ:
                        if self.op1.value == self.op2.value:
                           return ExprValue(1)
                        else:
                           return ExprValue(0)
        else:
            # must be a sublcass ConREC
            # TODO not implemented yet.
            raise NotImplementedError
        
        return self
    
class ExprValue(Expr):
    def __init__(self, v):
        super().__init__()
        self.value = v;

    def print(self,f):
        print(self.value,end='',file=f)

    def replaceAndSimplify(self,parent,concreteNode,indent):
        return self

class ExprID(Expr):
    def __init__(self, n):
        super().__init__()
        self.name = n;

    def print(self,f):
        print(self.name,end='',file=f)

    def replaceAndSimplify(self,parent,concreteNode,indent):
        if isinstance(parent, ExprBinOp) and parent.opcode == Opcode.DOT:
            print("******* dot not implemented yet *****")
            raise NotImplementedError
        if isinstance(concreteNode,ConToken):
            # should do somehting about numeric vs string types
            return ExprValue(concreteNode.value)
        return self

@unique
class BuiltIn(IntEnum):
    PDUREMAINING = 0

class ExprBuiltin(Expr):
    def __init__(self, v):
        super().__init__()
        self.value = v;
