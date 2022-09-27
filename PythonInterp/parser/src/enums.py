#+
# File: enums.py
#
# Enumerated types used by the parser and
# concrete classes.
#-

from enum import Enum,unique
import sys

#=========================================
# class Encoding
#
# encoding is used to represent the encoding
# of a type, CUSTOM is used for self managed
# layout, DER and BER are used for asn.1
# encoded types
#=========================================

@unique
class Encoding(Enum):
    CUSTOM = 0
    DER = 1
    BER = 2

#=========================================
# class RecType
# 
# ASN.1 makes a distinction between a sequence
# and a set.
# Sets can be out of order if the structure
# can be matched based on the DER/BER encoding
#=========================================

@unique
class RecType(Enum):
    SEQ = 0
    SET = 1

#=========================================
# class TextRep
# 
# To be used when producing a text representation
# of the object (not implemented yet)
#=========================================

@unique
class TextRep(Enum):
    String = 0
    Octet = 1

#=========================================
# class BaseType
# 
# SCL primitive types
#=========================================

@unique
class BaseType(Enum):
    INTEGER = 1
    REAL = 2
    OCTET_STRING = 3

    # needed because OCTET_STRING has space in SCL
    @staticmethod
    def from_str(label):
        if label == 'INTEGER':
            return BaseType.INTEGER
        elif label == 'REAL':
            return BaseType.REAL
        elif label == 'OCTET STRING':
            return BaseType.OCTET_STRING
        else:      
            raise NotImplementedError

#=========================================
# class Endian
#
# Little/Big Endian
#=========================================

@unique
class Endian(Enum):
    LITTLE = 0
    BIG = 1
    @staticmethod
    def from_str(label):
        if label == 'LITTLEENDIAN':
            return Endian.LITTLE
        elif label == 'BIGENDIAN':
            return Endian.BIG
        else:      
            raise NotImplementedError

