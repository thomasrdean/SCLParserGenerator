% Generate Header
% Ali El-Shakankiry
% Queen's University, Jan 2017

% Copyright 2017 Thomas Dean, Ali El-Shakankiry, Kyle Lavorato

% Revision history:

% 3.0 Changed to only provide definitiions for 
% parse and free funcions of exported types.
% also, same structure is created regardless of
% submessage. Ununsed fields will be set to null
% by the parser.

% 2.0 Release Version		- KPL	06 06 2018
%	  All known issues resolved
% 1.5 LL(1) Bug Fix Support	- KPL	06 05 2018
% 1.4 Debug mode beta v1.0	- KPL	05 18 2018
% 1.3 LL(k) Addition 		- KPL	05 15 2018
% 1.2 Documentation			- KPL	06 26 2017
% 1.1 Callback annotation 	- KPL	06 14 2017
% 1.0 Initial revision 		- AES 	01 01 2017 

% This program walks through a SCL5 file and generates a header file for
% a parser for the specified protocol.

% The input to the program is a SCL5 file named "protocol"_opt1.scl5.
% The input file has been annotated by the previous TXL scripts, marking it for
% various optimizations and ensuring unique naming.

% The output of this program is a header file named 
% "protocol"_Generated.h.unsorted. The output file describes the protocol in
% terms of c structs.
%
% Output:
%   Include files (stdio, stdint, stdlib, string, inttypes, packet.h globals.h
%
%   #ifndef _FILENAME_DEFINITIONS_H_
%   #define _FILENAME_DEFINITIONS_H_
%
%   - Types for all the module the module
%   - Type decision
%   typedef enum {... } TYPEDEC_NAME_type_val;
%   typedef struct {
%       TYPEDEC_NAME_type_val type;
%	union { ... } - entry for each type in the type decision
%   } UNIQUETYPENAME;
%
%   - Struct Type
%   typedef struct {
%   } UNIQUETYPE_NAME
%
%   - prototype for callbacks
%   -- general callback
%   void FULL_RTPS_callback (FULL_RTPS * full_rtps, PDU * thePDU);
%   -- submessage callback
%   void GAP_RTPS_callback (FULL_RTPS * full_rtps, GAP_RTPS * gap_rtps, PDU * thePDU);
%   - prototype for parse functions for each exported type
%   bool parsePDU_RTPS(PDU_RTPS * pdu_rtps, PUD * thePDU, char * name, uint8_t endianness);
%   - prototype for free function for exach exported type
%   void freePDU_RTPS(PDU_RTPS * pdu_rtps);
%
%   -- struct Fields for structure type become unsigned ints.
%   -- reals are float or double, only 4 and 8 are recognized
%   -- octet strings of defined length become embedded character arrays
%   -- octet strings of computed length are pointers to character arrays
%   -- fields of other defined types are embedded types
%   -- optional fields of any type other than integer are pointer
%   -- set of/seq of are pointers to arrays of that type


% Base grammars

include "c.grm"
include "ASNOne.Grm"

include "annot.ovr"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%C overrides for headers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

redefine program
    ...
  | [repeat c_translation]
end redefine

redefine rule_definition
    ...
  | [repeat c_translation]
end redefine

define c_translation
     [callback_function]
   | [parse_function]
   | [free_function]
   | [type_tag_translation]
   | [type_translation]
   | [enum_translation]
   | [import_translation]
end define

define callback_function
    [function_definition_or_declaration]
end define

define parse_function
    [function_definition_or_declaration]
end define

define free_function
    [function_definition_or_declaration]
end define

define type_tag_translation
    [function_definition_or_declaration]
end define

define type_translation
    [type_decision_translation]
  | [type_rule_translation]
end define

define type_decision_translation
    % enum and union
    % now just union
    %[function_definition_or_declaration]
    [function_definition_or_declaration]
end define

define enum_translation
    [function_definition_or_declaration]
end define

define import_translation
    [function_definition_or_declaration]
end define

define type_rule_translation
    % struct
    [function_definition_or_declaration]
end define


function main
    replace [program]
	P [program]

    construct Msg [stringlit]
    	_ [processCommandArguments]
	  [createGlobalVars]
    by
	P [processEachModule]
	  [assembleProgram]
end function

function processCommandArguments
    % runtime debug flag
    export debugArg [number]
	_ [checkTXLArgs '"-debug'"]

    export Callback [number]
	_ [checkTXLArgs '"-callback"]

    export SubMessage [number]
	_ [checkTXLArgs '"-submessage"]

    export noFree [number]
	_ [checkTXLArgs '"-nofree"]

    replace [stringlit]
    	S [stringlit]
    by
    	S
end function

% this function creates the initial value of global
% variables used to assemble the final program.
function createGlobalVars

    % Global variable to hold all the DotID imported includes
    export DTIDIncludes [repeat preprocessor]
    	_


    replace [stringlit]
    	S [stringlit]
    by
    	S
end function

function checkTXLArgs Arg[stringlit]
    import TXLargs [repeat stringlit]
    deconstruct * [stringlit] TXLargs
	Arg
    replace [number]
	num [number]
    by
	'1
end function

rule processEachModule
    replace $ [module_definition]
      ModName [id] 'DEFINITIONS ::= 'BEGIN
         Exports [opt export_block]
	 Imports [opt import_block]
	 Rules [repeat rule_definition]
      'END

    %construct Msg [stringlit]
	%_ [createModuleGlobalVars]

    export Tags [list enumerator]
    	_

    construct TagTypeName [id]
    	ModName [+ '_TagType]

    % Copy of all the [type_decision_definition]s in the program
    construct TypeDecisions [repeat type_decision_definition]
	    _ [^ Rules]

    by
      ModName  'DEFINITIONS ::= 'BEGIN
         Exports
	 Imports
	 Rules
	     [translateTypeDecisions Exports TagTypeName]
	     [translateTypeStructs Exports]
	     [addEnums TagTypeName]
	     [addModules Imports]
      'END
end rule


define struct_container
    [repeat type_translation]
end define

function assembleProgram
    % input name is FILENAME_somephase.scl5
    % assume outputs are:
    %   FILENAME_Parser.c
    %   FILENAME_Definitions.h
    import TXLinput [stringlit]

    construct StemName [stringlit]
    	TXLinput
	    [trimToBase]
	    [removeAfterUnderscore]
    
    construct IncludeGuard [stringlit]
        _ [+ '"_"]
	  [+ StemName]
	  [toupper]
	  %[putp "Name stem is %"]
	  [+ '"DEFINITIONS_H_"]
	  %[putp "Include Name is %"]

    replace [program]
	P [program]
    construct CallbackProtos [repeat callback_function]
    	_ [^ P]
    construct CallBackProtos2 [repeat c_translation]
    	_ [reparse CallbackProtos]
    construct ParseProtos [repeat parse_function]
    	_ [^ P]
    construct ParseProtos2 [repeat c_translation]
    	_ [reparse ParseProtos]
    construct FreeProtos [repeat free_function]
    	_ [^ P]
    construct FreeProtos2 [repeat c_translation]
    	_ [reparse FreeProtos]
    construct Structs [repeat type_translation]
    	_ [^ P]
    construct SortContainer [struct_container]
	Structs
    construct SortContainer2 [struct_container]
        SortContainer [sortStructs]
    construct Structs2 [repeat c_translation]
    	_ [reparse SortContainer2]

    construct Enums [repeat enum_translation]
    	_ [^ P]
    construct Enums2 [repeat c_translation]
    	_ [reparse Enums]

    construct Includes [repeat import_translation]
    	_ [^ P]
    construct Includes2 [repeat c_translation]
    	_ [reparse Includes]
	  [putp "INcludes are %"]

    construct  IfNDefStr [stringlit]
    	_ [+ "#ifndef "] [+ IncludeGuard]
    construct  IfNDefLine [preprocessor_line]
    	_ [parse IfNDefStr]
    construct  DefStr [stringlit]
    	_ [+ "#define "] [+ IncludeGuard]
    construct  DefLine [preprocessor_line]
    	_ [parse DefStr]

    construct Preface [repeat c_translation]
        IfNDefLine
        DefLine
	'#include <stdio.h>
	'#include <stdint.h>
	'#include <stdlib.h>
	'#include <string.h>
	'#include <inttypes.h>
	'#include "packet.h"
	'#include "globals.h"

    construct Trailer [repeat c_translation]
    	'#endif
    by
        Preface
	[. Includes2]
	[. Enums2]
        [. Structs2]
	[. CallBackProtos2]
	[. ParseProtos2]
	[. FreeProtos2]
	[. Trailer]
end function 
% reset per module global variables

function trimToBase
    replace [stringlit]
	FileName [stringlit]
    construct Slash [number]
    	_ [index FileName '/]
	  [+ 1]
    construct FileNameLength [number]
    	_ [# FileName]
    where
    	Slash [> 0]
	      [< FileNameLength]
    by
       FileName [: Slash FileNameLength]
end function

function removeAfterUnderscore
    replace [stringlit]
	FileName [stringlit]
    construct Under [number]
    	_ [index FileName '_]
    where
    	Under [> 0]
    by
       FileName [: 1 Under]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% Step 1 - Type Decisions
% Type Decisions become Union Structures with an enumerated type for the type field
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

rule translateTypeDecisions Exports [opt export_block] TagTypeName [id]
    replace [repeat rule_definition]
	'[ UniqueName [id] '^ ShortName [id] '] Annot [annotation] '::= TypeDec [type_decision] SclAdd [opt scl_additions]
	Rest [repeat rule_definition]
 
    construct Types [repeat type_reference]
    	_ [^ TypeDec]

    construct Enumerators [list enumerator]
	_ [addTagForEachType each Types]
 
    import Tags [list enumerator]
    export Tags
    	Tags [, Enumerators]

    %construct TagTypeName [id]
    	%UniqueName [+ '_TagType]

    %construct FirstUnder [number]
        %_ [index UniqueName '_]
    %construct ModName [id]
    	%UniqueName [: 1 FirstUnder]

    % one enum type for all tags
    %construct TagTypeName [id]
    	%ModName [+ '_TagType]

    construct body [repeat member_declaration]
	_ [addUnionElementForEachType each Types]

    construct CallbackFunction [repeat rule_definition]
        _ [addGeneralCallback UniqueName SclAdd]

    construct ParseFunction [repeat rule_definition]
        _ [addParseFunction UniqueName Exports]

    construct FreeFunction [repeat rule_definition]
        _ [addFreeFunction UniqueName Exports]

    construct TypeDecTrans [type_decision_translation]
        %'typedef 'enum '{ Enumerators'} TagTypeName ';
	'typedef 'struct {
	    TagTypeName 'type ';	% Variable to hold the type of the item selected in the union
	    'union '{
		body
	    '} 'item;			% Union is represented by the name 'item'
	} UniqueName ;

    construct TypeDecTrans2 [repeat rule_definition]
    	TypeDecTrans
    by
        TypeDecTrans2
	    [. CallbackFunction]
	    [. ParseFunction]
	    [. FreeFunction]
	    [. Rest]
end rule


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate enum type for type decision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function addTagForEachType aType [type_reference]
    replace [list enumerator]
    	Enums [list enumerator]
    by
    	Enums [addEnumIfNoDot aType]
	      [addEnumIfDot aType]
end function

function addEnumIfNoDot aType [type_reference]
    deconstruct aType
    	Name [id] Annot [annotation]
    construct TagName [id]
    	Name [+ '_VAL]
    replace [list enumerator]
    	Enums [list enumerator]
    by
        TagName ,
    	Enums
end function

function addEnumIfDot aType [type_reference]
    deconstruct aType
    	_ [id] . Name [id] Annot [annotation]
    construct TagName [id]
    	Name [+ '_VAL]
    replace [list enumerator]
    	Enums [list enumerator]
    by
        TagName,
    	Enums
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate fields of union type for type decision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function addUnionElementForEachType aType [type_reference]
    replace [repeat member_declaration]
    	Elements [repeat member_declaration]
    by
    	Elements
	    [addUnionElementIfNoDot aType]
	    [addUnionElementIfDot aType]
end function

function addUnionElementIfNoDot aType [type_reference]
    deconstruct aType
    	Name [id] Annot [annotation]
    construct Member [member_declaration]
    	Name Name [tolower];
    replace [repeat member_declaration]
    	Elements [repeat member_declaration]
    by
    	Elements [. Member]
end function

function addUnionElementIfDot aType [type_reference]
    deconstruct aType
    	_ [id] . Name [id] Annot [annotation]
    construct Member [member_declaration]
    	Name Name [tolower];
    replace [repeat member_declaration]
    	Elements [repeat member_declaration]
    by
    	Elements [. Member]
end function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% Step 1 - Structure Type 
% Structure Type Decisions become c structures with one or more C fields for
% each element
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

rule translateTypeStructs Exports [opt export_block]
    replace [repeat rule_definition]
	'[ UniqueName [id] '^ ShortName [id] '] Annot [annotation] '::= 'SEQUENCE  SZ [opt size_constraint]  '{
		Elements [list struct_element] _[opt ',]
	'}
	SclAdd [opt scl_additions]
	Rest [repeat rule_definition]
 

    construct body [repeat member_declaration]
	_ [addMemberForEachElement SclAdd each Elements]

    construct CallbackFunction [repeat rule_definition]
        _ [addGeneralCallback UniqueName SclAdd]
	  [addSubmessageCallback UniqueName SclAdd]

    construct ParseFunction [repeat rule_definition]
        _ [addParseFunction UniqueName Exports]

    construct FreeFunction [repeat rule_definition]
        _ [addFreeFunction UniqueName Exports]
    
    construct CStruct [type_rule_translation]
	'typedef 'struct {
	    body
	} UniqueName ;

    construct CStruct2 [repeat rule_definition]
    	CStruct
    by
    	CStruct2
	    [. CallbackFunction]
	    [. ParseFunction]
	    [. FreeFunction]
	    [. Rest]
end rule

function addMemberForEachElement SclAdd [opt scl_additions] anElement [struct_element]
    replace [repeat member_declaration]
        Elements [repeat member_declaration]
    by
    	Elements
	   [addSizeBasedType anElement]
	   [addExternalSizeBasedType anElement]
	   [addSizeBasedOptionalType anElement]
	   [addExternalSizeBasedOptionalType anElement]
	   [addSetOfType anElement]
	   [addExternalSetOfType anElement]
	   [addInteger anElement]
	   [addReal anElement]
	   [addDynamicOctetString anElement]
	   [addStaticOctetString anElement]
	   [addStaticOctetStringLarge anElement]
	   [addPositionField anElement]
	   [addSlackField anElement SclAdd]
	   [addSlackModField anElement SclAdd]
end function

% Function to generate the variable for a [size_based_type] definition;
% This is a variable with a user defined type
% must not be optional
function addSizeBasedType anElement [struct_element]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] ElementType [id] '('SIZE 'DEFINED') TypeAttr [repeat type_attribute]

    deconstruct not * [optional] TypeAttr
    	'OPTIONAL

    construct Decl [member_declaration]
	ElementType ShortName [tolower] ';

    replace [repeat member_declaration]
	Members [repeat member_declaration]
    by
	Members [. Decl]	% Append variable to the body
end function

function addExternalSizeBasedType anElement [struct_element]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] ModualName[id] . ExportedType [id] '('SIZE 'DEFINED') TypeAttr [repeat type_attribute]

    deconstruct not * [optional] TypeAttr
    	'OPTIONAL

    construct Decl [member_declaration]
	ExportedType ShortName [tolower] ';

    replace [repeat member_declaration]
	Members [repeat member_declaration]
    by
	Members [. Decl]	% Append variable to the body
end function

% Function to generate the variable for a [size_based_type] definition; 
% This is a variable with a user defined type declared as a pointer
function addSizeBasedOptionalType anElement [struct_element]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] ElementType [id] '('SIZE 'DEFINED') TypeAttr [repeat type_attribute]

    % must have optional
    deconstruct * [optional] TypeAttr
    	'OPTIONAL

    construct Decl [member_declaration]
	ElementType * ShortName [tolower] ';	% Pointer variable
    replace [repeat member_declaration]
	MD [repeat member_declaration]
    by
	MD [. Decl]	% Append variable to the body
end function

% Function to generate the variable for a [size_based_type] definition; 
% This is a variable with a user defined type declared as a pointer
function addExternalSizeBasedOptionalType anElement [struct_element]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] ModuleName [id] . ExternalType [id] '('SIZE 'DEFINED') TypeAttr [repeat type_attribute] 

    % must have optional
    deconstruct * [optional] TypeAttr
    	'OPTIONAL

    construct Decl [member_declaration]
	ExternalType * ShortName [tolower] ';	% Pointer variable
    replace [repeat member_declaration]
	MD [repeat member_declaration]
    by
	MD [. Decl]	% Append variable to the body
end function

function addSetOfType anElement [struct_element]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] 'SET 'OF ElementType [id]  '('SIZE 'CONSTRAINED') TypeAttr [repeat type_attribute]

    construct Decl [repeat member_declaration]
	'unsigned 'long ShortName [+ "length"] [tolower]';
	'unsigned 'long ShortName [+ "Count"] [tolower]';
	ElementType '* ShortName[tolower]';

    replace [repeat member_declaration]
	MD [repeat member_declaration]
    by
	MD [. Decl] % Append variables to the body
end function

function addExternalSetOfType anElement [struct_element]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] 'SET 'OF ModuleName [id] . ExternalType [id]  '('SIZE 'CONSTRAINED') TypeAttr [repeat type_attribute]

    construct Decl [repeat member_declaration]
	'unsigned 'long ShortName [+ "length"] [tolower]';
	'unsigned 'long ShortName [+ "Count"] [tolower]';
	ExternalType '* ShortName[tolower]';

    replace [repeat member_declaration]
	MD [repeat member_declaration]
    by
	MD [. Decl] % Append variables to the body
end function



% Function to generate the variable for an [integer_type] definition;
% This is a variable with a specified number of bits required. It is
% stored as a uint# where the # is calculated from the [element_type]

define number_pair
    [number] [number]
end define

function addInteger anElement [struct_element]
	deconstruct anElement
	    '[ Unique [id] '^ ShortName [id] '] Annots [annotation] 'INTEGER '( 'SIZE Size [number] 'BYTES ') TypeAttr [repeat type_attribute]

	% current implmentation limited to 64 bit integers
	% Also have to round the number to the nearest integer size

	% TODO, TD 2021 should we have round everyitng to 32/64? Does it matter
	% for speed?


	% remove this message if we implement bigints in a separate rule in the future.
	construct Msg [number]
		Size [checkMaxNumberSize 'integer '8]

	where
		Size [<= 8]	% If the number of bytes is greater than 8 it
				% cannot be represented as a uint
	construct SizeTable [repeat number_pair]
	   1 8 2 16 3 32 4 32 5 64 6 64 7 64 8 64

	deconstruct * [number_pair] SizeTable
		Size NumBits [number]

	construct IntType [id]
	   _ [+ 'uint] [+ NumBits] [+ '_t]

	construct Decl [member_declaration]
		IntType ShortName [tolower] ';

	replace [repeat member_declaration]
	    MD [repeat member_declaration]
	by
	    MD [. Decl]	% Append variable to the body
end function


function checkMaxNumberSize Type [id] Max [number]
    match [number]
	N [number]
    where
    	N [> Max]
    construct Msg [stringlit]
    	_ [+ '"Error: Size "]
	  [+ N]
	  [+ '"is larger than the maximum implemented "]
	  [+ Type]
	  [+ '"size("]
	  [+ Max]
	  [+ '")"]
	  [print]
end function


function checkRealSizes ShortName [id]
   match [number]
   	N [number]
   where not 
   	N [= '4]
	  [= '8]
   construct Msg [stringlit]
   	_ [+ '"Size "]
	  [+ N]
	  [+ '" of REAL field "]
	  [+ ShortName]
	  [+ '" is not 4 or 8"]
	  [print]
end function

% Function to generate the variable for an [real_type] definition;
% This is a variable with a specified number of bits required in 
% floating point precision. only 4 -> float and 8 -> double is supported

function addReal anElement [struct_element]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] 'REAL '( 'SIZE Size [number] 'BYTES ') TypeAttr [repeat type_attribute]

    construct Msg [number]
	Size [checkRealSizes ShortName]

    where
	Size [= 4]	% 4 bytes equates to float predefined size
	     [= 8]
    
    construct RealType [id]
    	_ [addIf 'float '4 Size]
	  [addIf 'double '8 Size]

    construct Decl [member_declaration]
	RealType ShortName [tolower] ';
	
    replace [repeat member_declaration]
	MD [repeat member_declaration]
    by
	MD [. Decl]	% Append variable to the body
end function

function addIf Type [id] TargetSize [number] FieldSize[number]
    where
    	TargetSize [= FieldSize]
    replace [id]
    	_ [id]
    by
    	Type
end function

% Function to generate the variable for a dynamic [octet_type] definition;
% This is a variable with a dynamic size, defined externally. It is represented
% as a character pointer which will be dynamically allocated during the parse.
% The length is stored in a variable for reference

function addDynamicOctetString anElement [struct_element]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] 'OCTET 'STRING '( 'SIZE 'CONSTRAINED ') TypeAttr [repeat type_attribute]

    construct Decl [repeat member_declaration]
	unsigned 'long ShortName [+ "_length" ][tolower]';	% Size of the pointer array
	'unsigned 'char '* ShortName [tolower]';		% Dyanmic pointer array

    replace [repeat member_declaration]
	MD [repeat member_declaration]
    by
	MD [. Decl]	% Append variable to the body
end function


% Function to generate the variable for an [octet_type] definition;
% This is represented as a uint with a static size to hold all the info
% which is determined from the [element_type] definition

function addStaticOctetString anElement [struct_element]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] 'OCTET 'STRING '( 'SIZE Size [number] 'BYTES ') TypeAttr [repeat type_attribute]

    where
	Size [<= 8]	% If the number of bytes is greater than 8 it
			% cannot be represented as a uint

    construct SizeTable [repeat number_pair]
	1 8 2 16 3 32 4 32 5 64 6 64 7 64 8 64

    deconstruct * [number_pair] SizeTable
	Size NumBits [number]

    construct IntType [id]
       _ [+ 'uint] [+ NumBits] [+ '_t]

    construct Decl [member_declaration]
	IntType ShortName[tolower]';

    replace [repeat member_declaration]
	MD [repeat member_declaration]
    by
	MD [. Decl]	% Append variable to the body
end function


% Function to generate the variable for an [octet_type] definition;
% This is represented as a character array with a static size 
% that is determined from the [element_type] definition as the
% size is too large for a uint
function addStaticOctetStringLarge anElement [struct_element]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] 'OCTET 'STRING '( 'SIZE Size [number] 'BYTES ') TypeAttr [repeat type_attribute]
    where
	Size [> 8]	% If the size is greater than 8 bytes it is too
					% large to store in a uint and must be stored in
					% an array
    construct Decl [member_declaration]
	'unsigned 'char ShortName[tolower] '[ Size '];

    replace [repeat member_declaration]
	MD [repeat member_declaration]
    by
	MD [. Decl]	% Append variable to the body
end function

% psotiion fields are added if there is either a SAVEPOS in the type or
% an @POS in the Annots
function addPositionField anElement [struct_element]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] Type [type]

    construct IsThereAPos [number]
    	_ [OneIfSAVEPOSInType Type]
	  [OneIfPOSInAnnots Annots]

    where
    	IsThereAPos [= '1]

    construct Decl [member_declaration]
	'uint32_t  ShortName[tolower] [+ '"_POS"] ';
    replace [repeat member_declaration]
	MD [repeat member_declaration]
    by
	MD [. Decl]	% Append variable to the body
end function

function OneIfPOSInAnnots Annots [annotation]
    deconstruct * [position_used] Annots
    	'@ 'POS
    replace [number]
    	_ [number]
    by
    	'1
end function

% If a field of a uswer defined type is the subject of a length constraint, it may not take
% up the length constraint. The remaining bytes of the length constraint are skipped as slack bytes
% to represent this in the data structure we have an integer field that holds how many bytes were skipped.
function addSlackField anElement [struct_element] SclAdd [opt scl_additions]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] ElementType [id] '('SIZE 'DEFINED') TypeAttr [repeat type_attribute]


    deconstruct * [slack] TypeAttr
    	SLACK _ [opt MODNUM]


    deconstruct * [construction_parameter] SclAdd
    	LENGTH '( '[ Unique '^ ShortName '] ') '== _ [additive_expression] _ [opt size_unit]

    construct Decl [member_declaration]
	'unsigned 'long  ShortName[tolower] [+ '"_SLACK"] ';
    replace [repeat member_declaration]
	MD [repeat member_declaration]
    by
	MD [. Decl]	% Append variable to the body
end function

function addSlackModField anElement [struct_element] SclAdd [opt scl_additions]
    deconstruct anElement
	'[ Unique [id] '^ ShortName [id] '] Annots [annotation] ElementType [id] '('SIZE 'DEFINED') TypeAttr [repeat type_attribute]


    deconstruct * [slack] TypeAttr
    	SLACK _ [MODNUM]

% not sure if we need the number in the field name, probably not
    construct Decl [member_declaration]
	'unsigned 'long  ShortName[tolower] [+ '"_SLACKMOD"] ';
    replace [repeat member_declaration]
	MD [repeat member_declaration]
    by
	MD [. Decl]	% Append variable to the body
end function

function OneIfSAVEPOSInType Type [type]
    deconstruct * [save_position] Type
    	'SAVEPOS
    replace [number]
    	_ [number]
    by
    	'1
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General Utiliy Rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%deep bubble sort
% given A B Rest in middle of list, if a type used in 
% A is defined anywhere in B or Rest, then swap A and B

rule sortStructs
   replace [struct_container]
      SC [struct_container]
   construct NewSC [struct_container]
      SC [sortPass]
   deconstruct not NewSC
      SC
   by
      NewSC
end rule

rule sortPass
   replace $ [repeat type_translation]
       TranslatedType [type_translation]
       Rest [repeat type_translation]
   construct Members [repeat member_declaration]
   	_ [^ TranslatedType]
   construct Refs [repeat type_specifier]
   	_ [^ Members]
   where
   	Rest [containsDeclarationOf each Refs]
   by
       Rest [swapWithTop TranslatedType]
end rule

function containsDeclarationOf aRef [type_specifier]
    deconstruct aRef
    	TypeName [id]
    match * [declaration]
        'typedef struct Body [struct_or_union_body] TypeName ';
end function

function swapWithTop FirstTranslatedType [type_translation]
   replace [repeat type_translation]
       SndTranslatedType [type_translation]
       Rest [repeat type_translation]
   by
       SndTranslatedType %%[message "swapped"]
       FirstTranslatedType
       Rest
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add general callback function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function addGeneralCallback UniqueName [id] SclAdd [opt scl_additions]
    % Only support unannotated Callback Statement fron user
    % not from annotation for submessage callback.
    %deconstruct  * [transfer_statement] SclAdd
    	%'Callback
    where
    	SclAdd [hasPlainCallback]
	       [hasSubmessageOptimizedCallback]

    replace [repeat rule_definition]
	_ [repeat rule_definition]

    construct FunctionName [id]
    	UniqueName [+ '_callback]

    construct CallBack [callback_function]
    	'void  FunctionName '( UniqueName '* UniqueName [tolower] , PDU * thePDU ) ;
    	
    by
        CallBack
end function

function hasPlainCallback
    match * [transfer_statement] 
    	'Callback 
end function

function hasSubmessageOptimizedCallback
    match * [transfer_statement] 
    	'Callback @ _ [id] _ [id]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Submessage Callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function addSubmessageCallback UniqueName [id] SclAdd [opt scl_additions]
    % Add submessage callback using Callback annotation from submessage markup
    deconstruct  * [transfer_statement] SclAdd
    	'Callback ParentUID [id] ParentField [id]
    replace [repeat rule_definition]
	_ [repeat rule_definition]

    construct FunctionName [id]
    	UniqueName [+ '_callback]

    construct CallBack [callback_function]
    	'void  FunctionName '( ParentUID * ParentUID [tolower] , UniqueName '* UniqueName [tolower] , PDU * thePDU ) ;
    	
    by
        CallBack
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add parse and free function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function addParseFunction UniqueName [id] Exports [opt export_block]
    deconstruct * [id] Exports
        UniqueName
    replace [repeat rule_definition]
	_ [repeat rule_definition]

    construct FunctionName [id]
        _ [+ 'parse]
    	  [+ UniqueName]

    construct ParseFn [parse_function]
    	'bool  FunctionName '( UniqueName '* UniqueName [tolower] , PDU * thePDU, char * name, uint8_t endianness ) ;
    	
    by
        ParseFn
end function

function addFreeFunction UniqueName [id] Exports [opt export_block]
    deconstruct * [id] Exports
        UniqueName
    replace [repeat rule_definition]
	_ [repeat rule_definition]

    construct FunctionName [id]
        _ [+ 'free]
    	  [+ UniqueName]

    construct FreeFn [free_function]
    	'void  FunctionName '( UniqueName '* UniqueName [tolower] ) ;
    	
    by
        FreeFn
end function

function addEnums TagTypeName [id]

    replace [repeat rule_definition]
        Rules [repeat rule_definition]

    import Tags [list enumerator]
    % at least one tag
    deconstruct Tags
    	_ [enumerator] , Rest [list enumerator]

    construct EnumDef [enum_translation]
        'typedef 'enum '{ Tags [removeDuplicateTags] '} TagTypeName ';
    by
        EnumDef
	Rules
end function

function removeDuplicateTags
   replace [list enumerator]
      T1 [enumerator] , Rest [list enumerator]
   by T1 ,
      Rest [removeAllTag T1]
           [removeDuplicateTags]
end function

rule removeAllTag T1 [enumerator]
   replace [list enumerator]
      T1 , Rest [list enumerator]
   by
      Rest
end rule

function addModules Imports [opt import_block]
    replace [repeat rule_definition]
	Rules [repeat rule_definition]

    deconstruct * [list import_list+] Imports
    	Import_List [list import_list+]

    construct Includes [repeat rule_definition]
    	_  [includeModDef Rules each Import_List]
    by
    	Rules [. Includes]
end function

function includeModDef Rules [repeat rule_definition] anImportList [import_list]
    replace [repeat rule_definition]
        Defs [repeat rule_definition]

    deconstruct anImportList
	_ [list decl] 'FROM ModName [id]

%TODO - need a deep deconstruct in to rules to verify that Module is used.

    construct IncludeString [stringlit]
    	_ [+ "#include \""]
	  [+ ModName]
	  [+ '"_Definitions.h\""]

    construct  IncludeLine [preprocessor_line]
        _ [parse IncludeString]
    construct ImportLine [import_translation]
    	IncludeLine

    construct RD [rule_definition]
    	ImportLine
    by
        Defs [. RD]
end function
