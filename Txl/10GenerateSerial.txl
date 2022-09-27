%+
% 09GenerateSerial.txl
%   - generate code to reserialized the structures.
%
%   - note that the constraints are not used in the serialization
%     as thee
%
% Copyrights, Thomas Dean, Ali El Shakankiry, Kyle Lavorato
%-

% Base grammars

include "c.grm"
include "ASNOne.Grm"
include "annot.ovr"


%==================================================================================
% overrides for C translation
%
% The old generator had a lot of redundant code that was used to produce the 
% appropriate forward prototype header at the top for the code that was
% later in the body. Other aux functions had to be put in the appropriate place.
%
% In this approach we use the grammar to classify the C code. When we generate
% the code for a SCL entity, it has three parts, a protype a parse function
% and a free function. By using the grammar to type each of these, we
% can easily identify them and move them to the correct place in the file.
%
%==================================================================================

redefine module_definition
    ...
  | [repeat c_translation]
end redefine

redefine rule_definition
    ...
  | [c_translation]
end redefine

define c_translation
     [public_serialize_prototype]
   | [private_serialize_prototype]
   | [serialize_function]
end define

define public_serialize_prototype
    [function_definition_or_declaration]
end define

define private_serialize_prototype
    [function_definition_or_declaration]
end define

define serialize_function
    [function_definition_or_declaration]
end define


