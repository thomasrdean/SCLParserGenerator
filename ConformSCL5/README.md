Conformance Tests
=================

Test cases that test specific language featuree.

The script conform.sh in the root directory
will process the scl5 files and save them in ../ConformSrc
The C code that runs these tests is in ../ConformC.
The makefile in ../ConformC.

Note prrinting and serialization code is also tested


Test Cases
==========

R1.scl5 - Single structure with explicit little endian types

R2.scl5 - Single structure with explicit bit endian

R3.scl5 - Single structure with implicit endian (passed as big endian from R3.c)

R4.scl5 - Structure with two fields that are strucutres.

R5.scl5 - Choice between two structures of different size, back constraints mututally exclusive

R6.scl5 - Structure with optional field (forward EXiSTS and PDUREMAINING)

R7.scl5 - Structure with optional field (forward EXiSTS and Bit flag)

R8.scl5  - Choice between three structures, two with same bck constraint but different sizes

R9.scl5 - length of octet string given by value of other field

R10.scl5 - Choice using octet string and mutuall exclusive back

R11.scl5 - Set of user defined type, cardinality constraint 

R12.scl5 - set of user defined type, length constraint


Needed Test Cases
=================

callback, or in back constraint, submessage callback
