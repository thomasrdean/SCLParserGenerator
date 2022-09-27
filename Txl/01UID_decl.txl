% Generate Header
% Ali El-Shakankiry
% Queen's University, Jan 2017

% Copyright 2017 Thomas Dean

% Revision history:

% 2.0 Release Version		- KPL	06 06 2018
%	  All known issues resolved
% 1.1 Documentation			- KPL	06 26 2017
% 1.0 Initial revision 		- AES 	01 01 2017 

% This program walks through a SCL5 definition of a protocol and ensures 
% unique naming for all definitions by appending the protocol name in hat notation

% The input to the program is a SCL5 file named "protocol".scl5. The input 
% file is a SCL5 description of a protocol that the user wants to generate
% a parser for

% The output of this program is a SCL5 file named "protocol"_decl.scl5.
% The output file is the original SCL5 file with unique naming of all definitions.


% Base grammars

include "ASNOne.Grm"

% Main rule followed by other rules in topological order

function main
    replace [program]
	P [program]
    export ErrorCount [number]
    	0
    by
	P [checkSyntaxRestrictions]
	  [checkErrors]
	  [noUnderscores]
	  [doDecls]
	  [checkMissedDecl]
	  [checkErrors]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 1: The new grammar is a bit more permissive than the language.
% - it allows a size constraint and type attribute on a stuctured type
% - it allows nesting of structured types
% Thesse three rules report an error if this occurs in the file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function checkSyntaxRestrictions
    replace [program]
	P [program]
    by
	P [checkSyntaxNestedStructure]
	  [checkSyntaxStructuredSize]
	  [checkSyntaxStructuredAttr]
end function

% a structured type is nested if a struct_element
% has a structured type as a type.
% ElementName has not been UID'd yet, so is user defined name
% TODO - make this first visit all structure type dfinitions
%  and pass the name of the outer type in.