% overrides for translating expressions in Constraints
redefine if_statement
     ...
   | 'if '( [relational_expression] ')
       [sub_statement]
      [opt else_statement]
end redefine

redefine dotReference
    ...
  | '-> [id]
end redefine

%========================================================================
% Main
%========================================================================

function main
    replace [program]
        P [program]

    construct NewArgs [number]
    	_ [convertFlagsToGlobals]

    export NullId [id]
    	_ [unquote '"NULL"]

    by
       P [convertEachModule]
         [insertHeaders]
end function

%========================================================================
% flags passed on the command line are recognized and converted
% to TXL global variables.
% 
% the flags are:
%  nocallback - don't generate calls for callback annotation. Instead
%    the entire data structure is returned to the function calling the parser
%  nosubmessage - onely applies when using callbacks. Normally if a structure
%    that is used for a callback ends with a repeat of a user defined type,
%    then a separate callback is defined for each of the submessags, the callback
%    inclues the parent data strcture as well. This flag supresses the separate
%    callback for submessages, and only one callback is made on the main message
%    which will have the submessages as part of the structure
%  noFreeAfterCallaback - nomrally in the callback style, the calling function
%    is not interested in the generated data strcture, so it is freed after
%    the callback is made. This suppresses the free, and the calling function
%    has to free the data structure.
% debug - include code to trace the parser while running
%========================================================================

function convertFlagsToGlobals
    replace [number]
    	Zero [number]

    % The flag -nocallback suppresses generation of
    % callbacks
    export noCallbackArg [number]
	Zero [checkTXLargs '"-nocallback"]

    % the flag -nosubmessage suppresses the submessage
    % callback optimization
    export noSubMsgArg [number]
	Zero [checkTXLargs '"-nosubmessage"]	

    % the flag -noFreeAfterCallback
    % callback optimization
    export noFreeAfterCallback [number]
	Zero [checkTXLargs '"-noFreeAfterCallback"]	

  
    construct traceFileString [stringlit]
    	_ [checkTXLargsString "-traceFileID"]
    export traceFileID [id]
        _ [+ traceFileString]

    % the flag -debug adds debugging code
    % to the parser
    export debugArg [number]
	Zero [checkTXLargs '"-debug"]
	[checkTraceFile traceFileString]


    by
    	Zero
end function

function checkTraceFile traceFileString [stringlit]
    replace [number]
    	N [number]
    where
    	N [> 0]
    construct traceStringLen [number]
    	_ [# traceFileString]
    deconstruct traceStringLen
	0
    by
    	N [message "******** Must specify traceFileID if debug is specified"]
end function

% aux function for convertFlagsToGlobals
function checkTXLargs Arg [stringlit]
    import TXLargs [repeat stringlit]
    deconstruct * [stringlit] TXLargs
	Arg
    replace [number]
	num [number]
    by
	'1
end function

function checkTXLargsString Arg [stringlit]
    import TXLargs [repeat stringlit]
    deconstruct * [repeat stringlit] TXLargs
	Arg Val [stringlit] Rest [repeat stringlit]
% TODO - confirm VAL does not start with '-'
    replace [stringlit]
	num [stringlit]
    by
	Val
end function

%========================================================================
% insertHeaders
%
% This rule is run after the code generation to insert the include 
% statements needed to compile the parsing functions. The first include
% statement is for the .h file for this spec file (e.g. Dns_Defitions.h)
% and then adds the common headers for the support files.
%========================================================================

function insertHeaders
    import TXLinput [stringlit]

    construct StemName [stringlit]
    	TXLinput
	    [trimToBase]
	    [removeAfterUnderscore]

    construct  IncludeStr [stringlit]
    	_ [+ "#include \""] [+ StemName] [+ '"Definitions.h\""]
    construct  IncludeLine [preprocessor_line]
    	_ [parse IncludeStr]

    construct  IncludeStr2 [stringlit]
    	_ [+ "#include \""] [+ StemName] [+ '"Serialize.h\""]
    construct  IncludeLine2 [preprocessor_line]
    	_ [parse IncludeStr2]

   replace * [repeat module_definition]
      Mods [repeat module_definition]
   by
     '#include "globals.h"
     '#include "sutilities.h"
     IncludeLine
     IncludeLine2
      Mods
end function

% used by insertHeaders
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

% used by insertHeaders
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

%=========================================================================================
% convertEachModule
%
% main driver routine for code generation. Generate parser functions for each
% module in the file.
% 
% The generateFunctions rules creates the code in place, using non-terminals to classify
% each type of code. The replace by C function extracts each type of code to place
% in the right place in the file. It also remove any extraneous text that remains
% after the code generation.
%=========================================================================================

rule convertEachModule
    replace $ [module_definition]
        M [module_definition]
    by
    	M [generateFunctions]
	  [replaceByC]
end rule


%=========================================================================================
% Some SCL language constructs create Derived Types. For exmaple, a SEQUENCE field
%   foo SET of BAR, creates the type used for the array of BAR. Since SET of BAR
%   may be the type of more than one field in the file, this can create redundant derived
%   types and redundant code. In particular, if the second SET of BAR field occured in the
%   same SEQUENCE, the unique naming failed in the old generator. Instead we record
%   the occurences of the type, including the method by which the length is constrained
%   in a global variable using the set_of_function type, and generate a single set of
%   parsing routines for them.
%
% Data structure used to record the set of/sequence of type
% they can be terminated by cardinality, length or a sub type
% values are type (Card/Len/Term/End), Type, parseFunctionName, ShortTypeName, endType (if needed)
%=========================================================================================

define set_of_function
   [id] [id] [id] [id] [opt id]
end define

%=========================================================================================
% Driver function for generating code in place. Matches a module and rplaces the 
% contents of the module by code in place. Some of the original SCL strucutre remains
% after this rule.
%=========================================================================================

function generateFunctions
    replace  [module_definition]
	ModuleName [id] 'DEFINITIONS ::= 'BEGIN
	    Exports [opt export_block]
	    Imports [opt import_block]
	    AllRules [repeat rule_definition]
	'END

    % export the debug variable if needed
    export indent [id]
	_ [+ '"indent_"] [+ ModuleName]


    % Extract a copy of all the standard type rules in the Module
    construct TypeRules [repeat type_rule_definition]
	_ [^ AllRules]

    % Extract a copy of all the type decision rules in the program
    construct TypeDecisions [repeat type_decision_definition]
	_ [^ AllRules]

    % initial list of array function types is empty
    export SetOfFunctions [repeat set_of_function]
        _

    by
	ModuleName 'DEFINITIONS ::= 'BEGIN
	    Exports
	    Imports
	    AllRules
	        [addProtoForExternal ModuleName Imports]
	        [generateStructTypeFunctions ModuleName Exports TypeRules TypeDecisions]
	        [generateTypeDecFunctions ModuleName Exports TypeRules TypeDecisions]
	'END
end function

%========================================================================================
% Reorganize the code. For each module the code order is:
%    1. the prototype headers for the private functions
%    2. the parse function
%    2. the free functions
%
% this module also removes the remaining SCL code. I.e. the defintions/END lines
% and the export and import statements.
%========================================================================================

% TODO - may also have to export to global to write the header file.
% or put markers around them to make them easier to extract???

function replaceByC
    replace  [module_definition]
	ModuleName [id] 'DEFINITIONS ::= 'BEGIN
	    Exports [opt export_block]
	    Imports [opt import_block]
	    AllRules [repeat rule_definition]
	'END

    construct PublicFunctionProtos [repeat public_serialize_prototype]
    	_ [^ AllRules]
    construct PublicFunctionProtosC [repeat c_translation]
    	_ [reparse PublicFunctionProtos]

    construct PrivateFunctionProtos [repeat private_serialize_prototype]
    	_ [^ AllRules]
    construct PrivateFunctionProtosC [repeat c_translation]
    	_ [reparse PrivateFunctionProtos]

    construct SerializeFunctions [repeat serialize_function]
    	_ [^ AllRules]
    construct SerializeFunctionsC [repeat c_translation]
    	_ [reparse SerializeFunctions]
    by
   	PublicFunctionProtosC
   	    [. PrivateFunctionProtosC]
	    [. SerializeFunctionsC]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 1 - generate functions for struct types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sequence/set functions. ASN.1 makes a distinction
% between them for DER/BER encoding that we currently
% do not implement in the compiled version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule generateStructTypeFunctions ModName [id] Ex [opt export_block] TPRules [repeat type_rule_definition] TypeDec [repeat type_decision_definition]
    replace [repeat rule_definition]
	'[ UniqueID [id] '^ ShortID [id] '] ANN [annotation]'::= 'SEQUENCE '{
	    Elements [list struct_element] OC [opt ',]
	'} OptScl [opt scl_additions]
	Rest [repeat rule_definition]
    construct Parse [repeat rule_definition]
        _ [generateStructSerializeFunction UniqueID Ex TPRules TypeDec Elements OptScl]
    by
        Parse
    	 [. Rest]
end rule

%=========================================================================
% parse function for a structure
%
% In general, some of the fields are of constant size, even if they are a
% in turn a structure(a structure of constant size). Some of the fields
% are variable size (i.e. set/SEQ of type, constriained strings, etc).
% We have to emit code to check if there are enough bytes left to read
% a field. If the structure starts with a set of constant fields, wec
% and make on length check before reading all of the fields.
%
%   E.g. SEQUEENCE {
%		a INT 4
%		b INT 4
%		c INT 2
%		d INT 2 (OPTIONAL)
%         }
% so instead of checking the length of a, b, and c individually, we
% can check that there are 10 bytes available, and then read a, b and c.
%
% So the first parat of the function finds the partition point between
% the constant fields and the firsr non-constant field.
% if there are vaiable eleents (so we don't know right off if there are enough
% bytes to read, then we generate save variables.
%=========================================================================

function generateStructSerializeFunction RuleName [id] Ex [opt export_block] TPRules [repeat type_rule_definition] TypeDec [repeat type_decision_definition] Elements [list struct_element] SclAdd [opt scl_additions]

     % partition elements To those before the first var and those after the first var
     % We can use one check to see if there are enough bytes for the const size
     % elements at the beginning of the type.
     construct ConstElements [list struct_element]
        Elements %[message '"**************The Elements Are:"]
	         %[print]
		 %[message '"*********************************"]
		 %[message '"***************Const Elements Are:"]
		 [removeVarElements1]
		 [removeVarElements2]
		 [removeVarElements3]
		 %[print]
		 %[message '"*********************************"]

     construct VarElements [list struct_element]
        Elements [removeConstElements]
		 %[message '"***************Var Elements Are:"]
		 %[print]
		 %[message '"*********************************"]

     % TODO: also have to filter the back constraints to remove the ones that have already
     % been used in lookahead. - how do we know?

     % equivalent to Read Fields - needed for Endian constraint to write. 
     export SerializedFields [repeat id]
     	_

     export EndianConstraints [repeat immediate_endian_change]
        _ [^ SclAdd]

     construct SerializeFunctionName [id]
        _ [+ 'serialize]
	  [+ RuleName]

     construct Type [repeat decl_qualifier_or_type_specifier+]
         'SerializeBuffer 

     construct ParmName [id]
     	RuleName [tolower]

     construct Body [repeat declaration_or_statement]
        _ %[addDebugEnter ParseFunctionName]
	  [addProtectedConstWrite ConstElements RuleName ParmName SclAdd SerializeFunctionName]
	  [addUnprotectedVarWrite VarElements RuleName ParmName SclAdd SerializeFunctionName]
	  %[addDebugSucceed ParseFunctionName]
	  [addReturnBuff]

     construct SerializeFunction [serialize_function]
        Type  [addStaticIfNotExternal RuleName Ex]
	'* SerializeFunctionName(SerializeBuffer * buff, RuleName * ParmName, char * name, uint8_t endianness){
	    Body
	}

     replace [repeat rule_definition]
     	Functions [repeat rule_definition]
     by
        SerializeFunction
        Functions
	    [addProtoIfPrivate SerializeFunctionName RuleName Ex ParmName]
	    [addProtoIfPublic SerializeFunctionName RuleName Ex ParmName]
end function

% if the parse rule is not for an exported type, then it is private
% so delcare it static so it can't conflict with any other functions in
% other modules.
function addStaticIfNotExternal RuleName [id] Ex [opt export_block]
   deconstruct not * [id] Ex
   	RuleName
   replace [repeat decl_qualifier_or_type_specifier+]
     Type [repeat decl_qualifier_or_type_specifier]
   by
     'static Type
end function

% if it is a private function, then the prototype wasn't in the header
% file that was generated for the module. So generate a header so
% we don't have to worry about function order.
function addProtoIfPrivate ParseFunctionName  [id] RuleName [id] Ex [opt export_block] ParmName[id]
    deconstruct not * [id] Ex
   	RuleName
     construct ParseFunction [private_serialize_prototype]
	'static 'SerializeBuffer '* ParseFunctionName('SerializeBuffer '* 'buff, RuleName * ParmName, char * name, uint8_t endianness);
     replace [repeat rule_definition]
     	Functions [repeat rule_definition]
     by
        ParseFunction
        Functions
end function

function addProtoIfPublic ParseFunctionName  [id] RuleName [id] Ex [opt export_block] ParmName[id]
    deconstruct * [id] Ex
   	RuleName
     construct ParseFunction [public_serialize_prototype]
	'SerializeBuffer '* ParseFunctionName('SerializeBuffer '* 'buff, RuleName * ParmName, char * name, uint8_t endianness);
     replace [repeat rule_definition]
     	Functions [repeat rule_definition]
     by
        ParseFunction
        Functions
end function

function addProtoForExternal ModuleName  [id] Imports [opt import_block]
    deconstruct * [list import_list] Imports
    	ModuleImport [list import_list]	

    replace [repeat rule_definition]
	Functions [repeat rule_definition]
    by
	Functions [addProtoEachModule each ModuleImport]
end function

function addProtoEachModule ImportedModule [import_list]
    deconstruct ImportedModule
	ImportedTypes [list decl] 'FROM ModName [id]

    replace [repeat rule_definition]
	Functions [repeat rule_definition]
    by
	Functions [addProtoEachModuleType each ImportedTypes]
end function

function addProtoEachModuleType ImportedType [decl]
     deconstruct ImportedType
     	'[ Unique [id] '^ Short [id] ']

     construct WriteFunctionName [id]
         _ [+ 'serialize]
	   [+ Unique]

     construct WriteFunction [public_serialize_prototype]
	'SerializeBuffer '* WriteFunctionName ('SerializeBuffer '* 'buff, Unique * Unique [tolower], char * name, uint8_t endianness);
     replace [repeat rule_definition]
     	Functions [repeat rule_definition]
     by
        WriteFunction
        Functions
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rules to partition the list of structure elements at the first VAR element
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function removeVarElements1
    replace [list struct_element]
        Element1 [struct_element],
        Element2 [struct_element],
	Rest [list struct_element]
    deconstruct * [const_pos_size_annotation] Element1
    	_ [const_pos_size_annotation]
    deconstruct * [var_pos_size_annotation] Element2
    	_ [var_pos_size_annotation]
    by
        Element1
end function

function removeVarElements2
    replace [list struct_element]
        Element1 [struct_element],
	Rest [list struct_element]
    deconstruct * [const_pos_size_annotation] Element1
    	_ [const_pos_size_annotation]
    by
        Element1,
        Rest [removeVarElements1]
	     [removeVarElements2]
end function

function removeConstElements
    replace [list struct_element]
        Element1 [struct_element],
	Rest [list struct_element]
    deconstruct * [const_pos_size_annotation] Element1
    	_ [const_pos_size_annotation]
    by
	Rest [removeConstElements]
end function

% special case, all elements are var
function removeVarElements3
    replace [list struct_element]
        Element1 [struct_element],
	Rest [list struct_element]
    deconstruct * [var_pos_size_annotation] Element1
    	_ [var_pos_size_annotation]
    by
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the first elements of a structure from the buffer that are all constant size
% we can protect all of the 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function addProtectedConstWrite ConstElements [list struct_element] RuleName [id] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
    construct Msg [list struct_element]
        ConstElements [warnIfVarAnnotation RuleName]

    deconstruct not * [var_pos_size_annotation] ConstElements
   	_ [var_pos_size_annotation]

    % get pos and size of last element
    deconstruct * [list struct_element] ConstElements
       LastElement [struct_element]
    deconstruct * [const_pos_size_annotation] LastElement
    	'@ 'CONST Pos [number] Size [number]

    construct FailStmts [repeat declaration_or_statement]
       _ %[addDebugFail FunctionName]
         [addReturnNull]

    import NullId [id]

    construct Guard [declaration_or_statement]
        if (('buff = 'SerializeBufferAllocate('buff, Pos [+ Size])) == NullId){
	    FailStmts
	}

    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    by
	Stmts
	   [. Guard]
	   [addProtectedWrite RuleName ParmName SclAdd FunctionName each ConstElements]
end function

%========================================
% if the parser reaches the end of the function, a succssful parse has been made.
%========================================
% if the parser reaches the end of the function, a succssful parse has been made.

function addReturnBuff
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    construct ReturnTrue [declaration_or_statement]
        'return 'buff;
    by
    	Stmts [. ReturnTrue]
end function

function warnIfVarAnnotation RuleName [id]
   match * [var_pos_size_annotation]
   	_ [var_pos_size_annotation]
   construct Msg [stringlit]
      _ [+ '"Internal Error: addProtectedConstWrite: split of fields in struct type "]
        [+ RuleName]
	[+ '" failed"]
	[print]
end function


function addProtectedWrite RuleName [id] ParmName [id] SclAdd [opt scl_additions] FunctionName [id] aConstElement [struct_element]
    % TODO: warn if the const element is guarded by a forward constraint for some reason
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    by
	Stmts
	    % Todo expand backconstraints for non-integer fields
	    [addEndianCheck ParmName FunctionName SclAdd]
	    [addProtectedInteger aConstElement ParmName FunctionName]
	    [addProtectedOctetStringInt aConstElement ParmName FunctionName]
	    [addProtectedOctetStringChar aConstElement ParmName FunctionName]
	    [addProtectedReal aConstElement ParmName FunctionName]
	    [addProtectedUserDefinedConst aConstElement ParmName FunctionName]
end function

function addEndianCheck ParmName [id] FunctionName [id] SclAdd [opt scl_additions]

    import EndianConstraints [repeat immediate_endian_change]

    % at least one constraint to evaluate
    deconstruct EndianConstraints
        _ [immediate_endian_change] Rest [repeat immediate_endian_change]

    export EndianConstraintsToRemove [repeat immediate_endian_change]
        _

    import SerializedFields [repeat id]

    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
    by
        Stmts [evaluateEndianConstraintIfRipe ParmName SerializedFields FunctionName each EndianConstraints]
              [removeEvaluatedEndianConstraints] % TODO note only removes one.
end function

function evaluateEndianConstraintIfRipe ParmName [id] SerializedFields [repeat id] FunctionName [id] EndianConstraint [immediate_endian_change]
    deconstruct EndianConstraint
        'ENDIANNESS '== RE [relational_expression]

    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]

    construct ResolvedRE [or_expression]
        RE [convertSimpleFieldsIfWritten ParmName SerializedFields]
    deconstruct not * [referenced_element] ResolvedRE
        '[ _ [referenced_element] '^ _ [referenced_element] ']
    construct CExpr [opt assignment_cexpression]
        _ [reparse ResolvedRE]
          [putp "ENDIAN expr is %"]
    deconstruct  CExpr
        CExpr2 [assignment_cexpression]

    import EndianConstraintsToRemove [repeat immediate_endian_change]
    export EndianConstraintsToRemove
        EndianConstraint
        EndianConstraintsToRemove

    construct EndianStmt [declaration_or_statement]
        'endianness '= '( CExpr2 ') ';

    by
        Stmts [. EndianStmt]
end function

rule convertSimpleFieldsIfWritten ParmName [id] SerializedFields [repeat id]
    replace [primary]
        '[ UniqueID [id] '^ ShortId[id] ']
    deconstruct * [id] SerializedFields
        UniqueID
    by
        (ParmName -> ShortId [tolower])
end rule


function removeEvaluatedEndianConstraints
    import EndianConstraintsToRemove [repeat immediate_endian_change]

    import EndianConstraints [repeat immediate_endian_change]
    export EndianConstraints
        EndianConstraints [removeEndianConstraint each EndianConstraintsToRemove]
    match [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
end function

function removeEndianConstraint anEndianConstraint [immediate_endian_change]
     replace * [repeat immediate_endian_change]
        anEndianConstraint Rest [repeat immediate_endian_change]
     by
        Rest
end function

function addProtectedInteger aConstElement [struct_element] ParmName [id] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    deconstruct aConstElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] INTEGER '(SIZE Size [number] BYTES) TA [repeat type_attribute]

	%uint32_t get32_e(PDU * thePDU, uint8_t endianness) 
    construct Bits [number]
    	Size [* 8]
    construct WriteName [id]
    	_ [+ 'writebufferInt]
	  [+ Bits]

    import SerializedFields [repeat id]
    construct NewSerializedFields [repeat id]
        UniqueID SerializedFields
    export SerializedFields
        NewSerializedFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    construct GetStmt [declaration_or_statement]
        WriteName('buff, ParmName '-> ShortID [tolower], Endian);

    by
	Stmts [. GetStmt] 
	%[addDebugLong Size ParmName ShortID]
	%[addDebugLongLong Size ParmName ShortID]
end function

function addProtectedOctetStringInt aConstElement [struct_element] ParmName [id] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    deconstruct aConstElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] 'OCTET 'STRING '(SIZE Size [number] BYTES) TA [repeat type_attribute]

    where
    	Size [<= 8]
    construct Bits [number]
    	Size [* 8]
    construct WriteName [id]
    	_ [+ 'writebufferInt]
	  [+ Bits]

    import SerializedFields [repeat id]
    construct NewSerializedFields [repeat id]
        UniqueID SerializedFields
    export SerializedFields
        NewSerializedFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    construct GetStmt [declaration_or_statement]
        WriteName('buff, ParmName '-> ShortID [tolower], Endian);

    by
	Stmts [. GetStmt]
end function

function addProtectedOctetStringChar aConstElement [struct_element] ParmName [id] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    deconstruct aConstElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] 'OCTET 'STRING '(SIZE Size [number] BYTES) TA [repeat type_attribute]

    where
    	Size [> 8]

    import SerializedFields [repeat id]
    construct NewSerializedFields [repeat id]
        UniqueID SerializedFields
    export SerializedFields
        NewSerializedFields %[putp "NewFields are %"]
    % constant size octet strings are represented as arrays in the structures.
    % so nothing to free, as nothing is allocated
    % TODO difficult to change length for fuzzing here, maybe provide altnerate
    % pointer and length field?

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    construct GetStmt [declaration_or_statement]
        writebufferOctetStr('buff, ParmName '-> ShortID [tolower], Size,Endian);

    by
	Stmts [. GetStmt]
end function


function addProtectedReal aConstElement [struct_element] ParmName [id] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    deconstruct aConstElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] REAL '(SIZE Size [number] BYTES) TA [repeat type_attribute]

    where
    	Size [= 8] [= 4]
    construct BitSize [number]
    	Size [* 8]

    construct WriteName [id]
    	_ [+ 'writebufferReal]
	  [+ BitSize]

    import SerializedFields [repeat id]
    construct NewSerializedFields [repeat id]
        UniqueID SerializedFields
    export SerializedFields
        NewSerializedFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    construct GetStmt [declaration_or_statement]
         WriteName('buff, ParmName '-> ShortID [tolower], Endian);

    by
	Stmts [. GetStmt]
end function


function addProtectedUserDefinedConst aConstElement [struct_element] ParmName [id] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct aConstElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] TypeName [id] '(SIZE DEFINED) TA [repeat type_attribute]


    construct WriteName [id]
    	_ [+ 'serialize]
	  [+ TypeName ]

    import SerializedFields [repeat id]
    construct NewSerializedFields [repeat id]
        UniqueID SerializedFields
    export SerializedFields
        NewSerializedFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    construct GetStmt [declaration_or_statement]
        buff = WriteName(buff, &(ParmName '-> ShortID [tolower]), name, Endian);

    by
	Stmts [. GetStmt]
end function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% this should be similar to ConstGets, split at the point that VAR gos to VAR Number
% so we can use a single lengthRemaining check for contiguous Var Number.
% for now, jsut generate protection for each constant get
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

function addUnprotectedVarWrite VarElements [list struct_element] RuleName [id] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    by
	Stmts
	   [addUnprotectedGet RuleName ParmName SclAdd FunctionName each VarElements]
end function

function addUnprotectedGet RuleName [id] ParmName [id] SclAdd [opt scl_additions] FunctionName [id] aVarElement [struct_element]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    by
	Stmts
	   [addUnprotectedUserDefinedVarOptional aVarElement ParmName SclAdd FunctionName]
	   [addProtectedOctetStringInt aVarElement ParmName FunctionName]
	   [addProtectedOctetStringChar aVarElement ParmName FunctionName]
	   [addUnprotectedOctetStringConstrained aVarElement ParmName SclAdd FunctionName ]
	   [addUnprotectedSetOfConstrained aVarElement ParmName SclAdd FunctionName]
	   [addUnprotectedInteger aVarElement ParmName SclAdd FunctionName]
	   [addUnprotectedUserDefinedConst aVarElement ParmName SclAdd FunctionName]
end function


function addUnprotectedUserDefinedVarOptional aVarElement [struct_element] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] TypeName [id] '(SIZE DEFINED) TA [repeat type_attribute]

    deconstruct * [optional] TA
    	_ [optional]


    construct WriteName [id]
    	_ [+ 'serialize]
	  [+ TypeName ]


    import SerializedFields [repeat id]
    construct NewSerializedFields [repeat id]
        UniqueID SerializedFields
    export SerializedFields
        NewSerializedFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    construct FieldName [id]
    	ShortID [tolower]

    import NullId [id]


    % TODO we need a macro/function to allocate memory
    % and report and error if a problem so we don't
    % have to emit error checking code
    % TODO add free statements
    % use restoreState rule
    construct WriteStmts [repeat declaration_or_statement]
        if (ParmName '-> FieldName != NullId){
            'buff '= WriteName('buff, ParmName '-> FieldName, name, Endian);
	}
    by
	Stmts [. WriteStmts]
end function


%TODO, should verify that the field given by the length constraint occurs earlier than the field
function addUnprotectedOctetStringConstrained aVarElement [struct_element] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] 'OCTET 'STRING '(SIZE CONSTRAINED) TA [repeat type_attribute]

    % constant size octet strings are represented as arrays in the structures.
    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    import SerializedFields [repeat id]
    construct NewSerializedFields [repeat id]
        UniqueID SerializedFields
    export SerializedFields
        NewSerializedFields %[putp "NewFields are %"]

    construct FieldName [id]
    	ShortID[tolower]

    construct FailStmts [repeat declaration_or_statement]
       _ %[addDebugFail FunctionName]
         [addReturnNull]

    import NullId [id]

    construct WriteStmts [repeat declaration_or_statement]
        if (('buff = SerializeBufferAllocate(buff, ParmName' -> FieldName [+ '_length])) == NullId){
	    FailStmts
	}
	writebufferOctetStr('buff, ParmName '-> FieldName, ParmName '-> FieldName [+ '_length], Endian);

    by
	Stmts [. WriteStmts]
end function


function addUnprotectedSetOfConstrained aVarElement [struct_element] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] 'SET 'OF TypeName [id] '(SIZE CONSTRAINED) TA [repeat type_attribute]

    construct FieldName [id]
    	ShortID[tolower]

    construct FailStmts [repeat declaration_or_statement]
       _ %[addDebugFail FunctionName]
         [addReturnNull]

    import SerializedFields [repeat id]
    construct NewSerializedFields [repeat id]
        UniqueID SerializedFields
    export SerializedFields
        NewSerializedFields %[putp "NewFields are %"]

    construct WriteName [id]
    	_ [+ 'serialize]
	  [+ TypeName ]

    import NullId [id]

    construct GetStmts [repeat declaration_or_statement]
        'if ( ParmName -> FieldName != NullId){
	    'for (int i = 0; i < ParmName '-> FieldName [+ 'count]; i++){
	        'buff '= WriteName(buff, &(ParmName '-> FieldName '[ i ']), name, endianness)';
	    }
	}

    by
	Stmts  [. GetStmts]
end function

function addUnprotectedInteger aVarElement [struct_element] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] INTEGER '(SIZE Size [number] BYTES) TA [repeat type_attribute]

    construct Bits [number]
    	Size [* 8]

    construct WriteName [id]
    	_ [+ 'writebufferInt]
	  [+ Bits]

    construct FailStmts [repeat declaration_or_statement]
       _ %[addDebugFail FunctionName]
         [addReturnNull]

    import SerializedFields [repeat id]
    construct NewSerializedFields [repeat id]
        UniqueID SerializedFields
    export SerializedFields
        NewSerializedFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]
 
    import NullId [id]

    construct GetStmts [repeat declaration_or_statement]
        if (('buff = SerializeBufferAllocate(buff, Size)) == NullId ){
	    FailStmts
	}
        WriteName(buff,ParmName '-> ShortID [tolower], Endian);


    by
	Stmts
	    [. GetStmts]
end function

function addUnprotectedUserDefinedConst aVarElement [struct_element] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]

    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] TypeName [id] '(SIZE DEFINED) TA [repeat type_attribute]

    deconstruct not * [optional] TA
    	_ [optional]

    construct WriteName [id]
        _ [+ 'serialize]
          [+ TypeName ]

    import SerializedFields [repeat id]
    construct NewSerializedFields [repeat id]
        UniqueID SerializedFields
    export SerializedFields
        NewSerializedFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]       % default is parameter to parse function
          [replaceBigEndianIfSpecified TA]
          [replaceLittleEndianIfSpecified TA]

    construct FailStmts [repeat declaration_or_statement]
       _ %[addDebugFail FunctionName]
         [addReturnNull]

    import NullId [id]

    construct GetStmt [repeat declaration_or_statement]
        if ((buff= WriteName(buff,&(ParmName '-> ShortID [tolower]), name, Endian))==NullId){
            FailStmts
        }

    construct WrappedGetStmt [repeat declaration_or_statement]
        GetStmt [wrapIfLengthAndSlack ParmName UniqueID SclAdd TA FailStmts]
                [wrapIfLengthAndSlackMod ParmName ShortID SclAdd TA FailStmts]

    by
        Stmts [. WrappedGetStmt]
end function

function wrapIfLengthAndSlack ParmName [id] UniqueID [id] SclAdd [opt scl_additions] TypeAttr [repeat type_attribute] FailStmts [repeat declaration_or_statement]
    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]

    % forwared constraints should be checking that the fields are proper
    deconstruct * [construction_parameter] SclAdd
        LENGTH '( '[ UniqueID '^ ShortID [id] '] ') '== AddExp [additive_expression] _ [opt size_unit]

    deconstruct * [slack] TypeAttr
        SLACK

    construct SlackField [id]
        ShortID [tolower] [+ '_SLACK]
	%[putp '"slack field is %"]

    import NullId [id]

    construct alignFields [repeat declaration_or_statement]
        if ((buff= writeNulls(buff,ParmName '-> SlackField))==NullId){
            FailStmts
        }
    by
	Stmts [. alignFields]
end function


function wrapIfLengthAndSlackMod ParmName [id] ShortID [id] SclAdd [opt scl_additions] TypeAttr [repeat type_attribute] FailStmts [repeat declaration_or_statement]

    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]

    deconstruct * [slack] TypeAttr
        SLACK MOD ModNum [number]

    construct SlackField [id]
        ShortID [tolower] [+ '_SLACKMOD]
	%[putp '"slack field is %"]

    import NullId [id]

    % assumes alignment based on beginning of buffer passed to
    % parser.
    construct alignStmts [repeat declaration_or_statement]
        if ((buff= writeNulls(buff,ParmName '-> SlackField))==NullId){
            FailStmts
        }

    by
        Stmts [. alignStmts]
end function

function removeAfterUnderScore
    replace [id]
	TypeName [id]
    construct index [number]
	_ [index TypeName "_"]	% Find the "_" character location
    where
    	index [> 0]
    construct finalIndex [number]
	index [- 1]	% The location one character before the "_"
    by 
	TypeName [: 1 finalIndex]	% Get the characters before the "_"
end function 

function addReturnNull
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    import NullId [id]
    construct FalseStmt [declaration_or_statement]
    	return NullId;
    by
        Stmts [. FalseStmt]
end function

% need a forward conversion section
rule convertREMAINING
    replace [primary]
    	'PDUREMAINING
    by
    	thePDU -> remaining
end rule


%TODO move to library section
function replaceBigEndianIfSpecified TA [repeat type_attribute]
    deconstruct * [endian] TA
	'BIGENDIAN
    replace [id]
	_ [id]
    by
	'BIGENDIAN
end function

%TODO move to library section
function replaceLittleEndianIfSpecified TA [repeat type_attribute]
    deconstruct * [endian] TA
	'LITTLEENDIAN
    replace [id]
	_ [id]
    by
	'LITTLEENDIAN
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Type Decisions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule generateTypeDecFunctions ModName [id] Ex [opt export_block] TPRules [repeat type_rule_definition] TypeDec [repeat type_decision_definition]
    replace [repeat rule_definition]
	'[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] '::= TD [type_decision] OptScl [opt scl_additions]
	Rest [repeat rule_definition]

    construct Refs [repeat type_reference]
    	_ [^ TD]
	  %[message "hi"]

    construct Parse [repeat rule_definition]
        _ [generateTDWriteFunction UniqueID Ex TPRules TypeDec Refs OptScl]

    by
        Parse
    	 [. Rest]
end rule

function generateTDWriteFunction RuleName [id] Ex [opt export_block] TPRules [repeat type_rule_definition] TypeDec [repeat type_decision_definition] Refs [repeat type_reference] SclAdd [opt scl_additions]

     construct WriteFunctionName [id]
        _ [+ 'serialize]
	  [+ RuleName]

     construct Type [repeat decl_qualifier_or_type_specifier+]
         'SerializeBuffer

     construct UnionName [id]
     	RuleName [tolower]
      
     construct SwitchBody [repeat declaration_or_statement]
        _ [addSwitchCase UnionName each Refs]
          [addSwitchCaseExternal UnionName each Refs]
	  [addDefault UnionName]

    construct  PrePragma1 [preprocessor_line]
        _ [parse '"#pragma GCC diagnostic push"]
    construct  PrePragma2 [preprocessor_line]
        _ [parse '"#pragma GCC diagnostic ignored \"-Wswitch\""]
    construct  PrePragma3 [preprocessor_line]
        _ [parse '"#pragma clang diagnostic push"]
    construct  PrePragma4 [preprocessor_line]
        _ [parse '"#pragma clang diagnostic ignored \"-Wswitch\""]

    construct  PostPragma1 [preprocessor_line]
        _ [parse '"#pragma GCC diagnostic pop"]
    construct  PostPragma2 [preprocessor_line]
        _ [parse '"#pragma clang diagnostic pop"]

     construct WriteFunction [serialize_function]
        Type  [addStaticIfNotExternal RuleName Ex]
	'*WriteFunctionName(SerializeBuffer * buff, RuleName * UnionName, char * name, uint8_t endianness){
	    PrePragma1
	    PrePragma2
	    PrePragma3
	    PrePragma4
	    switch(UnionName '-> 'type) '{
		SwitchBody
	    '}
	    PostPragma1
	    PostPragma2
	    return buff;
	}

     replace [repeat rule_definition]
     	Functions [repeat rule_definition]
     by
        WriteFunction
        Functions [addProtoIfPrivate WriteFunctionName RuleName Ex UnionName]
                  [addProtoIfPublic WriteFunctionName RuleName Ex UnionName]
end function

function addSwitchCase UnionName [id] aRef [type_reference]
     deconstruct aRef
        UniqueTypeName [id] Annot [annotation]

     construct WriteName [id]
         _ [+ 'serialize]
	   [+ UniqueTypeName]

     construct SwitchCase [repeat declaration_or_statement]
        'case UniqueTypeName [+ '_VAL]:
	   'buff = WriteName('buff, (&(UnionName '-> item.UniqueTypeName[tolower])), name,endianness);
	   break;

     replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
     by
     	Cases [. SwitchCase]
end function

function addSwitchCaseExternal UnionName [id] aRef [type_reference]
     deconstruct aRef
        Module [id] '. UniqueTypeName [id] Annot [annotation]

     construct WriteName [id]
         _ [+ 'serialize]
	   [+ UniqueTypeName]

     construct SwitchCase [repeat declaration_or_statement]
        'case UniqueTypeName [+ '_VAL]:
	   'buff = WriteName('buff, (&(UnionName '-> item.UniqueTypeName[tolower])), name,endianness);
	   break;

     replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
     by
     	Cases [. SwitchCase]
end function

function addDefault UnionName [id]
     construct FprintfStr [stringlit]
     	_ [+ '"Uknown type %d for "]
	  [+ UnionName]
	  [+ '"\n"]

     construct DefaultCase [repeat declaration_or_statement]
        default:
	   fprintf(stderr,FprintfStr, UnionName  '-> 'type);

     replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
     by
     	Cases [. DefaultCase]
end function

function addDebugEnter FunctionName [id]
    import debugArg [number]
    	'1
    import traceFileID [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement] 
    construct FuncString [stringlit]
    	_ [+ FunctionName]
    construct DebugStmt [declaration_or_statement]
        if (debugLevel > 0)
        'IN(traceFileID, FuncString) ';
    by
	Stmts [. DebugStmt]
end function

function addDebugSucceed FunctionName [id]
    import debugArg [number]
    	'1
    import traceFileID [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement] 
    construct FuncString [stringlit]
    	_ [+ FunctionName]
    construct DebugStmt [declaration_or_statement]
        if (debugLevel > 0)
        SUCCESS(traceFileID, FuncString) ';
    by
	Stmts [. DebugStmt]
end function

function addDebugFail FunctionName [id]
    import debugArg [number]
    	'1
    import traceFileID [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement] 
    construct FuncString [stringlit]
    	_ [+ FunctionName]
    construct DebugStmt [declaration_or_statement]
        if (debugLevel > 0)
	    FAIL(traceFileID, FuncString) ';
    by
	Stmts [. DebugStmt]
end function

function addDebugLong Size [number] ParmName [id] ShortID [id]
    import debugArg [number]
    	'1
    import traceFileID [id]
    where
    	Size [< '5]
    construct FieldNameID [id]
    	ShortID [tolower]
    construct FieldNameStr [stringlit]
    	_ [+ FieldNameID]
    construct DebugStmt [declaration_or_statement]
        if (debugLevel > 0)
	    READLONG(traceFileID, FieldNameStr, ParmName '-> FieldNameID);
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement] 
    by
	Stmts [. DebugStmt]
end function
   
function addDebugLongLong Size [number] ParmName [id] ShortID [id]
    import debugArg [number]
    	'1
    import traceFileID [id]
    where
    	Size [> '4]
    construct FieldNameID [id]
    	ShortID [tolower]
    construct FieldNameStr [stringlit]
    	_ [+ FieldNameID]
    construct DebugStmt [declaration_or_statement]
        if (debugLevel > 0)
	    READLONGLONG(traceFileID, FieldNameStr, ParmName '-> FieldNameID);
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement] 
    by
	Stmts [. DebugStmt]
end function
