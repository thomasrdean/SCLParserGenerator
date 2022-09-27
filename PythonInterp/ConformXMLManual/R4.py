#+
# File R1.py
# 
# This is the translation to pytyon
# of the coformacne code used to test
# the SCL parser generataor.
#
# This one tets the use of SEQENCE types
# as the types of fields. Results in nested
# concrete structures
#-

from struct import *

import sys
sys.path.append('../')
import parser.src.parser as SCLParser

if __name__ == '__main__':
    #build the byte array
    # all big endian
    # a - REAL 8 4.3
    # b - INT 8 (0xA1A2A3A4A5A6A7A8)
    # c - REAL 4 (45.5)
    # d - INT 4 (0xA1A2A3A4)
    # e - INT 2 (0xA1A2)
    # f - INT 1 (0xA1A2)
    data = pack('>d',4.3);
    data = data + pack('>Q',0xA1A2A3A4A5A6A7A8)
    data = data + pack('>f',45.4);
    data = data + pack('>I',0xA1A2A3A4)
    data = data + pack('>H',0xA1A2)
    data = data + pack('>B',0xA1)
    print ('packed data is <' + data.hex() +  '>')

    thePDU = SCLParser.PDU()
    thePDU.len = len(data)
    thePDU.data = data

    p = SCLParser.Parser('R4.xml')

    c = p.parse(thePDU,'PDU_R4')
    c.walk(0,sys.stdout)
    if c.members['s1'].members['a'].value != 4.3:
        print('s1.a = ' + str(c.members['s1'].members['a'].value) + '(!= 4.3)')
    if c.members['s1'].members['b'].value != 0xA1A2A3A4A5A6A7A8:
        print('s1.b = ' + hex(c.members['s1'].members['b'].value) + '(!= 0xA1A2A3A4A5A6A7A8)')
    if c.members['s1'].members['c'].value - 45.4 > 0.00001:
        print('s1.c = ' + str(c.members['s1'].members['c'].value) + '(!= 45.4)')
    if c.members['s2'].members['d'].value != 0xA1A2A3A4:
        print('s1.d = ' + hex(c.members['s2'].members['d'].value) + '(!= 0xA1A2A3A4)')
    if c.members['s2'].members['e'].value != 0xA1A2:
        print('s2.e = ' + hex(c.members['s2'].members['e'].value) + '(!= 0xA1A2)')
    if c.members['s2'].members['f'].value != 0xA1:
        print('s1.f = ' + hex(c.members['s2'].members['f'].value) + '(!= 0xA1)')