rule  checkSyntaxNestedStructure
    replace $ [struct_element]
	ElementName [id] ST [structured_type]
    construct Message [stringlit]
       _ [+ '"Error: Element "]
         [+ ElementName]
         [+ '" is a nested structured type."]
	 [print]
    import ErrorCount [number]
    export ErrorCount
        ErrorCount [+ 1]
    by
    	ElementName ST
end rule

rule checkSyntaxStructuredSize
    replace $ [type_rule_definition]
	TypeName[id] '::= 
	   ST [structured_type] SZ [size_constraint] TA [repeat type_attribute]
	SCLA [opt scl_additions]
    construct Message [stringlit]
       _ [+ '"Error: Structured Type "]
         [+ TypeName]
         [+ '" has a size constraint."]
	 [print]
    import ErrorCount [number]
    export ErrorCount
        ErrorCount [+ 1]
    by
	TypeName '::= ST SZ TA SCLA 
end rule
	  
rule checkSyntaxStructuredAttr
    replace $ [type_rule_definition]
	TypeName[id] '::= 
	   ST [structured_type] SZ [opt size_constraint] TA [type_attribute] TA2 [repeat type_attribute]
	SCLA [opt scl_additions]
    construct Message [stringlit]
       _ [+ '"Error: Structured Type "]
         [+ TypeName]
         [+ '" has a type attribute."]
	 [print]
    import ErrorCount [number]
    export ErrorCount
        ErrorCount [+ 1]
    by
	TypeName '::= ST SZ TA TA2 SCLA 
end rule

function checkErrors
    replace [any]
    	P [any]
    import ErrorCount [number]
    where
    	ErrorCount [> '0]
    by
    	P [quit '1]
end function 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 2: Find any undercores in the SCL5 specification and replace them
% with the '$' character. Since underscores will be used to seperate the
% naming and unique name addition they are to not be used anywhere else
% Emit a warning to notify the user of the change in their name in SCL5
% NOTE: The '$' character was chosen out of simplicity as it is usable
% in both SCL5 and c naming without causing any issues or bugs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule noUnderscores
    replace [id]
	ID [id]
    construct US [number]
	_ [index ID "_"]		% Find the position of the "_" character in ID (if it exists
    deconstruct not US
	0				% If the location is 0 a "_" was not found; Only contine if not 0
    construct Err [stringlit]
	_ [+ "Warning: declaration \""] [+ ID] [+ "\" contains underscore '_' "]
    construct Message [stringlit]
	_ [message Err]			% Send error message to the console output
    construct LenS [number]
	_ [# ID]			% Find the length of ID
    construct sub1 [number]
	US [- 1]			% The end location of the content before the location of "_"
    construct sub2 [number]
	US[+ 1]				% The start location of the content after the location of the "_"
    construct ID2 [id]
	ID[:sub2 LenS]			% The content after the location of the "_"
    construct NEWID [id]
	ID[:0 sub1] [+ "$"] [+ ID2]	% The two halves joined together by the "$"
    by
	NEWID
end rule

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 3: This is a big step, so broken into multiple parts
%  a - check for dupliate names first. The names are scoped
%      buy the module, so only care about LHS of ::=. But uses of
%      imports take the form A.B where A is the module and B is
%      the type from the module. So the LHS cannot conflict
%      with the name of an module a type is imported from
% b - rename the LHS of type declarations and type choices.
%     In the simplified version of the language, we don't have the
%     value and other rules to rename, so that code was removed.
%     Also rename element names. The original name is kept as an annotation
%     to the renamed declaration with a ^ for syntax disambiguation.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule doDecls
    replace $ [module_definition]
	ModuleName [id] 'DEFINITIONS ::= 'BEGIN
	    Exports [opt export_block]
	    Imports [opt import_block]
	    Rules [repeat rule_definition]
	'END
    export DefinedNames [repeat id]
    	_
    by
	ModuleName 'DEFINITIONS ::= 'BEGIN
	    Exports
	    Imports [addAndCheckImportedModuleNames]
	            [renameImports]
	    Rules
	       [addAndCheckTypeRuleNames]
	       [addAndCheckTypeDecNames]
	       [checkErrors]
	       [renameTypeRule ModuleName]
	       [renameTypeDecision ModuleName]
	'END		
end rule

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 3a: Duplicate Names
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule addAndCheckImportedModuleNames
    replace $ [import_list]
	Decls [list decl] 'FROM ExModuleName [id]
    by
	Decls 'FROM
	ExModuleName [checkIfDuplicate '" in imports clause"]
		     [addIfNotDuplicate]
end rule

rule addAndCheckTypeRuleNames
    replace $ [type_rule_definition]
	TypeName [id] '::= Type [type] SclA [opt scl_additions]
    by
	TypeName [checkIfDuplicate '" in type decision definition"]
	         [addIfNotDuplicate]
	'::= Type SclA 
end rule

rule addAndCheckTypeDecNames
    replace $ [type_decision_definition]
	TypeName [id] '::= TD [type_decision] SclA [opt scl_additions]
    by
	TypeName [checkIfDuplicate '" in type rule definition"]
	         [addIfNotDuplicate]
	'::= TD SclA
end rule

function checkIfDuplicate Context [stringlit]
    replace [id]
    	Name [id]
    import DefinedNames [repeat id]
    deconstruct * [id] DefinedNames
        Name
    construct Message [stringlit]
    	_ [+ '"Error: Duplicate name "]
	  [+ Name]
	  [+ Context]
	  [print]
    import ErrorCount [number]
    export ErrorCount
        ErrorCount [+ 1]
    by
    	Name
end function

function addIfNotDuplicate
    replace [id]
    	Name [id]
    import DefinedNames [repeat id]
    deconstruct not * [id] DefinedNames
        Name
    export DefinedNames
        Name
	DefinedNames
    by
    	Name
end function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 3b: Imports, LHS and Elements
% b - rename the LHS of type declarations and type choices.
%     In the simplified version of the language, we don't have the
%     value and other rules to rename, so that code was removed.
%     Also rename element and import names. 
%     
%        A DEFINITIONS ::= BEGIN
%            B ::= (X | Y)
%            C ::= SEQUENCE {
%                M  XYZ (SIZE DEFINED),
%                N  ABC (SIZE DEFINED),
%            }
%        END
%     becomes:
%        A DEFINITIONS ::= BEGIN
%            B_A ^ B ::= (X | Y)
%            C_A ^ C ::= SEQUENCE {
%                M_C_A ^ M XYZ (SIZE DEFINED),
%                N_C_A ^ N ABC (SIZE DEFINED),
%            }
%        END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Function to rename a type rule using unique naming by adding the
% protocol name to the start of it. The name gets annotated into the
% form LONGNAME ^ ORIGINALNAME. Also must rename all its elements

rule renameTypeRule ModName [id]

    skipping [type_rule_definition]
    replace $ [type_rule_definition]
	TypeName [id] '::= Type [type] SclA [opt scl_additions]

    construct UniqueTypeName [id]
	TypeName [+ '_ ] [+ ModName]	% Unique name using protocol
    by
	'[ UniqueTypeName '^ TypeName '] '::= Type [renameStructuredType UniqueTypeName] SclA
end rule


% If the type on the RHS is a structured type
%   i.e. SEQUENCE {} or SET {}
% we have to rename the elements. Currently
% SET {} has been removed from the grammar.
% but since it will be under structured_type
% this should work without modification
% - however ths will break badly if nested
% structured types are allowed.

function renameStructuredType TypeName [id]
    replace * [structured_type]
	T [structured_type]
    by
	T [renameElements TypeName]
end function

% This rule renames all of the element Names inside
% a structured type by appending the type name (which aready
% has the module name appended.
% -- if nested structred types are added, this will
% have to be modified.

rule renameElements TypeName [id]
    skipping [struct_element]
    replace $ [struct_element]
	ElementName [id] Type [type]
    construct UniqueElementName [id]
	ElementName [+ '_ ] [+ TypeName]
    by
	'[ UniqueElementName '^ ElementName '] Type 
end rule

% Type decisions don't have nested elements, just a diffeernt
% non terminal to match

rule renameTypeDecision ModName [id]
    skipping [type_decision_definition]
    replace $ [type_decision_definition]
	TypeName [id] '::= Td [type_decision] SclA [opt scl_additions]
    construct UniqueTypeName [id]
	TypeName [+ '_ ] [+ ModName]
    by
	'[ UniqueTypeName '^ TypeName  '] '::= Td SclA
end rule

% Imports get a name generated from the external module name
% a separate step checks if the imported name was exported from
% the modue

rule renameImports
    replace $ [import_list]
	Decls [list decl] 'FROM ExModuleName [id]
    by
	Decls [renameImportedType ExModuleName] 'FROM
	ExModuleName
end rule

rule renameImportedType ModName [id]
   replace [decl]
   	TypeName[id]

    construct UniqueTypeName [id]
	TypeName [+ '_ ] [+ ModName]

   by
   	'[ UniqueTypeName '^ TypeName ']
end rule

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 4: Check if we missed anything.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule checkMissedDecl
    replace $ [decl]
	Name [id]
    construct Message [stringlit]
       _ [+ '"Error: Declarataion "]
         [+ Name]
         [+ '" was not renamed."]
	 [print]
    import ErrorCount [number]
    export ErrorCount
        ErrorCount [+ 1]
    by
	Name
end rule
