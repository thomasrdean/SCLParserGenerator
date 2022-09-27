# The SCL Parser Generator

This is the source and test code for the SCL Parser Generator. Structure:

- Txl - this directory contains all of the TXL code
- SCL5 - grammar files
- GENSOURCE - default destination of generated parsers/deserializers/printers
- BUILD directory - contains utility code and main, used to build the final systems
- Docs - contains tex file for pdf
- PtyhonInterp - start of a python interpreter that will use an xml file generated from SCL file
- compare - used for regression testing.
- INTERMEDIATE - intermediate files during generation of framework
- ConformScl5 - conformance tests
- ConformC - C support files for conformance tests
- ConformSrc - generated output of ConformScl5

Usage:

New Branch for restructured parser 

Place all SCL5 files that you would like parsers generated for in /SCL5
Run ./generateParser.sh
Generated parsers will be located in /GENSOURCE

As part of the generation process, generated parsers will be copied to BUILD, which contains all necessary code to execute the parser program. Existing copies of the generated parsers in BUILD will be replaced and the build will have a 'make clean' run on it.


Fixed (somewhat)
--------------
1. llK optimization no longer requires BACKs to be in correct order
2. General readabiity of code has been improved
4. only parse funcitons for exported types are public, and include the protocol name to prevent conflict
5. Annotations in grammar are unified
6. LL(k) uses unified parsing methods
    - LLK is based only on offset and size, not that choices have the exact same intervening fields (conventional LLK).
7. Only one parsing method is made for each SET/SEQUENCE_OF for each type of termination.
  - if the SET/SEQ of type occurs more than once, only one is gerated.


TODO:
----------------
1. submessage callback is not implemented yet.
2. LENGTH of user defined type as expression in constraint (remove SIZEOF operator)
3. CARDINALITY of userdefined type as expression.
4. LENGTH on a field defined type without slack not yet enforced (could be less)
5. Unused bytes at end not enforced yet.
6. global constraints (needed for RTPS App Data)
7. ALIGN attribute (needed for RTPS App Data)
8. Option to free strucutres after callback.
9. Reorg of programs and more comments.

Other optimziations to do
-------------------
1. constant folding
2. Subexpression reduction (a complex constraint may be executed more than once).
2. checking - e.g. check that back constraints are simple and ask the use to refactor if not.
3. Type checking of constraints (check type of fields and operations).

