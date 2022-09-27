%+
% 09GenerateSource.txl
%   -complete restructureing from start of the old 09GenerateSource.txl
%    - which was a simple restructure of generateSourceImmediate.txl
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
     [private_parse_prototype]
   | [parse_function]
   | [free_function]
end define

define private_parse_prototype
    [function_definition_or_declaration]
end define

define parse_function
    [function_definition_or_declaration]
end define

define free_function
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

    export NullId [id]
    	_ [unquote '"NULL"]

    construct NewArgs [number]
    	_ [convertFlagsToGlobals]

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
    export CallbackArg [number]
	Zero [checkTXLargs '"-callback"]

    % the flag -nosubmessage suppresses the submessage
    % callback optimization
    export SubMsgArg [number]
	Zero [checkTXLargs '"-submessage"]	

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

   replace * [repeat module_definition]
      Mods [repeat module_definition]
   by
     '#include "globals.h"
     '#include "packet.h"
     '#include "putilities.h"
     IncludeLine
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
   [id] [id] [id] [id] [opt id] [opt callbackInfo]
end define

% @ type of the parent record for the callback call.
define callbackInfo
 '@ [id]
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
	        [generateStructTypeFunctions ModuleName Exports TypeRules TypeDecisions]
	        [generateTypeDecFunctions ModuleName Exports TypeRules TypeDecisions]
		[generateSetOfFunctions]
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

function replaceByC
    replace  [module_definition]
	ModuleName [id] 'DEFINITIONS ::= 'BEGIN
	    Exports [opt export_block]
	    Imports [opt import_block]
	    AllRules [repeat rule_definition]
	'END
    construct FunctionProtos [repeat private_parse_prototype]
    	_ [^ AllRules]
    construct FunctionProtosC [repeat c_translation]
    	_ [reparse FunctionProtos]
    construct ParseFunctions [repeat parse_function]
    	_ [^ AllRules]
    construct ParseFunctionsC [repeat c_translation]
    	_ [reparse ParseFunctions]
    construct FreeFunctions [repeat free_function]
    	_ [^ AllRules]
    construct FreeFunctionsC [repeat c_translation]
    	_ [reparse FreeFunctions]
    by
   	FunctionProtosC
	    [. ParseFunctionsC]
	    [. FreeFunctionsC]
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
        _ [generateStructParseFunction UniqueID Ex TPRules TypeDec Elements OptScl]
	  [createSubmessageVersionOfStructParseFunction OptScl]
	  [createSubmessageVersionOfStructPrototype OptScl]

    construct Free [repeat rule_definition]
       _ [generateStructFree UniqueID Ex TPRules TypeDec Elements OptScl]
         %[addFreeIfCallbackUniqueID Ex]
    by
        Parse
	 [. Free]
    	 [. Rest]
end rule

% TODO needs to create extra for each callback_statement (in case more than one)
function createSubmessageVersionOfStructPrototype OptScl [opt scl_additions]

    replace * [repeat rule_definition]
        PT [private_parse_prototype]
	Rest [repeat rule_definition]

    import SubMsgArg [number]
    	1
    deconstruct * [callback_statement] OptScl
    	'Callback ParentType [id] _ [id]

    deconstruct PT
        Type  [repeat decl_qualifier_or_type_specifier+]
	ParseFunctionName [id] (RuleName[id] * ParmName [id], PDU *thePDU, char * name, uint8_t endianness);

    construct Orig [private_parse_prototype]
	Type ParseFunctionName (RuleName * ParmName, PDU *thePDU, char * name, uint8_t endianness);
    construct Callback [private_parse_prototype]
	Type ParseFunctionName  [+ '_] [+ ParentType][+ '_Callback]

	(RuleName * ParmName, ParentType '* ParentType [tolower], PDU *thePDU, char * name, uint8_t endianness);
    by
    	Orig
	Callback
	Rest
end function

% TODO needs to create extra for each callback_statement (in case more than one)
function createSubmessageVersionOfStructParseFunction OptScl [opt scl_additions]
    replace * [repeat rule_definition]
        PF [parse_function]
	Rest [repeat rule_definition]


    import SubMsgArg [number]
    	1
    deconstruct * [callback_statement] OptScl
    	'Callback ParentType [id] _ [id]

    deconstruct PF
        Type  [repeat decl_qualifier_or_type_specifier+]
	ParseFunctionName [id] (RuleName [id] * UnionName [id], PDU *thePDU, char * name, uint8_t endianness){
	    Body [repeat declaration_or_statement]
	}

    construct Orig [parse_function]
        Type ParseFunctionName (RuleName * UnionName , PDU *thePDU, char * name, uint8_t endianness){
	    Body 
	}

    construct Callback [parse_function]
        Type ParseFunctionName [+ '_] [+ ParentType] [+ '_Callback]
	(RuleName * UnionName , ParentType '* ParentType [tolower], PDU *thePDU, char * name, uint8_t endianness){
	    Body [addSubmessageCallback UnionName ParentType RuleName]
	}

    by
    	Orig
	Callback
	Rest
end function

function addSubmessageCallback UnionName [id] ParentType [id] RuleName [id]
   skipping [declaration_or_statement]
   replace * [repeat declaration_or_statement]
   	return 'true ';
   by
        RuleName [+ '_callback] '( ParentType [tolower], UnionName, 'thePDU  ')';
	return 'true ';
end function

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

% free pair is used for recording fields that have to be freed if the
% parse fails and has to back up. The first component is the type
% of allocation (Opt/Oct/Set/User). The second value is the
% name of the field, and the third is the name of the User Type if given
% (used to call the free function for nested values
define free_pair
   [id] [id] [opt id] [NL]
end define

function generateStructParseFunction RuleName [id] Ex [opt export_block] TPRules [repeat type_rule_definition] TypeDec [repeat type_decision_definition] Elements [list struct_element] SclAdd [opt scl_additions]

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

     % some fields require memory alloctions (i.e. long Octets, Set of, etc.)
     % if the parse fails for some reason, allocated fields have to be deallocated
     % to prevent a memory leak.
     export FreeFieldNames [repeat free_pair]
     	_

     % generic back constraints can either be evaluated at the end or can
     % evaluate when all of the fields that are used in the constraint have been read.
     export ReadFields [repeat id]
     	_

     % the back constraints should only be checked once after the fields
     % in the constraint have been read. We start with all of the constraints
     % for the current structure. As we generate code for each of the reads,
     % we generate the code to check the constraint and remove it from
     % the list
     export BackConstraints [repeat back_block]
     	_ [^ SclAdd]


     % when a field changes the endianness for the rest of a SEUQUENCE, it is given
     % as a forward constraint. It is possible (but unheard of) for more than
     % one such occurrentce. This collects the set of Endianness changes for a given
     % sequence and evaluates them in much the same way as BackConstraints Are handled
     export EndianConstraints [repeat immediate_endian_change]
     	_ [^ SclAdd]
    
     % TODO: also have to filter the back constraints to remove the ones that have already
     % been used in lookahead. - how do we know?

     construct ParseFunctionName [id]
        _ [+ 'parse]
	  [+ RuleName]

     construct Type [repeat decl_qualifier_or_type_specifier+]
         'bool

     construct ParmName [id]
     	RuleName [tolower]

     construct Body [repeat declaration_or_statement]
        _ [addDebugEnter ParseFunctionName]
          [saveState]
	  [addProtectedConstGets ConstElements RuleName ParmName SclAdd ParseFunctionName]
	  [addUnprotectedVarGets VarElements RuleName ParmName SclAdd ParseFunctionName]
	  [addAllBytesUsead RuleName ParmName SclAdd ParseFunctionName]
	  [addDebugSucceed ParseFunctionName]
	  [addCallback RuleName SclAdd] % only for main callback
	  [addReturnTrue]

    % TODO: should confirm all back constraints are used and the list is empty.

     construct ParseFunction [parse_function]
        Type  [addStaticIfNotExternal RuleName Ex]
	ParseFunctionName(RuleName * ParmName, PDU *thePDU, char * name, uint8_t endianness){
	    Body
	}

     replace [repeat rule_definition]
     	Functions [repeat rule_definition]
     by
        ParseFunction
        Functions [addProtoIfPrivate ParseFunctionName RuleName Ex ParmName]
end function

% T.D. the used one...
function saveState
    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
    construct SaveStmts [repeat declaration_or_statement]
        'unsigned 'long saveCurPos = thePDU -> curPos;
	'unsigned 'long saveRemaining  = thePDU -> remaining;
    by
     	Stmts [. SaveStmts]
end function

function addCallback RuleName[id] SclAdd [opt scl_additions]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    import CallbackArg [number]
    	'1
    where
    	SclAdd [hasSimpleCallback]
	       [hasRootOfSubmessageCallback]
    construct Callback [repeat declaration_or_statement]
    	RuleName [+ '_callback]
	%[putp ''***************************** Callback name is %']
	'( RuleName [tolower] , thePDU ') ';
    by
     	Stmts [. Callback]
end function

function hasSimpleCallback
   match * [callback_statement]
   	'Callback
end function

function hasRootOfSubmessageCallback
   match * [callback_statement]
   	'Callback '@ _ [id] _ [id]
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
     construct ParseFunction [private_parse_prototype]
	'static 'bool ParseFunctionName(RuleName * ParmName, PDU *thePDU, char * name, uint8_t endianness);
     replace [repeat rule_definition]
     	Functions [repeat rule_definition]
     by
        ParseFunction
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

function addProtectedConstGets ConstElements [list struct_element] RuleName [id] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
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
       _ %[restoreState]
         [addDebugFail FunctionName]
         [addFalseStmt]

    construct Guard [declaration_or_statement]
        if (!lengthRemaining(thePDU, Pos [+ Size], name)){
	    %return false;
	    FailStmts
	}

    construct EatBytes [repeat declaration_or_statement]
	_ [addEatBytesIfBytesToEat ConstElements]

    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    by
	Stmts
	   [. Guard]
	   [. EatBytes]
	   [addProtectedGet RuleName ParmName SclAdd FunctionName each ConstElements]
end function

function addSizeIfNotUserDefined aConstElement [struct_element]
    deconstruct not * [type] aConstElement
       TypeName [id] '(SIZE DEFINED) TA [repeat type_attribute]
    deconstruct * [const_pos_size_annotation] aConstElement
    	'@ CONST _ [number] Size [number]
    replace [number]
    	N [number]
    by
    	N [+ Size]
end function

function addEatBytesIfBytesToEat ConstElements [list struct_element]
    % get total size of built in types
    construct BytesToEat [number]
    	_ [addSizeIfNotUserDefined each ConstElements]

    where
    	BytesToEat [> 0]
    replace [repeat declaration_or_statement]
       _ [repeat declaration_or_statement]
    by
    	thePDU -> remaining -= BytesToEat;
end function

%========================================
% if the parser reaches the end of the function, a succssful parse has been made.
%========================================
% if the parser reaches the end of the function, a succssful parse has been made.
function addReturnTrue
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    construct ReturnTrue [declaration_or_statement]
        'return 'true;
    by
    	Stmts [. ReturnTrue]
end function

function warnIfVarAnnotation RuleName [id]
   match * [var_pos_size_annotation]
   	_ [var_pos_size_annotation]
   construct Msg [stringlit]
      _ [+ "Internal Error: addProtectedConstGtest: split of fields in struct type "]
        [+ RuleName]
	[+ " failed"]
	[print]
end function

function addProtectedGet RuleName [id] ParmName [id] SclAdd [opt scl_additions] FunctionName [id] aConstElement [struct_element]
    % TODO: warn if the const element is guarded by a forward constraint for some reason
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    by
	Stmts
	    % Todo expand backconstraints for non-integer fields
	    [recordPosition aConstElement ParmName FunctionName]
	    [addEndianCheck ParmName FunctionName SclAdd]
	    [addProtectedInteger aConstElement ParmName FunctionName]
	    [addProtectedOctetStringInt aConstElement ParmName FunctionName]
	    [addProtectedOctetStringChar aConstElement ParmName FunctionName]
	    [addProtectedReal aConstElement ParmName FunctionName]
	    [addProtectedUserDefinedConst aConstElement ParmName FunctionName]
end function

function recordPosition anElement [struct_element] ParmName[id] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct anElement
       %'[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] INTEGER '(SIZE Size [number] BYTES) TA [repeat type_attribute]
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation]  Type [type]
    deconstruct * [repeat type_attribute] Type
       TA [repeat type_attribute]

    where
    	UniqueID
	    [typeAttrHasPos TA]
	    [annotationHasPos Annot]

    construct GetStmt [declaration_or_statement]
        ParmName '-> ShortID [tolower][+ '_POS] = thePDU '-> curPos ';

    by
	Stmts [. GetStmt] 
end function

function typeAttrHasPos TA [repeat type_attribute]
    deconstruct * [save_position] TA
    	_ [save_position]
    match [id]
    	_ [id]
end function

function annotationHasPos Annot [annotation]
    deconstruct * [position_used] Annot
        @ 'POS
    match [id]
    	UniqueID [id]
end function

function addEndianCheck ParmName [id] FunctionName [id] SclAdd [opt scl_additions]

    import EndianConstraints [repeat immediate_endian_change]

    % at least one constraint to evaluate
    deconstruct EndianConstraints
    	_ [immediate_endian_change] Rest [repeat immediate_endian_change]

    export EndianConstraintsToRemove [repeat immediate_endian_change]
    	_

    import ReadFields [repeat id]

    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
    by 
    	Stmts [evaluateEndianConstraintIfRipe ParmName ReadFields FunctionName each EndianConstraints]
	      [removeEvaluatedEndianConstraints] % TODO note only removes one.
end function

function evaluateEndianConstraintIfRipe ParmName [id] ReadFields [repeat id] FunctionName [id] EndianConstraint [immediate_endian_change]
    deconstruct EndianConstraint
        'ENDIANNESS '== RE [relational_expression]

    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    construct ResolvedRE [or_expression]
    	RE [convertSimpleFieldsIfRead ParmName ReadFields]
    deconstruct not * [referenced_element] ResolvedRE
    	'[ _ [referenced_element] '^ _ [referenced_element] ']
    construct CExpr [opt assignment_cexpression]
    	_ [reparse ResolvedRE]
	  %[putp "ENDIAN expr is %"]
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
    construct GetName [id]
    	_ [+ 'get]
	  [+ Bits]
	  [+ '_e]

    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
    	NewReadFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    construct GetStmt [declaration_or_statement]
        ParmName '-> ShortID [tolower] = GetName(thePDU, Endian);

    construct CheckFields [repeat declaration_or_statement]
    	_ [checkBackConstraints ParmName NewReadFields FunctionName]

    by
	Stmts [. GetStmt] 
	[addDebugLong Size ParmName ShortID]
	[addDebugLongLong Size ParmName ShortID]
	[. CheckFields]
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
    construct GetName [id]
    	_ [+ 'get]
	  [+ Bits]
	  [+ '_e]

    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
    	NewReadFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    construct GetStmt [declaration_or_statement]
        ParmName '-> ShortID [tolower] = GetName(thePDU, Endian);

    construct CheckFields [repeat declaration_or_statement]
    	_ [checkBackConstraints ParmName NewReadFields FunctionName]
    by
	Stmts [. GetStmt] [. CheckFields]
end function

function addProtectedOctetStringChar aConstElement [struct_element] ParmName [id] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    deconstruct aConstElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] 'OCTET 'STRING '(SIZE Size [number] BYTES) TA [repeat type_attribute]

    where
    	Size [> 8]

    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
    	NewReadFields %[putp "NewFields are %"]

    % constant size octet strings are represented as arrays in the structures.
    % so nothing to free, as nothing is allocated
    % TODO difficult to change length for fuzzing here, maybe provide altnerate
    % pointer and length field?

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]
    construct GetStmt [declaration_or_statement]
        getConstChar_e(thePDU,ParmName '-> ShortID [tolower], Size,Endian);

    construct CheckFields [repeat declaration_or_statement]
    	_ [checkBackConstraints ParmName NewReadFields FunctionName]
    by
	Stmts [. GetStmt] [. CheckFields]
end function

function addProtectedReal aConstElement [struct_element] ParmName [id] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    deconstruct aConstElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] REAL '(SIZE Size [number] BYTES) TA [repeat type_attribute]

    where
    	Size [= 8] [= 4]

    construct GetName [id]
    	_ [+ 'getReal]
	  [+ Size]
	  [+ '_e]

    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
    	NewReadFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    construct GetStmt [declaration_or_statement]
        ParmName '-> ShortID [tolower] = GetName(thePDU, Endian);

    construct CheckFields [repeat declaration_or_statement]
    	_ [checkBackConstraints ParmName NewReadFields FunctionName]
    by
	Stmts [. GetStmt] [. CheckFields]
end function

function addProtectedUserDefinedConst aConstElement [struct_element] ParmName [id] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct aConstElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] TypeName [id] '(SIZE DEFINED) TA [repeat type_attribute]


    construct ParseName [id]
    	_ [+ 'parse]
	  [+ TypeName ]

    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
    	NewReadFields %[putp "NewFields are %"]

%TODO - add to free fields, and free fields to false
% but if const, nothing to free???

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    % TODO FAIL, have to add free statements here...
    % have to leave a placeholder and then
    % collect the fields that have been allocated previously and free them
    construct GetStmt [declaration_or_statement]
        if (!ParseName(&(ParmName '-> ShortID [tolower]), thePDU, name, Endian)){
	    return false;
	}

    construct CheckFields [repeat declaration_or_statement]
    	_ [checkBackConstraints ParmName NewReadFields FunctionName]

    by
	Stmts [. GetStmt] [. CheckFields]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% this should be similar to ConstGets, split at the point that VAR gos to VAR Number
% so we can use a single lengthRemaining check for contiguous Var Number.
% for now, jsut generate protection for each constant get
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

function addUnprotectedVarGets VarElements [list struct_element] RuleName [id] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
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
	   [recordPosition aVarElement ParmName FunctionName]
	   [addEndianCheck ParmName FunctionName SclAdd]
	   [addUnprotectedUserDefinedVarOptional aVarElement ParmName SclAdd FunctionName]
	   [addUnprotectedOctetStringInt aVarElement ParmName FunctionName ]
	   [addUnprotectedOctetStringChar aVarElement ParmName FunctionName ]
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


    construct ParseName [id]
    	_ [+ 'parse]
	  [+ TypeName ]

    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
    	NewReadFields %[putp "NewFields are %"]


    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    construct FieldName [id]
    	ShortID [tolower]

    % for some reason the C Grammar doesn't like NULL
    % when it is combined with the ASN grammar.
    % So use an ID to work

    import NullId [id]
    	%_ [unquote '"NULL"]

    % TODO - optional has a constraint that must be checked.
    % for now we have EXISTS(x) == PDUREMAINING and
    % EXISTS(x) == boolean expression.
    % Also add check for malloc result == NULL

    deconstruct * [forward_block] SclAdd
       'Forward '{ 'EXISTS( '[ UniqueID '^ _ [id] '] ') '== Exp [relational_expression]'}

    construct ConditionForIf [relational_expression]
        Exp [convertREMAINING]
	    [convertSimpleFields ParmName]

    % TODO we need a macro/function to allocate memory
    % and report and error if a problem so we don't
    % have to emit error checking code
    % TODO add free statements
    % use restoreState rule
    construct GetStmts [repeat declaration_or_statement]
        if (ConditionForIf){
            ParmName -> FieldName = (TypeName *) malloc(sizeof(TypeName));
            if (!ParseName(ParmName '-> FieldName, thePDU, name, Endian)){
	        % if the condition said it was there, but it wasn't,
		% release the memory and return false.
	        free (ParmName -> FieldName);
	        ParmName -> FieldName = NullId ;
		thePDU -> curPos = saveCurPos;
		thePDU -> remaining = saveRemaining;
		return false ;
	    }
	} else {
	    ParmName -> FieldName = NullId ;
	
	}
    construct CheckFields [repeat declaration_or_statement]
    	_ [checkBackConstraints ParmName NewReadFields FunctionName]
    by
	Stmts [. GetStmts] [. CheckFields]
end function

function addUnprotectedOctetStringInt aConstElement [struct_element] ParmName [id] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    deconstruct aConstElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] 'OCTET 'STRING '(SIZE Size [number] BYTES) TA [repeat type_attribute]

    where
    	Size [<= 8]
    construct Bits [number]
    	Size [* 8]
    construct GetName [id]
    	_ [+ 'get]
	  [+ Bits]
	  [+ '_e]

    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
    	NewReadFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    import FreeFieldNames [repeat free_pair]

    construct FailStmts [repeat declaration_or_statement]
       _ [addFreeFieldStmt ParmName each FreeFieldNames]
         [restoreState]
	 [addDebugFail FunctionName]
         [addFalseStmt]

    construct GetStmt [repeat declaration_or_statement]
        if (!lengthRemaining(thePDU, Size , name)){
	    FailStmts
	}
	thePDU '-> remaining -= Size;
        ParmName '-> ShortID [tolower] = GetName(thePDU, Endian);

    construct CheckFields [repeat declaration_or_statement]
    	_ [checkBackConstraints ParmName NewReadFields FunctionName]
    by
	Stmts [. GetStmt] [. CheckFields]
end function

function addUnprotectedOctetStringChar aConstElement [struct_element] ParmName [id] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    deconstruct aConstElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] 'OCTET 'STRING '(SIZE Size [number] BYTES) TA [repeat type_attribute]

    where
    	Size [> 8]

    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
    	NewReadFields %[putp "NewFields are %"]

    % constant size octet strings are represented as arrays in the structures.
    % so nothing to free, as nothing is allocated
    % TODO difficult to change length for fuzzing here, maybe provide altnerate
    % pointer and length field?

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    import FreeFieldNames [repeat free_pair]

    construct FailStmts [repeat declaration_or_statement]
       _ [addFreeFieldStmt ParmName each FreeFieldNames]
         [restoreState]
	 [addDebugFail FunctionName]
         [addFalseStmt]

    construct GetStmt [repeat declaration_or_statement]
        if (!lengthRemaining(thePDU, Size , name)){
	    FailStmts
	}
	thePDU '-> remaining -= Size;
        getConstChar_e(thePDU,ParmName '-> ShortID [tolower], Size,Endian);

    construct CheckFields [repeat declaration_or_statement]
    	_ [checkBackConstraints ParmName NewReadFields FunctionName]
    by
	Stmts [. GetStmt] [. CheckFields]
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

    deconstruct * [forward_block] SclAdd
       'Forward '{ 'LENGTH( '[ UniqueID '^ _ [id] '] ') '== Exp [additive_expression]'}

    % resolve SCL fields and special names in the expression
    % todo - lengh of previous fields, position of previous fields
    construct ResolvedExpr [additive_expression]
        Exp [convertREMAINING]
	    [convertSimpleFields ParmName]
	    [convertPos ParmName]
	    %[putp "Converted addExpr is %"]

    construct CVersionOpt [opt assignment_cexpression]
    	_ [reparse ResolvedExpr]

    deconstruct CVersionOpt
    	CLengthExpr [assignment_cexpression]

    construct FieldName [id]
    	ShortID[tolower]

    import FreeFieldNames [repeat free_pair]

    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
    	NewReadFields %[putp "NewFields are %"]


    construct FailStmts [repeat declaration_or_statement]
       _ [addFreeFieldStmt ParmName each FreeFieldNames]
         [restoreState]
	 [addDebugFail FunctionName]
         [addFalseStmt]

    export FreeFieldNames
        'Octet ShortID 
	FreeFieldNames

    construct GetStmts [repeat declaration_or_statement]
        if (!lengthRemaining(thePDU, CLengthExpr , name)){
	    FailStmts
	}
	thePDU '-> remaining -= CLengthExpr;
	ParmName '-> FieldName [+ '_length] = CLengthExpr;
	ParmName '-> FieldName = malloc(CLengthExpr); % TODO check malloc return?
        getConstChar_e(thePDU,ParmName '-> FieldName, CLengthExpr, Endian);

    construct CheckFields [repeat declaration_or_statement]
    	_ [checkBackConstraints ParmName NewReadFields FunctionName]

    by
	Stmts [. GetStmts] [. CheckFields]
end function

function addAllBytesUsead RuleName [id] ParmName [id] SclAdd [opt scl_additions] ParseFunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct * [all_bytes] SclAdd
    	_ [all_bytes]

    import FreeFieldNames [repeat free_pair]

    construct FailStmts [repeat declaration_or_statement]
       _ [addFreeFieldStmt ParmName each FreeFieldNames]
         [restoreState]
	 [addDebugFail FunctionName]
         [addFalseStmt]

    construct CheckAllUsed [repeat declaration_or_statement]
        if (thePDU '-> remaining != 0){
	    FailStmts
	}

    by
	Stmts [. CheckAllUsed]
end function

function restoreState
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    construct RestoreStmts[repeat declaration_or_statement]
	thePDU -> curPos = saveCurPos;
	thePDU -> remaining = saveRemaining;
    by
    	Stmts [. RestoreStmts]
end function

function addUnprotectedSetOfConstrained aVarElement [struct_element] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] 'SET 'OF TypeName [id] '(SIZE CONSTRAINED) TA [repeat type_attribute]

    construct Msg [id]
    	UniqueID %[putp '"Forwards For Field % are:"]

    construct Fwds [repeat forward_block]
       _ [^ SclAdd]

    construct FilteredForwards [repeat forward_block]
    	_ [addIfLength UniqueID each Fwds]
	  [addIfCardinality UniqueID each Fwds]
	  [addIfTerminate UniqueID each Fwds]
	  [addIfEnd UniqueID each Fwds]
	  [warnIfMoreThanOneFwd UniqueID]
	  %[print]

    construct FieldName [id]
    	ShortID[tolower]

    import FreeFieldNames [repeat free_pair]
    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
    	NewReadFields %[putp "NewFields are %"]

    construct FailStmts [repeat declaration_or_statement]
       _ [addFreeFieldStmt ParmName each FreeFieldNames]
         [restoreState]
	 [addDebugFail FunctionName]
         [addFalseStmt]

    export FreeFieldNames
        'Set FieldName TypeName
	FreeFieldNames

 % length
 % count
 % ptr to field
    construct ErrMsg [stringlit]
        _ [+ "No get statements generated for field "]
	  [+ FieldName]
	  [+ " of struct "]
	  [+ ParmName]

    construct GetStmts [repeat declaration_or_statement]
        _ [buildSetOfCardinalityCall ParmName UniqueID FieldName TypeName FilteredForwards FailStmts]
	  [buildSetOfLengthCall ParmName UniqueID FieldName TypeName FilteredForwards FailStmts]
	  [buildSetOfTerminateCall ParmName UniqueID FieldName TypeName FilteredForwards FailStmts]
	  [buildSetOfEndCall ParmName UniqueID FieldName TypeName FilteredForwards FailStmts SclAdd]
	  [warnIfEmptyStmts ErrMsg]
	  %[putp "getStmts are %"]

    construct CheckFields [repeat declaration_or_statement]
    	_ [checkBackConstraints ParmName NewReadFields FunctionName]
    by
	Stmts  [. GetStmts] [. CheckFields]
end function

function buildSetOfCardinalityCall ParmName [id] UniqueID [id] FieldName [id] TypeName [id] Fwds [repeat forward_block] FailStmts [repeat declaration_or_statement]

    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct Fwds
    	'Forward '{ 'CARDINALITY '( '[  UniqueID '^ _ [id]  '] ') '== AddExp [additive_expression] '}

    construct ResolvedExpr [additive_expression]
        AddExp [convertREMAINING]
	    [convertSimpleFields ParmName]
	    %[putp "Converted ReExpr is %"]

    construct CAssignExprOpt [opt assignment_cexpression]
        _ [reparse ResolvedExpr]

    deconstruct CAssignExprOpt
	CardExpr [assignment_cexpression]

    construct ShortTypeName [id]
    	TypeName [removeAfterUnderScore]

    construct ParseName [id]
    	_ [+ 'parseSETOF_]
	  [+ ShortTypeName]
	  [+ '_Card]
	  
    import NullId [id]
    	%_ [unquote '"NULL"]

    construct CountField [id]
    	FieldName [+ 'count]

    import SetOfFunctions [repeat set_of_function]
    export SetOfFunctions
	SetOfFunctions	[addSetOfFunctionToList 'Card TypeName ParseName ShortTypeName]

    construct GetStmts [repeat declaration_or_statement]
        if ((CardExpr) > 0) '{
	    ParmName '-> CountField  = CardExpr ';
	    ParmName '-> FieldName [+ 'length] = thePDU '-> curPos;
	    ParmName ->FieldName = (TypeName *) malloc(sizeof(TypeName) * ParmName -> CountField);
	    if (!ParseName(ParmName '-> FieldName, thePDU , 0, ParmName '-> CountField, name, endianness')) {
	        free(ParmName -> FieldName);
		ParmName '-> CountField  = 0 ';
		ParmName '-> FieldName [+ 'length]  = 0 ';
		ParmName '-> FieldName = NullId ';
		FailStmts
	        
	    } else {
		ParmName '-> FieldName [+ 'length] = thePDU '-> curPos - ParmName '-> FieldName [+ 'length] ;
	    }
	'} else '{ 
	    ParmName '-> CountField  = 0 ';
	    ParmName '-> FieldName [+ 'length] = 0 ';
	    ParmName ->FieldName = NullId ';
	'}

    by
	Stmts  [. GetStmts] 
end function

function buildSetOfLengthCall ParmName [id] UniqueID [id] FieldName [id] TypeName [id] Fwds [repeat forward_block] FailStmts [repeat declaration_or_statement]

    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct Fwds
    	'Forward '{ 'LENGTH '( '[  UniqueID '^ _ [id]  '] ') '== AddExp [additive_expression] '}

    construct ResolvedExpr [additive_expression]
        AddExp [convertREMAINING]
	    [convertSimpleFields ParmName]
	    %[putp "Converted ReExpr is %"]

    construct CAssignExprOpt [opt assignment_cexpression]
        _ [reparse ResolvedExpr]

    deconstruct CAssignExprOpt
	LengthExpr [assignment_cexpression]

    construct ShortTypeName [id]
    	TypeName [removeAfterUnderScore]

    construct ParseName [id]
    	_ [+ 'parseSETOF_]
	  [+ ShortTypeName]
	  [+ '_Length]
	  
    import NullId [id]
    	%_ [unquote '"NULL"]

    construct CountField [id]
    	FieldName [+ 'count]
    construct LengthField [id]
    	FieldName [+ 'length]

    import SetOfFunctions [repeat set_of_function]
    export SetOfFunctions
	SetOfFunctions	[addSetOfFunctionToList 'Length TypeName ParseName ShortTypeName]

    construct GetStmts [repeat declaration_or_statement]
        if ((LengthExpr) '> 0)'{
	    PDU constrainedPDU;
	    constrainedPDU '. header = thePDU '-> header;
	    constrainedPDU '. data = thePDU '-> data;
	    constrainedPDU '. curPos = thePDU '-> curPos;
	    constrainedPDU '. remaining = LengthExpr;
	    constrainedPDU '. len = thePDU '-> curPos + (LengthExpr );
	    unsigned int count;

	    if ((ParmName -> FieldName '= ParseName(&constrainedPDU , 0, &count, name, endianness')) != NullId) { 
		ParmName '-> LengthField = LengthExpr;
		ParmName '-> CountField = count;
		% have to update the current position
		thePDU '-> curPos = constrainedPDU  '. curPos ';
		% fall through for successful parse.
	    } else {
		ParmName '-> CountField  = 0 ';
		ParmName '-> LengthField  = 0 ';
		FailStmts
	    }
	'} 'else {
	    ParmName -> FieldName '= NullId ;
	    ParmName '-> LengthField = 0 ';
	    ParmName '-> CountField = 0;
	'}

    by
	Stmts  [. GetStmts]
end function

function buildSetOfTerminateCall ParmName [id] UniqueID [id] FieldName [id] TypeName [id] Fwds [repeat forward_block] FailStmts [repeat declaration_or_statement]

    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct Fwds
    	'Forward '{ 'TERMINATE '( '[  UniqueID '^ _ [id]  '] ') '== '[ UniqueTERM [id] '^ _  [id] '] '}

    construct ShortTypeName [id]
    	TypeName [removeAfterUnderScore]

    construct ParseName [id]
    	_ [+ 'parseSETOF_]
	  [+ ShortTypeName]
	  [+ '_Term]
	  
    import NullId [id]
    	%_ [unquote '"NULL"]

    construct CountField [id]
    	FieldName [+ 'count]

    import SetOfFunctions [repeat set_of_function]
    export SetOfFunctions
	SetOfFunctions	[addSetOfFunctionToListTerm 'Term TypeName ParseName ShortTypeName UniqueTERM]

    construct GetStmts [repeat declaration_or_statement]
        '{
	    
	    ParmName '-> FieldName [+ 'length] = thePDU '-> curPos;
	    if ((ParmName '-> FieldName = ParseName(thePDU , 0, &(ParmName '-> CountField), name, endianness')) != NullId) {
		ParmName '-> FieldName [+ 'length] = thePDU '-> curPos - ParmName '-> FieldName [+ 'length] ;
	    } else {
	        free(ParmName -> FieldName);
		ParmName '-> CountField  = 0 ';
		ParmName '-> FieldName [+ 'length]  = 0 ';
		ParmName '-> FieldName = NullId ';
		FailStmts
	    }
	'}

    by
	Stmts  [. GetStmts] 
end function

% ParmName is the name of the current data structure being parsed
% UniqueID is the Unique ID of the fieldname (for lookup in forwards
% FieldName is the converted lowercase name of the field for use in code
% TypeName is the name of the type that is a set of to pars
% FWDs is the list of forwoard constraints
% failestmts are what to issue if the parse fails
function buildSetOfEndCall ParmName [id] UniqueID [id] FieldName [id] TypeName [id] Fwds [repeat forward_block] FailStmts [repeat declaration_or_statement] SclAdd [opt scl_additions]

    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    deconstruct Fwds
    	'Forward '{ 'END '( '[  UniqueID '^ ShortID [id]  '] ') '}

    construct ShortTypeName [id]
    	TypeName [removeAfterUnderScore]

    construct ParseName [id]
    	_ [+ 'parseSETOF_]
	  [+ ShortTypeName]
	  [+ '_End]
	  [addSubCallbackToParseName SclAdd ShortID]
	  % need to add type and callback name here
	  
    import NullId [id]

    construct CountField [id]
    	FieldName [+ 'count]

    import SetOfFunctions [repeat set_of_function]
    export SetOfFunctions
	SetOfFunctions	
	    [addSetOfFunctionToListNoSubCallback 'End TypeName ParseName ShortTypeName SclAdd ShortID]
	    [addSetOfFunctionToListSubCallback 'End TypeName ParseName ShortTypeName SclAdd ShortID]

    construct GetStmts [repeat declaration_or_statement]
        '{
	    
	    ParmName '-> FieldName [+ 'length] = thePDU '-> curPos;
	    % need to conditionally add statement here
	    SubmessageINIT ';
	    if ((ParmName '-> FieldName = ParseName(thePDU , SubmessageParentArg, 0, &(ParmName '-> CountField), name, endianness')) != NullId) {
	        % need to confirm remaining == 0 at this point in time
		ParmName '-> FieldName [+ 'length] = thePDU '-> curPos - ParmName '-> FieldName [+ 'length] ;
	    } else {
	        free(ParmName -> FieldName);
		ParmName '-> CountField  = 0 ';
		ParmName '-> FieldName [+ 'length]  = 0 ';
		ParmName '-> FieldName = NullId ';
		FailStmts
	    }
	'}
 
    construct FixedGetStmts [repeat declaration_or_statement]
    	GetStmts 
	    [fixInitNoSubmessage]
	    [fixInitSubmessage ParmName FieldName]
	    [fixArgsNoSubmessage]
	    [fixArgsSubmessage ParmName]

    by
	Stmts  [. FixedGetStmts] 
end function

function addSubCallbackToParseName SclAdd [opt scl_additions] FieldName [id]
    replace [id]
	SetOfParseName [id]
    import SubMsgArg [number]
    	'1
    deconstruct * [callback_statement] SclAdd
        Callback '@ TypeName [id] FieldName 
    by
    	SetOfParseName [+ '_] [+ TypeName] [+ '_Callback]
end function

function fixInitNoSubmessage
    replace * [repeat declaration_or_statement]
    	SubmessageINIT ';
	Rest [repeat declaration_or_statement]
    import SubMsgArg [number]
    	'0
    by	
    	Rest
end function 

function fixInitSubmessage ParmName [id] FieldName [id]
    replace * [repeat declaration_or_statement]
    	SubmessageINIT ';
	Rest [repeat declaration_or_statement]
    import SubMsgArg [number]
    	'1
    import NullId [id]
    by	
        ParmName '-> FieldName =  NullId ';
    	Rest
end function

rule fixArgsNoSubmessage
    replace * [list argument_cexpression]
    	SubmessageParentArg , Rest [list argument_cexpression]
    import SubMsgArg [number]
    	'0
    by
    	Rest
end rule

rule fixArgsSubmessage ParmName [id]
    replace * [list argument_cexpression]
    	SubmessageParentArg , Rest [list argument_cexpression]
    import SubMsgArg [number]
    	'1
    by
        ParmName, Rest
end rule

function addUnprotectedInteger aVarElement [struct_element] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] INTEGER '(SIZE Size [number] BYTES) TA [repeat type_attribute]

	%uint32_t get32_e(PDU * thePDU, uint8_t endianness) 
    construct Bits [number]
    	Size [* 8]
    construct GetName [id]
    	_ [+ 'get]
	  [+ Bits]
	  [+ '_e]

    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
    	NewReadFields %[putp "NewFields are %"]

    import FreeFieldNames [repeat free_pair]
    construct FailStmts [repeat declaration_or_statement]
       _ [addFreeFieldStmt ParmName each FreeFieldNames]
         [restoreState]
	 [addDebugFail FunctionName]
         [addFalseStmt]

    construct Endian [id]
        _ [+ 'endianness]	% default is parameter to parse function
	  [replaceBigEndianIfSpecified TA]
	  [replaceLittleEndianIfSpecified TA]

    construct GetStmts [repeat declaration_or_statement]
        if (!lengthRemaining(thePDU, Size , name)){
	    FailStmts
	}
        ParmName '-> ShortID [tolower] = GetName(thePDU, Endian);
	thePDU -> remaining -= Size;

    construct CheckFields [repeat declaration_or_statement]
    	_ [checkBackConstraints ParmName NewReadFields FunctionName]

    by
	Stmts
	    [. GetStmts]
	    [addDebugLong Size ParmName ShortID]
	    [addDebugLongLong Size ParmName ShortID]
	    [. CheckFields]
end function

function addUnprotectedUserDefinedConst aVarElement [struct_element] ParmName [id] SclAdd [opt scl_additions] FunctionName [id]
    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]

    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] TypeName [id] '(SIZE DEFINED) TA [repeat type_attribute]

    deconstruct not * [optional] TA
    	_ [optional]


    construct ParseName [id]
        _ [+ 'parse]
          [+ TypeName ]

    import ReadFields [repeat id]
    construct NewReadFields [repeat id]
        UniqueID ReadFields
    export ReadFields
        NewReadFields %[putp "NewFields are %"]

    construct Endian [id]
        _ [+ 'endianness]       % default is parameter to parse function
          [replaceBigEndianIfSpecified TA]
          [replaceLittleEndianIfSpecified TA]

    import FreeFieldNames [repeat free_pair]
    construct FailStmts [repeat declaration_or_statement]
       _ [addFreeFieldStmt ParmName each FreeFieldNames]
         [restoreState]
	 [addDebugFail FunctionName]
         [addFalseStmt]

    export FreeFieldNames
        'User ShortID TypeName
        FreeFieldNames

    construct GetStmt [repeat declaration_or_statement]
        if (!ParseName(&(ParmName '-> ShortID [tolower]), thePDU, name, Endian)){
            FailStmts
        }

    % if the type name is also governed by a length constraint, then
    % we have to manage slack bytes
    construct WrappedGetStmt [repeat declaration_or_statement]
    	GetStmt [wrapIfLengthAndSlack ParmName UniqueID SclAdd TA FailStmts ReadFields]
	        [wrapIfLengthAndSlackMod ParmName ShortID SclAdd TA FailStmts ReadFields]
    	        %[wrapIfLengthAndNoSlack UniqueID SclAdd TA ReadFields]

    construct CheckFields [repeat declaration_or_statement]
        _ [checkBackConstraints ParmName NewReadFields FunctionName]

    by
        Stmts [. WrappedGetStmt] [. CheckFields]
end function

function wrapIfLengthAndSlack ParmName [id] UniqueID [id] SclAdd [opt scl_additions] TypeAttr [repeat type_attribute] FailStmts [repeat declaration_or_statement] ReadFields [repeat id]
    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]

    % forwared constraints should be checking that the fields are proper
    deconstruct * [construction_parameter] SclAdd
        LENGTH '( '[ UniqueID '^ ShortID [id] '] ') '== AddExp [additive_expression] _ [opt size_unit]

    deconstruct * [slack] TypeAttr
        SLACK 

    construct ResolvedExpr [additive_expression]
        AddExp [convertREMAINING]
	    [convertSimpleFields ParmName]
	    %[putp "Converted ReExpr is %"]

    construct CAssignExprOpt [opt assignment_cexpression]
        _ [reparse ResolvedExpr]

    deconstruct CAssignExprOpt
	LengthExpr [assignment_cexpression]

    construct SlackField [id]
    	ShortID [tolower] [+ '_SLACK]

    by
        if ((LengthExpr) '> 0 '&& lengthRemaining(thePDU, (LengthExpr) , '"")){
	    'unsigned 'long start_pos = thePDU '-> curPos ';
	    'unsigned 'long end_pos = thePDU '-> curPos + (LengthExpr) ';
	    '{
		Stmts
	    '}
	    ParmName'-> SlackField '= 0;
	    if (thePDU '-> curPos < end_pos){
	        ParmName '-> SlackField  '= (end_pos - thePDU '-> curPos) ';
	        thePDU '-> remaining -=  ParmName '-> SlackField ';
		thePDU '-> curPos = end_pos ';
	    }
	} else {
	    FailStmts
	}
end function

function wrapIfLengthAndSlackMod ParmName [id] ShortID [id] SclAdd [opt scl_additions] TypeAttr [repeat type_attribute] FailStmts [repeat declaration_or_statement] ReadFields [repeat id]

    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]

    deconstruct * [slack] TypeAttr
        SLACK MOD ModNum [number]

    construct SlackField [id]
    	ShortID [tolower] [+ '_SLACKMOD]

    % assumes alignment based on beginning of buffer passed to
    % parser.
    construct alignStmts [repeat declaration_or_statement]	
	{
        'unsigned 'long oddBytes = (thePDU '-> curPos '% ModNum) ';
	'unsigned 'long bytesToSkip = (oddBytes)? ModNum - oddBytes : 0 ';
	thePDU '-> remaining -=  bytesToSkip ;
	thePDU '-> curPos += bytesToSkip ';
	ParmName '-> SlackField  '= bytesToSkip ';
	}

    by
	Stmts [. alignStmts]
end function

function wrapIfLengthAndNoSlack ParmName [id] UniqueID [id] SclAdd [opt scl_additions] TypeAttr [repeat type_attribute] FailStmts [repeat declaration_or_statement] ReadFields [repeat id]
    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]

    % forwared constraints should be checking that the fields are proper
    deconstruct * [construction_parameter] SclAdd
        LENGTH '( '[ UniqueID '^ _ [id] '] ') '== AddExp [additive_expression] _ [opt size_unit]

    deconstruct not * [slack] TypeAttr
        SLACK _ [opt MODNUM]

    construct ResolvedExpr [additive_expression]
        AddExp [convertREMAINING]
	    [convertSimpleFields ParmName]
	    %[putp "Converted ReExpr is %"]

    construct CAssignExprOpt [opt assignment_cexpression]
        _ [reparse ResolvedExpr]

    deconstruct CAssignExprOpt
	LengthExpr [assignment_cexpression]

    by
        if ((LengthExpr) '> 0 '&& lengthRemaining(thePDU, (LengthExpr) , '"")){
	    'uint32_t * start_pos = thePDU '-> curPos ';
	    'uint32_t * end_pos = thePDU '-> curPos + (LengthExpr) ';
	    '{
		Stmts
	    '}
	    if (thePDU '-> curPos < end_pos){
		FailStmts
	    }
	} else {
	    FailStmts
	}
end function

function warnIfEmptyStmts ErrMsg [stringlit]
    match [repeat declaration_or_statement]
       _ [empty]
    construct Msg [stringlit]
    	ErrMsg [print]
end function

function addSetOfFunctionToList TypeOfFunct[id] TypeName[id] ParseName[id] ShortTypeName[id]
   replace [repeat set_of_function]
   	Functions [repeat set_of_function]
   deconstruct not * [set_of_function]  Functions
   	_ [id] _ [id] ParseName _ [id]
    by
      TypeOfFunct TypeName ParseName ShortTypeName
      Functions
end function

function addSetOfFunctionToListNoSubCallback TypeOfFunct[id] TypeName[id] ParseName[id] ShortTypeName[id] SclAdd [opt scl_additions] FieldName [id]
   replace [repeat set_of_function]
   	Functions [repeat set_of_function]
   deconstruct not * [callback_statement] SclAdd
   	'Callback '@ _ [id] FieldName
   deconstruct not * [set_of_function]  Functions
   	_ [id] _ [id] ParseName _ [id]
    by
      TypeOfFunct TypeName ParseName ShortTypeName
      Functions
end function

function addSetOfFunctionToListSubCallback TypeOfFunct[id] TypeName[id] ParseName[id] ShortTypeName[id] SclAdd [opt scl_additions] FieldName [id]
   replace [repeat set_of_function]
   	Functions [repeat set_of_function]
   deconstruct * [callback_statement] SclAdd
   	'Callback '@ ParentTypeName [id] FieldName
   deconstruct not * [set_of_function]  Functions
   	_ [id] _ [id] ParseName _ [id] '@ ParentTypeName
    by
      TypeOfFunct TypeName ParseName ShortTypeName '@ ParentTypeName
      Functions
end function

function addSetOfFunctionToListTerm TypeOfFunct[id] TypeName[id] ParseName[id] ShortTypeName[id] TermId [id]
   replace [repeat set_of_function]
   	Functions [repeat set_of_function]
   deconstruct not * [set_of_function]  Functions
   	_ [id] _ [id] ParseName _ [id] _ [opt id]
    by
      TypeOfFunct TypeName ParseName ShortTypeName TermId
      Functions
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

function addIfLength UniqueID [id] aFwd [forward_block]
   deconstruct * [construction_parameter] aFwd
   	'LENGTH ( '[ UniqueID '^ _ [id] '] ') '== _ [additive_expression] _ [opt size_unit]
   replace [repeat forward_block]
   	Fwds [repeat forward_block]
   by
        aFwd
        Fwds
end function

function addIfCardinality UniqueID [id] aFwd [forward_block]
   deconstruct * [construction_parameter] aFwd
   	'CARDINALITY( '[ UniqueID '^ _ [id] '] ') '== _ [additive_expression]
   replace [repeat forward_block]
   	Fwds [repeat forward_block]
   by
        aFwd
        Fwds
end function

function addIfTerminate UniqueID [id] aFwd [forward_block]
   deconstruct * [construction_parameter] aFwd
   	'TERMINATE( '[ UniqueID '^ _ [id] '] ') '== _ [referenced_element]
   replace [repeat forward_block]
   	Fwds [repeat forward_block]
   by
        aFwd
        Fwds
end function

function addIfEnd UniqueID [id] aFwd [forward_block]
   deconstruct * [construction_parameter] aFwd
   	'END( '[ UniqueID '^ _ [id] '] ')
   replace [repeat forward_block]
   	Fwds [repeat forward_block]
   by
        aFwd
        Fwds
end function

function warnIfMoreThanOneFwd UniqueID [id]
   match [repeat forward_block]
   	Fwds [repeat forward_block]
   construct Len [number]
       _ [length Fwds]
   where
   	Len [ > 1]
   construct Msg [id]
      UniqueID [putp '"********More than one forward constraint for %"]
end function

function addFreeFieldStmt ParmName [id] aFreeFieldName [free_pair]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    construct FreeFieldStmt [repeat declaration_or_statement]
        _ [addFreeFieldStmtOctet ParmName aFreeFieldName]
          [addFreeFieldStmtSet ParmName aFreeFieldName]
          [addFreeFieldStmtUser ParmName aFreeFieldName]
	  % need optional user defined
	  % TODO - check that a statement was generated
    by
        Stmts [. FreeFieldStmt]
end function

% a field of type octet string that was longer than 8, or variable length
% so has a length field, but no user defined name

function addFreeFieldStmtOctet ParmName [id] aFreeFieldName [free_pair]
    deconstruct aFreeFieldName
       'Octet  fieldName [id]

    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    import NullId [id]
    	%_ [unquote '"NULL"]

    construct FreeStmt [repeat declaration_or_statement]
    	if (ParmName '-> fieldName != NullId)
		free (ParmName -> fieldName);
	ParmName '-> fieldName = NullId;
	ParmName '-> fieldName [+ '"_length"] = 0;
    by
        Stmts [. FreeStmt]
end function

% a set of user type
function addFreeFieldStmtSet ParmName [id] aFreeFieldName [free_pair]
    deconstruct aFreeFieldName
       'Set  fieldName [id] TypeName [id]

    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    import NullId [id]
    	%_ [unquote '"NULL"]

    construct freeFuncName [id]
    	_ [+ 'free]
	  [+ TypeName]

    construct FreeStmt [repeat declaration_or_statement]
        for (int i = 0; i < ParmName '-> fieldName [+ '"count"]; i++){
	    freeFuncName(&(ParmName '-> fieldName '[ i ']));
	}
    	if (ParmName -> fieldName != NullId)
		free (ParmName -> fieldName);
	ParmName '-> fieldName = NullId;
	ParmName '-> fieldName [+ '"length"] = 0;
    by
        Stmts [. FreeStmt]
end function

function addFreeFieldStmtUser ParmName [id] aFreeFieldName [free_pair]
    deconstruct aFreeFieldName
       'User  fieldName [id] TypeName [id]

    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]

    construct freeFuncName [id]
    	_ [+ 'free]
	  [+ TypeName]

    construct FreeStmt [repeat declaration_or_statement]
	freeFuncName(&(ParmName '-> fieldName[tolower]));
    by
        Stmts [. FreeStmt]
end function

function addFalseStmt
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    construct FalseStmt [declaration_or_statement]
    	return false;
    by
        Stmts [. FalseStmt]
end function


function addTrueStmt
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    construct FalseStmt [declaration_or_statement]
    	return true;
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

rule convertSimpleFields ParmName [id]
    replace [primary]
    	'[ UniqueID [id] '^ ShortId[id] ']
    by
    	(ParmName -> ShortId [tolower])
end rule

rule convertPos ParmName [id]
    replace [primary]
    	'POS '( '[ UniqueID [id] '^ ShortId[id] ']')
    by
    	(ParmName -> ShortId [tolower][+ '_POS])
end rule

rule convertSRCPORT
    replace [primary]
        'SRCPORT
    by
    	'( thePDU '-> header '-> srcPort ')
end rule

rule convertDSTPORT
    replace [primary]
        'DSTPORT
    by
    	'( thePDU '-> header '-> dstPort ')
end rule

function ConvertExistsExpression SclAdd [opt scl_additions] UniqueID[id]
   % the RHS is a boolean expression
   % TODO - we should check that it is actually a boolean expression somewhere.
   deconstruct * [forward_block] SclAdd
       'Forward '{ 'EXISTS( '[ UniqueID '^ _ [id] '] ') '== Exp [relational_expression]'}
   replace [repeat cexpression]
    _ [repeat cexpression]
   by
       thePDU -> remaining
end function

function checkBackConstraints ParmName [id] NewReadFields [repeat id] FunctionName [id]
    import BackConstraints [repeat back_block]
    export BackConstraintsToRemove [repeat back_block]
    	_
    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
    by 
    	Stmts [evaluateBackConstraintIfRipe ParmName NewReadFields FunctionName each BackConstraints]
	      [removeEvaluatedBackConstraints] % TODO note only removes one.
end function

function evaluateBackConstraintIfRipe ParmName [id] NewReadFields [repeat id] FunctionName [id] aBackConstraint [back_block]
    deconstruct aBackConstraint
    	Back '{ OrExpr [or_expression] '}

    construct ResolvedOrExpr [or_expression]
    	OrExpr [convertSimpleFieldsIfRead ParmName NewReadFields]
		% fix other elements
		[convertREMAINING]
		[convertSRCPORT]
		[convertDSTPORT]
	   %[putp "Resolved Expr: %"]
 
    % confirm that All are replaced
    deconstruct not * [referenced_element] ResolvedOrExpr
    	'[ _ [referenced_element] '^ _ [referenced_element] ']

    construct CExpr [opt assignment_cexpression]
    	_ [reparse ResolvedOrExpr]

    deconstruct CExpr
    	CBackConstraint [assignment_cexpression]

    import BackConstraintsToRemove [repeat back_block]
    export BackConstraintsToRemove
    	aBackConstraint
	BackConstraintsToRemove

    import FreeFieldNames [repeat free_pair]
    construct FailStmts [repeat declaration_or_statement]
       _ [addFreeFieldStmt ParmName each FreeFieldNames]
         [restoreState]
	 [addDebugFail FunctionName]
         [addFalseStmt]
    	
    construct CheckStmt [declaration_or_statement]
        if (!(CBackConstraint)){
	   FailStmts
	}

    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
    by 
    	Stmts [. CheckStmt]
end function

function removeEvaluatedBackConstraints
    import BackConstraintsToRemove [repeat back_block]
    import BackConstraints [repeat back_block]
    export BackConstraints
    	BackConstraints [removeBackConstraint each BackConstraintsToRemove]
    match [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
end function

function removeBackConstraint aBackConstraint [back_block]
     replace * [repeat back_block]
     	aBackConstraint Rest [repeat back_block]
     by
    	Rest
end function

rule convertSimpleFieldsIfRead ParmName [id] ReadFields [repeat id]
    replace [primary]
    	'[ UniqueID [id] '^ ShortId[id] ']
    deconstruct * [id] ReadFields
    	UniqueID
    by
    	(ParmName -> ShortId [tolower])
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Free funtion for struct types
%
% free functions are only geneerated for exported
% types and types used in callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% free function for a exported type
function generateStructFree RuleName [id] Ex [opt export_block] TPRules [repeat type_rule_definition] TypeDec [repeat type_decision_definition] Elements [list struct_element] SclAdd [opt scl_additions]

     construct FreeFunctionName [id]
        _ [+ 'free]
	  [+ RuleName]

     construct ParmName [id]
     	RuleName [tolower]

     construct Type [repeat decl_qualifier_or_type_specifier+]
         'void
      
     construct Body [repeat declaration_or_statement]
        _ [addFreeElement RuleName ParmName SclAdd each Elements]

     construct FreeFunction [free_function]
        Type [addStaticIfNotExternal RuleName Ex]
	FreeFunctionName(RuleName * ParmName){
	    Body
	}

     construct FreePrototype [private_parse_prototype]
        Type [addStaticIfNotExternal RuleName Ex]
	FreeFunctionName(RuleName * ParmName);

     replace [repeat rule_definition]
     	Functions [repeat rule_definition]
     by
        FreePrototype
        FreeFunction
        Functions
end function

function addFreeElement RuleName [id] ParmName [id] SclAdd [opt scl_additions] aVarElement [struct_element]
    replace [repeat declaration_or_statement]
	Stmts [repeat declaration_or_statement]
    by
	Stmts
	   [addFreeUserDefinedNonOpt aVarElement ParmName]
	   [addFreeElementOptional aVarElement ParmName SclAdd]
	   [addFreeOctetStringConstrained aVarElement ParmName SclAdd]
	   [addFreeSetOfConstrained aVarElement ParmName SclAdd]
end function

function addFreeUserDefinedNonOpt aVarElement [struct_element] ParmName[id]
    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]

    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] TypeName [id] '(SIZE DEFINED) TA [repeat type_attribute]

    deconstruct not * [optional] TA
        _ [optional]

  construct FreeName [id]
        _ [+ 'free]
          [+ TypeName ]

   construct FieldName [id]
        ShortID [tolower]

    by
	FreeName(&(ParmName '-> FieldName));
	Stmts
end function

function addFreeElementOptional aVarElement [struct_element] ParmName[id] SclAdd [opt scl_additions]
    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]

    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] TypeName [id] '(SIZE DEFINED) TA [repeat type_attribute]

    deconstruct * [optional] TA
        _ [optional]

  construct FreeName [id]
        _ [+ 'free]
          [+ TypeName ]

   construct FieldName [id]
        ShortID [tolower]

   deconstruct * [forward_block] SclAdd
       'Forward '{ 'EXISTS( '[ UniqueID '^ _ [id] '] ') '== Exp [relational_expression]'}

    import NullId [id]
       %_ [unquote '"NULL"]

    % T.D. only need to call free function if something inside has to be freed
    by
	if (ParmName '-> FieldName){
	    FreeName(ParmName '-> FieldName);
	    free(ParmName '-> FieldName);
	    ParmName '-> FieldName = NullId;
	}
	Stmts
end function

% TODO
function addFreeOctetStringConstrained aVarElement [struct_element] ParmName [id] SclAdd [opt scl_additions]
    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
    	
    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] OCTET STRING '(SIZE CONSTRAINED) TA [repeat type_attribute]

    construct xx [id]
        ShortID %[putp ''The octet field to free is %']

    deconstruct * [forward_block] SclAdd
    	'Forward '{ 'LENGTH '( '[ UniqueID '^ _ [id] '] ') '== _ [additive_expression] '}

    import NullId [id]
       %_ [unquote '"NULL"]
         %[message "matched"]

    construct FieldName [id]
    	ShortID [tolower]
         %[message "matched"]

    % T.D. only need to call free function if something inside has to be freed
    by
        if (ParmName '-> FieldName != NullId){
	    free(ParmName '-> FieldName);
	    ParmName '-> FieldName = NullId;
	}
	Stmts
end function

function addFreeSetOfConstrained aVarElement [struct_element] ParmName[id] SclAdd [opt scl_additions]
    replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
    	
    deconstruct aVarElement
       '[ UniqueID [id] '^ ShortID [id] '] Annot [annotation] SET OF TypeName [id] '(SIZE CONSTRAINED) TA [repeat type_attribute]

    construct xx [id]
        ShortID %[putp ''The field is %']

    % T.D. change to where with deconstruct rules
    %deconstruct * [forward_block] SclAdd
    	%'Forward '{ 'CARDINALITY '( '[ UniqueID '^ _ [id] '] ') '== _ [additive_expression] '}

    where
    	SclAdd [hasCardinality UniqueID]
	       [hasLength UniqueID]
	       [hasTerminate UniqueID]

    construct FreeName [id]
        _ [+ 'free]
          [+ TypeName ]

    import NullId [id]
       %_ [unquote '"NULL"]

    construct FieldName [id]
    	ShortID [tolower]

    % T.D. only need to call free function if something inside has to be freed
    by
        if (ParmName '-> FieldName != NullId){
	    for ( int i = 0; i < ParmName '-> FieldName [+ 'count]; i++){
		    FreeName(&(ParmName '-> FieldName '[ i '] ') ');
	    }
	    free(ParmName '-> FieldName);
	    ParmName '-> FieldName = NullId;
	}
    	Stmts
end function

function hasCardinality UniqueID [id]
    match * [forward_block]
    	'Forward '{ 'CARDINALITY '( '[ UniqueID '^ _ [id] '] ') '== _ [additive_expression] '}
end function

function hasLength UniqueID [id]
    match * [forward_block]
    	'Forward '{ 'LENGTH '( '[ UniqueID '^ _ [id] '] ') '== _ [additive_expression] '}
end function

function hasTerminate UniqueID [id]
    match * [forward_block]
    	'Forward '{ 'TERMINATE '( '[ UniqueID '^ _ [id] '] ') '== _ [referenced_element] '}
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
        _ [generateTDParseFunction UniqueID Ex TPRules TypeDec Refs OptScl]
	  [createSubmessageVersionOfTDParseFunction OptScl]
	  [createSubmessageVersionOfTDPrototype OptScl]

    construct Free [repeat rule_definition]
       _ [generateTDFree UniqueID Ex TPRules TypeDec Refs]
         %[addFreeIfCallbackUniqueID Ex]
    by
        Parse
	 [. Free]
    	 [. Rest]
end rule

% TODO needs to create extra for each callback_statement (in case more than one)
function createSubmessageVersionOfTDPrototype OptScl [opt scl_additions]

    replace * [repeat rule_definition]
        PT [private_parse_prototype]
	Rest [repeat rule_definition]

    import SubMsgArg [number]
    	1
    deconstruct * [callback_statement] OptScl
    	'Callback '^ ParentType [id] _ [id]

    deconstruct PT
        Type  [repeat decl_qualifier_or_type_specifier+]
	ParseFunctionName [id] (RuleName[id] * ParmName [id], PDU *thePDU, char * name, uint8_t endianness);

    construct Orig [private_parse_prototype]
	Type ParseFunctionName (RuleName * ParmName, PDU *thePDU, char * name, uint8_t endianness);
    construct Callback [private_parse_prototype]
	Type ParseFunctionName  [+ '_] [+ ParentType][+ '_Callback]

	(RuleName * ParmName, ParentType '* ParentType [tolower], PDU *thePDU, char * name, uint8_t endianness);
    by
    	Orig
	Callback
	Rest
end function

% TODO needs to create extra for each callback_statement (in case more than one)
function createSubmessageVersionOfTDParseFunction OptScl [opt scl_additions]
    replace * [repeat rule_definition]
        PF [parse_function]
	Rest [repeat rule_definition]


    import SubMsgArg [number]
    	1
    deconstruct * [callback_statement] OptScl
    	'Callback '^ ParentType [id] _ [id]

    deconstruct PF
        Type  [repeat decl_qualifier_or_type_specifier+]
	ParseFunctionName [id] (RuleName [id] * UnionName [id], PDU *thePDU, char * name, uint8_t endianness){
	    Body [repeat declaration_or_statement]
	}

    construct Orig [parse_function]
        Type ParseFunctionName (RuleName * UnionName , PDU *thePDU, char * name, uint8_t endianness){
	    Body 
	}

    construct Callback [parse_function]
        Type ParseFunctionName [+ '_] [+ ParentType] [+ '_Callback]
	(RuleName * UnionName , ParentType '* ParentType [tolower], PDU *thePDU, char * name, uint8_t endianness){
	    Body [fixEachParseCall ParentType]
	}

    by
    	Orig
	Callback
	Rest
end function

rule fixEachParseCall ParentType [id]
    replace [cexpression_list]
	ParseName [id] ( ParsePtr [argument_cexpression], thePDU, name, endianness)
    by
	ParseName [+ '_] [+ ParentType] [+ '_Callback]
	( ParsePtr, ParentType [tolower], thePDU, name, endianness)
end rule

function generateTDParseFunction RuleName [id] Ex [opt export_block] TPRules [repeat type_rule_definition] TypeDec [repeat type_decision_definition] Refs [repeat type_reference] SclAdd [opt scl_additions]

     construct ParseFunctionName [id]
        _ [+ 'parse]
	  [+ RuleName]

     construct Type [repeat decl_qualifier_or_type_specifier+]
         'bool

     construct UnionName [id]
     	RuleName [tolower]
      
     construct Body [repeat declaration_or_statement]
        _ [generateLLKOptimizedBody UnionName SclAdd]
	  [generateUnoptimizedBody UnionName SclAdd Refs]

     construct ParseFunction [parse_function]
        Type  [addStaticIfNotExternal RuleName Ex]
	ParseFunctionName(RuleName * UnionName, PDU *thePDU, char * name, uint8_t endianness){
	    Body
	}

     replace [repeat rule_definition]
     	Functions [repeat rule_definition]
     by
        ParseFunction
        Functions [addProtoIfPrivate ParseFunctionName RuleName Ex UnionName]
end function

function generateUnoptimizedBody UnionName [id] SclAdd [opt scl_additions] Refs [repeat type_reference]
     deconstruct not * [optimizable_block] SclAdd
     	'< lookahead '>
           _ [lookahead_block]
        '</ lookahead '>

     replace [repeat declaration_or_statement]
        Empty [repeat declaration_or_statement]
     by
	Empty
	 [addCallToRef UnionName each Refs]
         [addFalseStmt]
end function

function addCallToRef UnionName [id] aRef [type_reference]
     replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
     by
     	Stmts [addCallToInternal UnionName aRef]
	      [addCallToExternal UnionName aRef]
end function

function addCallToInternal UnionName [id] aRef [type_reference]
     deconstruct aRef % internal is no dot id
	UniqueID [id] _ [annotation]
     construct ParseName [id]
     	_ [+ 'parse]
	  [+ UniqueID]
     construct ParseCall [declaration_or_statement]
     	if(ParseName(&(UnionName -> item.UniqueID [tolower]), thePDU, name, endianness)){
	   UnionName -> 'type = UniqueID [+ '_VAL];
	   return true;
	}
     replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
     by
     	Stmts [. ParseCall]
end function

function addCallToExternal UnionName [id] aRef [type_reference]
     deconstruct aRef % external has dot id
	Module [id] '. UniqueID [id] _ [annotation]
     construct ParseName [id]
     	_ [+ 'parse]
	  [+ UniqueID]
     construct ParseCall [declaration_or_statement]
     	if(ParseName(&(UnionName -> item.UniqueID [tolower]), thePDU, name, endianness)){
	   UnionName -> 'type = UniqueID [+ '_VAL];
	   return true;
	}
     replace [repeat declaration_or_statement]
        Stmts [repeat declaration_or_statement]
     by
     	Stmts [. ParseCall]
end function

function generateLLKOptimizedBody UnionName [id] SclAdd [opt scl_additions]
     deconstruct * [optimizable_block] SclAdd
        '< lookahead '>
	   LB [lookahead_block]
        '</ lookahead '>
     replace [repeat declaration_or_statement]
        Empty [empty]
     by
	_ [buildRecursiveSwitch UnionName LB]
end function

% lookahead should include a type, right now assumes integer

define size_pair
  % byte size 	var size
  [number] [number]
end define

function buildRecursiveSwitch UnionName [id] LB [lookahead_block]
     deconstruct LB
	 '{
	     Offset [number] Size [number]
	     Cases [repeat switch_case]
	 '}

    construct BytesNeeded [number]
    	Offset [+ Size]

    construct Bits [number]
    	Size [* 8]

    construct GetName [id]
    	_ [+ 'la]
	  [+ Bits]
	  [+ '_e]

    construct Sizes [repeat size_pair]
    	1 32 2 32 3 32 4 32 5 64 5 64 7 64 8 64

    deconstruct * [size_pair] Sizes
	Size BitsT [number]

    construct LocalVarType [id]
    	_ [+ 'uint]
	  [+ BitsT]
	  [+ '_t]

    construct LocalVarName [id]
    	_ [+ 'LookaheadVal_]
	  [+ Offset]
	  [+ '_]
	  [+ Size]
 
     construct SwitchBody [repeat declaration_or_statement]
     	_ [addSwitchCase UnionName each Cases]

    construct FailStmts [repeat declaration_or_statement]
       _ %[restoreState]
         %[addDebugFail FunctionName]
         [addFalseStmt]

     replace [repeat declaration_or_statement]
        Empty [empty]
     by
        
	if(!lengthRemaining(thePDU, BytesNeeded , name)) {
	    % If we reach this point then we have an incorrect PDU length or type
	    %return false;
	    FailStmts
	}
        LocalVarType LocalVarName = GetName(thePDU,Offset,endianness);
	switch(LocalVarName) '{
	    SwitchBody
	'}
	%return false;
	FailStmts
end function

function addSwitchCase UnionName [id] aLookaheadCase[switch_case]
     replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
     by
     	Cases [addSimpleCase UnionName  aLookaheadCase]
     	      %[addSimpleMultiCase aLookaheadCase]
	      [addRecursiveCase UnionName aLookaheadCase]
	      %[addDefaultSimpleCase UnionName aLookaheadCase]
	      %[addDefaultSimpleMultiCase aLookaheadCase]
	      [addDefaultRecursiveCase aLookaheadCase]
end function

% if it is in the lookahead, it is not a .id which
% is used for reference to external modules, and does
% not do LLK lookahead.
function addSimpleCase UnionName [id] aLookaheadCase[switch_case]

     deconstruct aLookaheadCase
         Value [number] '@ Refs [repeat type_reference]

     construct IfStmts [repeat declaration_or_statement]
     	_ [buildIfForCase UnionName each Refs]
	  [addBreak]
     construct SwitchCase [repeat declaration_or_statement]
        'case Value:
	   IfStmts

     replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
     by
     	Cases [. SwitchCase]
end function

function addBreak
     construct BreakStmt [repeat declaration_or_statement]
        'break ;

     replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
     by
     	Cases [. BreakStmt]
end function

function buildIfForCase UnionName [id] aRef[type_reference]
     deconstruct aRef
        UniqueTypeName [id] Annot [annotation]
     construct UnionFieldName [id]
     	UniqueTypeName [tolower]
     construct ParseName [id]
         _ [+ 'parse]
	   [+ UniqueTypeName]

     construct SwitchCase [repeat declaration_or_statement]
	      if(ParseName(&(UnionName -> item.UnionFieldName), thePDU,name,endianness)){
	          UnionName -> 'type = UniqueTypeName [+ '_VAL] ;
		  return true;
	      }
     replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
     by
     	Cases [. SwitchCase]
end function

function addRecursiveCase UnionName [id] aLookaheadCase[switch_case]
     deconstruct aLookaheadCase
         Value [number] '@ LB [lookahead_block]

     construct NestedSwitch [repeat declaration_or_statement]
	_ [buildRecursiveSwitch UnionName LB]

     construct SwitchCase [repeat declaration_or_statement]
         'case Value:
	     NestedSwitch [addBreak]

     replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
     by
     	Cases [. SwitchCase]
end function

function addDefaultRecursiveCase aLookaheadCase[switch_case]
     deconstruct aLookaheadCase
         Value [number] '@ LB [lookahead_block]
     replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
     by
     	Cases
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Free funtion for type decisions
% nont static free functions are only geneerated for exported
% types and types used in callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% free function for a exported type
function generateTDFree RuleName [id] Ex [opt export_block] TPRules [repeat type_rule_definition] TypeDec [repeat type_decision_definition] Refs [repeat type_reference]

     construct FreeFunctionName [id]
        _ [+ 'free]
	  [+ RuleName]

     construct ParmName [id]
     	RuleName [tolower]

     construct Type [repeat decl_qualifier_or_type_specifier+]
         'void

     construct SwitchBody [repeat declaration_or_statement]
     	_ [addSwitchCaseFree ParmName each Refs]
	  % [add a default for error that should never happen?]

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

     construct Body [repeat declaration_or_statement]
        PrePragma1
        PrePragma2
        PrePragma3
        PrePragma4
        'switch (ParmName -> 'type){
	     SwitchBody
	}
        PostPragma1
        PostPragma2

     %construct SwitchCase [repeat declaration_or_statement]
        %'case Value:
	   %IfStmts

     construct FreeFunction [free_function]
        Type [addStaticIfNotExternal RuleName Ex]
        FreeFunctionName(RuleName * ParmName){
	    Body
	}

     construct FreePrototype [private_parse_prototype]
        Type [addStaticIfNotExternal RuleName Ex]
        FreeFunctionName(RuleName * ParmName);


     replace [repeat rule_definition]
     	Functions [repeat rule_definition]
     by
        FreePrototype
        FreeFunction
        Functions
end function

function addSwitchCaseFree ParmName [id] aRef [type_reference]
    replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
    by
        Cases
	  [addFreeToInternal ParmName aRef]
	  [addFreeToExternal ParmName aRef]
end function

function addFreeToInternal UnionName [id] aRef [type_reference]
    deconstruct aRef % internal is no dot id
        UniqueID [id] _ [annotation] _ [opt unused_annotation]

    construct FreeName [id]
    	_ [+ 'free]
	  [+ UniqueID]

    replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
    by
        'case UniqueID [+ '_VAL]:
	   FreeName(&(UnionName '-> item. UniqueID [tolower]));
	   'break;
	Cases
end function

function addFreeToExternal UnionName [id] aRef [type_reference]
    deconstruct aRef % external has dot id
        Module [id] '. UniqueID [id] _ [annotation] _ [opt unused_annotation]

    construct FreeName [id]
    	_ [+ 'free]
	  [+ UniqueID]

    replace [repeat declaration_or_statement]
        Cases [repeat declaration_or_statement]
    by
        'case UniqueID [+ '_VAL]:
	   FreeName(&(UnionName '-> item. UniqueID [tolower]));
	   'break;
end function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% to prevent redefinition of functions, if more than
% one field has a SET OF Type with the same general
% constraint, then only one parse function should be generated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function generateSetOfFunctions
    import SetOfFunctions [repeat set_of_function]
    replace [repeat rule_definition]
	Rules [repeat rule_definition]
    by
	Rules [addSetOfFunction each SetOfFunctions]
end function

function addSetOfFunction aSetOfFunction [set_of_function]
    replace [repeat rule_definition]
	Rules [repeat rule_definition]
    by
	Rules  [addCardSetOfFunction aSetOfFunction]
	       [addLengthSetOfFunction aSetOfFunction]
	       [addTermSetOfFunction aSetOfFunction]
	       [addEndSetOfFunction aSetOfFunction]
end function

function addCardSetOfFunction aSetOfFunction [set_of_function]
    deconstruct aSetOfFunction
       'Card TypeName [id] SetParseFunctionName [id] ShortTypeName [id]
    replace [repeat rule_definition]
	Rules [repeat rule_definition]

    construct ParseFunctionProto [private_parse_prototype]
	'static 'bool SetParseFunctionName(TypeName * buffer, PDU *thePDU, unsigned int index, unsigned int count, char * name, uint8_t endianness);

    construct ParseProtoRule [rule_definition]
    	ParseFunctionProto

    construct ParseFunctionName [id]
       _ [+ 'parse]
         [+ TypeName]

    construct FreeFunctionName [id]
       _ [+ 'free]
         [+ TypeName]

    construct FailStmts [repeat declaration_or_statement]
       _ [addDebugFail ParseFunctionName]
         [addFalseStmt]

    construct SucceedStmts [repeat declaration_or_statement]
       _ [addDebugSucceed ParseFunctionName]
         [addTrueStmt]

   % addDebugEnter needs a scope of repeat, and we can't simply
   % list instructions after a repeat, so we need to
   % build two repeats and append them.
    construct Body1 [repeat declaration_or_statement]
        _ [addDebugEnter ParseFunctionName]

    construct Body2 [repeat declaration_or_statement]
	    if (index == count){
	       % at the end.
	       %return true;
	       SucceedStmts
	    }
	    if (ParseFunctionName('&(buffer'[index']) , thePDU, name, endianness)){
		if (SetParseFunctionName(buffer,thePDU, index+1, count, name, endianness)){
		    %return true;
		    SucceedStmts
		}
		FreeFunctionName( '& ( 'buffer '[ 'index '] ') ') ';
	    }
	    %return false;
	    FailStmts

    construct ParseFunction [parse_function]
	'static 'bool SetParseFunctionName(TypeName * buffer, PDU *thePDU, unsigned int index, unsigned int count, char * name, uint8_t endianness){
	    Body1 [. Body2]
	}
    construct ParseRule [rule_definition]
    	ParseFunction
    by
      Rules  [. ParseProtoRule]
             [. ParseRule]
end function

function addLengthSetOfFunction aSetOfFunction [set_of_function]
    deconstruct aSetOfFunction
       'Length TypeName [id] SetParseFunctionName [id] ShortTypeName [id]
    replace [repeat rule_definition]
	Rules [repeat rule_definition]

    construct ParseFunctionProto [private_parse_prototype]
	'static TypeName * SetParseFunctionName(PDU *thePDU, unsigned int index, unsigned int *count, char * name, uint8_t endianness);

    construct ParseProtoRule [rule_definition]
    	ParseFunctionProto

    construct ParseFunctionName [id]
       _ [+ 'parse]
         [+ TypeName]

    import NullId [id]
    	%_ [unquote '"NULL"]

    construct ParseFunction [parse_function]
	'static TypeName * SetParseFunctionName(PDU *thePDU, unsigned int index, unsigned int *count, char * name, uint8_t endianness){
	    TypeName * retVal;
	    if (thePDU '-> remaining == 0){
	       % at the end.
	       *count = index;
	       retVal = (TypeName *)malloc(index * sizeof(TypeName));
	       return retVal;
	    }
	    TypeName tmp;
	    if (ParseFunctionName('&(tmp) , thePDU, name, endianness)){
		if ((retVal = SetParseFunctionName(thePDU, index+1, count, name, endianness)) != NullId){
		    retVal '[ index '] = tmp;
		    return retVal ';
		}
	        %TODO: define and call free for this type
	    } 
	    return NullId ';
	}
    construct ParseRule [rule_definition]
    	ParseFunction
    by
      Rules  [. ParseProtoRule]
             [. ParseRule]
end function

function addTermSetOfFunction aSetOfFunction [set_of_function]
    deconstruct aSetOfFunction
       'Term TypeName [id] SetParseFunctionName [id] ShortTypeName [id] TermType [id]

    replace [repeat rule_definition]
	Rules [repeat rule_definition]

    construct ParseFunctionProto [private_parse_prototype]
	'static TypeName * SetParseFunctionName(PDU *thePDU, unsigned int index, unsigned 'long *count, char * name, uint8_t endianness);

    construct ParseProtoRule [rule_definition]
    	ParseFunctionProto

    construct ParseFunctionName [id]
       _ [+ 'parse]
         [+ TypeName]

    construct FreeFunctionName [id]
       _ [+ 'free]
         [+ TypeName]

    import NullId [id]
    	%_ [unquote '"NULL"]

    construct ParseFunction [parse_function]
	'static TypeName * SetParseFunctionName(PDU *thePDU, unsigned int index, unsigned 'long *count, char * name, uint8_t endianness){
	    TypeName * retVal;
	    TypeName tmp;
	    if (ParseFunctionName('&(tmp) , thePDU, name, endianness)){
		if (tmp . 'type == TermType [+ '_VAL]){
		    retVal = (TypeName *)malloc( '++index * sizeof(TypeName));
		    retVal '[ index-1 '] = tmp;
		    *count = index;
		    return retVal;
		} else {
		    if ((retVal = SetParseFunctionName(thePDU, index+1, count, name, endianness)) != NullId){
			retVal '[ index '] = tmp;
			return retVal ';
		    }  else {
			FreeFunctionName( '& 'tmp ') ';
		    }
		}
	    } 
	    return NullId ';
	}

    construct ParseRule [rule_definition]
    	ParseFunction
    by
      Rules  [. ParseProtoRule]
             [. ParseRule]
end function

function addEndSetOfFunction aSetOfFunction [set_of_function]
    % no end terminal type
    deconstruct aSetOfFunction
       'End TypeName [id] SetParseFunctionName [id] ShortTypeName [id]  CallbackInfo [opt callbackInfo]

    replace [repeat rule_definition]
	Rules [repeat rule_definition]

    % this is a bit of a dodge. The ParmName
    % is only used if it is submessage, in rules fixArgsSubmessage
    % so default is udnerscore (empty ID) If submessage is on
    % the the subrule will generate the name of the parameter for use
    construct ParmName [id]
    	_ [submessageCallName CallbackInfo]

    construct ParseFunctionProto [private_parse_prototype]
	'static TypeName * SetParseFunctionName(PDU *thePDU, SubmessageParentParam, unsigned int index, unsigned 'long *count, char * name, uint8_t endianness);

    construct ParseProtoRule [rule_definition]
    	ParseFunctionProto
	    [fixParmNoSubmessage]
	    [fixParmSubmessage ParmName CallbackInfo]

    construct ParseFunctionName [id]
       _ [+ 'parse]
         [+ TypeName]
	 [addSubCallbackToParseName2 CallbackInfo]

    construct FreeFunctionName [id]
       _ [+ 'free]
         [+ TypeName]

    import NullId [id]
    	%_ [unquote '"NULL"]

    construct ParseFunction [parse_function]
	'static TypeName * SetParseFunctionName(PDU *thePDU, SubmessageParentParam, unsigned int index, unsigned 'long *count, char * name, uint8_t endianness){
	    TypeName * retVal;
	    TypeName tmp;
	    if (ParseFunctionName('&(tmp) , SubmessageParentArg, thePDU, name, endianness)){
		if ((retVal = SetParseFunctionName(thePDU, SubmessageParentArg, index+1, count, name, endianness)) != NullId){
		    retVal '[ index '] = tmp;
		    return retVal ';
		}  else {
		    FreeFunctionName( '& 'tmp ') ';
		}
	    }  else {
	        if (thePDU '-> remaining == 0){
		    retVal = (TypeName *)malloc( 'index * sizeof(TypeName));
		    retVal '[ index-1 '] = tmp;
		    *count = index;
		    return retVal;
		}
	    }
	    return NullId ';
	}

    construct ParseRule [rule_definition]
    	ParseFunction
	    [fixParmNoSubmessage]
	    [fixParmSubmessage ParmName CallbackInfo]
	    [fixArgsNoSubmessage]
	    [fixArgsSubmessage ParmName]
    by
      Rules  [. ParseProtoRule]
             [. ParseRule]
end function

function addSubCallbackToParseName2 CallbackInfo [opt callbackInfo]
    replace  [id]
    	ParseName [id]
    import SubMsgArg [number]
    	'1
   deconstruct CallbackInfo
    '@ TypeName [id]
    by
        ParseName [+ '_] [+ TypeName] [+ '_Callback]
end function

function fixParmNoSubmessage
    replace * [list argument_declaration]
    	SubmessageParentParam , Rest [list argument_declaration]
    import SubMsgArg [number]
    	'0
    by
    	Rest
end function

rule fixParmSubmessage ParmName [id] CallbackInfo [opt callbackInfo]
    replace * [list argument_declaration]
    	SubmessageParentParam , Rest [list argument_declaration]
    import SubMsgArg [number]
    	'1
   deconstruct CallbackInfo
    '@ TypeName [id]
    by
        TypeName '* ParmName, Rest
end rule


function submessageCallName CallbackInfo [opt callbackInfo]
   replace [id]
   	_ [id]
   deconstruct CallbackInfo
    '@ TypeName [id]
   by
   	TypeName [tolower]
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
