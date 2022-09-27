#+
# File R5.py
# 
# This is the translation to pytyon
# of the coformacne code used to test
# the SCL parser generataor.
#
# This one introduces a choice node (GrmOR)
# and simple backward constraints to choose
# between them
#-

from struct import *

import sys
sys.path.append('../')
import parser.src.parser as SCLParser

if __name__ == '__main__':

    # two arrays, grammar choice
    #
    # R51
    # a - INT 1 (back constraint = 10)
    # b - INT 4
    #
    # R51
    # c - INT 1 (back constraint == 20)
    # d - INT 4
    # e - INT 4

    R51 =  pack('>B',10) + pack('>I',0xA1A2A3A4)
    R52 =  pack('>B',20) + pack('>I',0xA1A2A3A4) + pack('>I',0xA5A6A7A8)

    print('Message R51')
    print ('packed data is <' + R51.hex() +  '>')

    thePDU = SCLParser.PDU()
    thePDU.len = len(R51)
    thePDU.data = R51

    p = SCLParser.Parser('R5.xml')

    c = p.parse(thePDU,'PDU_R5')
    c.walk(0,sys.stdout)
    # TODO add checks for value
    if c.members['a'].value != 10:
        print('a = ' + hex(c.members['a'].value) + '(!= 10)')
    if c.members['b'].value != 0xA1A2A3A4:
        print('b = ' + hex(c.members['b'].value) + '(!= 0xA1A2A3A4)')

    print('Message R52')
    print ('packed data is <' + R52.hex() +  '>')

    thePDU = SCLParser.PDU()
    thePDU.len = len(R52)
    thePDU.data = R52
    c = p.parse(thePDU,'PDU_R5')
    c.walk(0,sys.stdout)
    if c.members['c'].value != 20:
        print('c = ' + hex(c.members['c'].value) + '(!= 20)')
    if c.members['d'].value != 0xA1A2A3A4:
        print('d = ' + hex(c.members['d'].value) + '(!= 0xA1A2A3A4)')
    if c.members['e'].value != 0xA5A6A7A8:
        print('e = ' + hex(c.members['e'].value) + '(!= 0xA5A6A7A8)')


