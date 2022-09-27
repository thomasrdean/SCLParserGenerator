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

    # three arrays, grammar choice, two with same
    # disciriminator based on size.
    #
    # R82
    # a - INT 1 (back constraint = 10)
    # b - INT 4
    #
    # R81/R83
    # c - INT 1 (back constraint == 10) 20 for R83
    # d - INT 4
    # e - INT 4

    R81 =  pack('>B',10) + pack('>I',0xA1A2A3A4) + pack('>I',0xA5A6A7A8)
    R82 =  pack('>B',10) + pack('>I',0xA1A2A3A4)
    R83 =  pack('>B',20) + pack('>I',0xA1A2A3A4) + pack('>I',0xA5A6A7A8)

    print('Message R81')
    print ('packed data is <' + R81.hex() +  '>')

    thePDU = SCLParser.PDU()
    thePDU.len = len(R81)
    thePDU.data = R81

    p = SCLParser.Parser('R8.xml')

    c = p.parse(thePDU,'PDU_R8')
    c.walk(0,sys.stdout)
    if c.members['c'].value != 10:
        print('c = ' + hex(c.members['c'].value) + '(!= 10)')
    if c.members['d'].value != 0xA1A2A3A4:
        print('d = ' + hex(c.members['d'].value) + '(!= 0xA1A2A3A4)')
    if c.members['e'].value != 0xA5A6A7A8:
        print('e = ' + hex(c.members['e'].value) + '(!= 0xA5A6A7A8)')


    print('Message R82')
    print ('packed data is <' + R82.hex() +  '>')

    thePDU = SCLParser.PDU()
    thePDU.len = len(R82)
    thePDU.data = R82
    c = p.parse(thePDU,'PDU_R8')
    c.walk(0,sys.stdout)
    if c.members['a'].value != 10:
        print('a = ' + hex(c.members['a'].value) + '(!= 10)')
    if c.members['b'].value != 0xA1A2A3A4:
        print('b = ' + hex(c.members['b'].value) + '(!= 0xA1A2A3A4)')


    print('Message R83')
    print ('packed data is <' + R83.hex() +  '>')

    thePDU = SCLParser.PDU()
    thePDU.len = len(R83)
    thePDU.data = R83
    c = p.parse(thePDU,'PDU_R8')
    c.walk(0,sys.stdout)

    if c.members['c'].value != 20:
        print('c = ' + hex(c.members['c'].value) + '(!= 20)')
    if c.members['d'].value != 0xA1A2A3A4:
        print('d = ' + hex(c.members['d'].value) + '(!= 0xA1A2A3A4)')
    if c.members['e'].value != 0xA5A6A7A8:
        print('e = ' + hex(c.members['e'].value) + '(!= 0xA5A6A7A8)')

