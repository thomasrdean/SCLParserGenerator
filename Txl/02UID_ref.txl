% Generate Header
% Ali El-Shakankiry
% Queen's University, Jan 2017

% Copyright 2017 Thomas Dean

% Revision history:

% 2.0 Release Version		- KPL	06 06 2018
%	  All known issues resolved
% 1.1 Documentation			- KPL	06 25 2017
% 1.0 Initial revision 		- AES 	01 01 2017 

% This program walks through a SCL5 definition of a protocol with unique 
% naming in definitions and ensures that all references match and also
% uniquely names them

% The input to the program is a SCL5 file named "protocol"_declarations.scl5. 
% The input file is a SCL5 description of a protocol that has uniquely named
% definitions from the previous TXL script.

% The output of this program is a SCL5 file named "protocol"_UID.scl5.
% The output file is the input SCL5 file with unique naming of all references.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Approach:
%    Each module is it's own namespace. Even if there are two modules in the 
%    same file, they are logically separate. So renaming is done on each module
%    indpendntly.
%    
%    There are two sets of orthogonal cases to deal with.
%    A) Classes of references
%      1. References to Types in the ASN.1 part of the code
%      2. References to Types and elements of the ASN.1 in constraints
%    B) Types of declarations
%      1. References to imported types from external modules
%      2. References to Types defined in the module.
% 
%   The rename is done in several phases.
%	1. Collect the definition of all user defined types in the module.
%	   - Stored  in a globla variable
%       2. Rename Used types in the type productions that come from the
%		imports clause
%	3. Rename Used types in the type productions and exports clause that
%		are references to other types.
%       4. Rename types in constraints based on imports clause.
%       5. Rename types in constraints based on users
% 	6. Check all references in Constraints are fixed
%	7. Create an exports table that can be used to verify imports in
%	   other modules.
%  
% TODO?? The above assumes that all references are covered by checking
%   them when we look them up. If one is missed, then incorrect code
%   is generated. Mabe move to a markup form that says that a name
%   has been renamed, so we can check for missed names? Maybe add an
%   opt * to the type_reference as a local override. check for type_referneces
%   without the opt * and report them, and quit with error code 1
% TODO?? All of the error codes are 1, should we shave different error codes
%   for different situations?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO - add check that global variables have been declared at the choice point

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Base grammars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include "ASNOne.Grm"


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main rule followed by other rules in topological order
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function main
    replace [program]
	P [program]
    export ErrorCount [number]
    	0
    by
	P  [renameRefsEachModule]
	   [checkErrs]
	   [createExportTable]
end function

% module definitions are not recursive, so this is 
% a shallow one pass rule.

rule renameRefsEachModule
    replace $ [module_definition]
       M [module_definition]
    by
       M [collectNames]
         [renameTypeRefFromImports]
         [renameTypeRefFromUserDefs]
	 [renameTypeRefInTransferAndConstraints]
	 [renameElementRefFromUserDefs]
end rule

function checkErrs
    replace [program]
	P [program]
    import ErrorCount [number]
    where
	ErrorCount [> 0]
    by
   	P [quit 1]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 1: Collect the unique declarations in the module
%     References to non-built in types
%    We start by building a list of the names declared in the module.
%    It is stored in a global variable which is a repeat of
%    pairs which contain the original name and the unique name.
%  The list is initialized to empty for each module
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% pair is used to keep track of the global names
% left is original Name, right is unique name
define name_pair
 [id] [id] [NL]
end define

function collectNames
    replace [module_definition]
       M [module_definition]
    export UserNames [repeat name_pair]
	_
    by
       M [addTypeRuleDef]
         [addTypeDecDef]
#ifdef DEBUG
	 [dumpCollectedNames]
#end
end function 

% add unique and orioginal  from LSH of a type definition
%   e.g. XYZ ::== SEQUENCENCE { ... } in MODULE ABC is renamed
%    in 01UID_decl.txl as
%       [ XYZ_ABC ^ XYZ ] ::= SEQUENCE { ... }
%    prepend the pari XYZ XYZ_ABC to the list of names

rule addTypeRuleDef
    replace $ [type_rule_definition]
	 '[ UniqueName [id] '^ OrigName [id] '] '::= T [type] S [opt scl_additions]
    import UserNames [repeat name_pair]
    export UserNames
        OrigName UniqueName
        UserNames
    by
	 '[ UniqueName '^ OrigName '] '::= T  S 
end rule

% add unique and orioginal  from LSH of a type definition
%   e.g. XYZ ::== (M | N ... ) in MODULE ABC is renamed
%    in 01UID_decl.txl as
%       [ XYZ_ABC ^ XYZ ] ::= (M | N ... )
%    prepend the pari XYZ XYZ_ABC to the list of names

rule addTypeDecDef
    replace $ [type_decision_definition]
	 '[ UniqueName [id] '^ OrigName [id] '] '::= T [type_decision] S [opt scl_additions]
    import UserNames [repeat name_pair]
    export UserNames
        OrigName UniqueName
        UserNames
    by
	 '[ UniqueName '^ OrigName '] '::= T  S 
end rule

#ifdef DEBUG
% debugging for collectNames
function dumpCollectedNames
    match [module_definition]
	ModuleName [id] 'DEFINITIONS '::= 'BEGIN
	    Exports [opt export_block]
	    Imports [opt import_block]
	    Body [repeat rule_definition]
	'END
    import UserNames [repeat name_pair]
    construct M [stringlit]
        _ [+ '"User Defined Names for Module "]
	  [+ ModuleName]
	  [+ '":"]
	  [print]
    construct UserNames2 [repeat name_pair]
    	UserNames [print]
end function
#end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 2. Rename Used types in the type productions that come from the imports
% clause
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function renameTypeRefFromImports
    replace [module_definition]
	ModuleName [id] 'DEFINITIONS '::= 'BEGIN
	    Exports [opt export_block]
	    IMPORTS ImpList [list import_list+];
	    Body [repeat rule_definition]
	'END
    by
	ModuleName 'DEFINITIONS '::= 'BEGIN
	    Exports
	    IMPORTS ImpList ;
	    Body 
	        [checkModNamesFirst ImpList]
	        [renameTypeRefEachImportList each ImpList]
	'END
end function

% first check that the X in all type references of the form
%    X.Y are imported modules.
% the next rule will assume that all X's are valid and
% check the Y's
rule checkModNamesFirst ImpList [list import_list+]
    replace $ [type_reference]
	ModName [id] '. SubName [id]
    deconstruct not * [list import_list] ImpList
        Decls [list decl] 'FROM ModName,
	Rest [list import_list]
    construct Message [stringlit]
       _ [+ '"Error: Type Reference "]
         [+ ModName]
	 [+ '"."]
         [+ SubName]
	 [+ '": Module Name "]
         [+ ModName]
	 [+ '" is not in the Imports List"]
	 [print]

    import ErrorCount [number]
    export ErrorCount
    	ErrorCount [+ 1]
    by
	ModName '. SubName
end rule

% called for each imported module list
%  E.g. A,B from M
% find all type references of the form M.Y
% and check that Y is in the list of A,B.
% rename as M.UniqueNameForY

rule renameTypeRefEachImportList ImportList [import_list]
    deconstruct ImportList
        Decls [list decl] 'FROM ModName [id]
    replace $ [type_reference]
	ModName '. SubName [id]
    construct ErrorCheck [id]
        SubName [errorIfSubNameNotInList ModName Decls]
    deconstruct * [decl] Decls
       '[ UniqueSubName [id] '^ SubName ']
    by
	ModName
	'. UniqueSubName 
end rule

function errorIfSubNameNotInList ModName [id] Decls [list decl]
    match [id]
        SubName [id]
    deconstruct not * [id] Decls
        SubName

    construct Message [stringlit]
       _ [+ '"Error: Type reference "]
         [+ ModName]
         [+ '"."]
         [+ SubName]
         [+ '": imported type name "]
         [+ SubName]
         [+ '" is not in the types imported from "]
         [+ ModName]
         [print]

    import ErrorCount [number]
    export ErrorCount
        ErrorCount [+ 1]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 3. Rename Used types in the type productions and exports clause that are
%  references to other types. We import the list and pass it as a parameter.
% Simple lookup  is used to find them
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function renameTypeRefFromUserDefs
    replace [module_definition]
       M [module_definition]
    import UserNames [repeat name_pair]
    by
       M [renameUserTypeRefsFromDefs UserNames]
end function 

% no dot becuse it is a reference to a type in the
% same module

rule renameUserTypeRefsFromDefs UserNames [repeat name_pair]
    replace $ [type_reference]
	Name [id]
    construct NameCheck [id]
    	Name [errorIfNotDefined UserNames]
    deconstruct * [name_pair] UserNames
         Name UniqueName [id]
    by
	UniqueName
end rule

function errorIfNotDefined UserNames [repeat name_pair]
    match [id]
    	Name [id]
    deconstruct not * [name_pair] UserNames
         Name _ [id]
    construct Message [stringlit]
       _ [+ '"Error: Type reference "]
         [+ Name]
         [+ '" is not defined as a type in the file"]
         [print]

    import ErrorCount [number]
    export ErrorCount
        ErrorCount [+ 1]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 4. Rename types in constraints based on imports clause.
%   - this runs before the rename assuming element names
%   - only does matches, doesn't generate an error message.
%   - if something is misspelled, then it will assume it is an element name
%	- then element rules will generate the error message
%
% TODO - modify grammar to know when it should be a type reference?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function renameTypeRefInTransferAndConstraints
    replace [module_definition]
       M [module_definition]
    import UserNames [repeat name_pair]
    deconstruct * [repeat rule_definition] M
    	Rules [repeat rule_definition]
    by
	M [renameTypesInStructureConstraints UserNames Rules]
end function

rule renameTypesInStructureConstraints UserNames [repeat name_pair] Rules [repeat rule_definition]
   replace $ [type_rule_definition]
       '[ UniqueName [id] '^ TypeName [id] '] '::= St[structured_type]
	   Encoding [opt encoding_grammar_indicator]
	   Trans [opt transfer_rules_block]
	   Constraints [opt constraints_block]
   by
       '[ UniqueName '^ TypeName '] '::= St
	   Encoding
	   Trans  [renameTypsInStructure TypeName UserNames Rules]
	   Constraints
end rule

rule renameTypsInStructure TypeName [id] UserNames [repeat name_pair] Rules [repeat rule_definition]
    skipping [referenced_element]
    replace $ [referenced_element]
       Root [id] RestInputReferenceChain [repeat dotReference]

    deconstruct * [name_pair] UserNames
        Root RootUniqueName[id]

    % recursive rule to fix the rest of the 
    % elements in the chain
    % TODO 
    % this is different from  the other, in that the
    % first element of the name was a type name instead
    % of a element name, so we have to first do a lookup
    % of the first name in the type name instead
    %construct RestOfReference [repeat dotReference]
    %   _ [recursiveElementName TypeName RestInputReferenceChain T Rules]
    % for now, just copy the chain, and it will generate an error later.

    by
       '[ RootUniqueName RestInputReferenceChain '^ Root RestInputReferenceChain ']
end rule

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 5. Rename types in constraints based on user types
%  - The main issue here is element names in strcutures.
%     BACK{ a.b.c.d.e == 5 }
%    a must be a field in the current structure, The type of A must be a structure
%    and b is s field in the structure
% TODO: implement elementAt(number) e.g. a.b.c.elementAt(3).d. the type of C
% must be SEQUENCE OF <type>, and 3 refers to the 3rd memnber in the sequence.
% TODO: go through alias types. e.g. a.b.c.d, where the type of c is M and
%     M ::= N, and N ::= SEQUENCE {..  d  ...} is valid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function renameElementRefFromUserDefs
    replace [module_definition]
       M [module_definition]
    deconstruct * [repeat rule_definition] M
    	Rules [repeat rule_definition]
    by
       M [renameElementsInStructuredConstraints Rules]
end function 

% do structures first. Figure out others later.
% TODO: constraints not implemented yet either.
% note: constraints may refer to fields in other types

rule renameElementsInStructuredConstraints Rules [repeat rule_definition]
   replace $ [type_rule_definition]
       '[ UniqueName [id] '^ TypeName [id] '] '::= St[structured_type]
	   Encoding [opt encoding_grammar_indicator]
	   Trans [opt transfer_rules_block]
	   Constraints [opt constraints_block]
   by
       '[ UniqueName '^ TypeName '] '::= St
	   Encoding
	   Trans  [renameElementinStructure TypeName St Rules]
	   Constraints
end rule

rule renameElementinStructure TypeName [id] St [structured_type] Rules [repeat rule_definition]
    skipping [referenced_element]
    replace $ [referenced_element]
       Root [id] RestInputReferenceChain [repeat dotReference]

    construct NewR [id]
    	Root [errorIfNotDefinedInStructure TypeName TypeName St]
	     [replaceByUniqueElementName St]

    % get the type of the field.
    deconstruct * [struct_element] St
	'[ _ [id] '^ Root '] T [type]

    % recursive rule to fix the rest of the 
    % elements in the chain
    % TTTTTT - broken here...
    construct RestOfReference [repeat dotReference]
       _ [recursiveElementName TypeName RestInputReferenceChain T Rules]
    by
       '[ NewR RestOfReference '^ Root RestInputReferenceChain ']
end rule

function errorIfNotDefinedInStructure TypeName [id] TransferTypeName [id] St [structured_type]
    match [id]
	FieldName [id]
    deconstruct not * [decl] St
	'[ _ [id] '^ FieldName ']
    construct Message [stringlit]
	_ [+ '"Error: element "]
          [+ FieldName]
	  [+ '" referenced in transfer block for "]
          [+ TransferTypeName]
          [+ '" is not defined in "]
          [+ TypeName]
          [+ '"."]
          [print]
    import ErrorCount [number]
    export ErrorCount
        ErrorCount [+ 1]
end function

function replaceByUniqueElementName St [structured_type]
    replace [id]
	FieldName [id]
    deconstruct * [decl] St
	'[ UniqueFieldName [id] '^ FieldName ']
    by
	UniqueFieldName 
end function

function recursiveElementName TransferTypeName [id] RestInputReferenceChain [repeat dotReference]  T [type] Rules [repeat rule_definition]
    replace [repeat dotReference]
       ChainSoFar [repeat dotReference]
    by
       ChainSoFar  
		   [recursiveStructureTypeName TransferTypeName RestInputReferenceChain T Rules]
                  %[recursiveAliasTypeName RestInputReferenceChain T Rules]
		  %[recursiveElementAt RestInputReferenceChain T Rules]
		  [checkForFailure TransferTypeName T RestInputReferenceChain ChainSoFar]
end function

% is the current elemnnt part of a structured type
function recursiveStructureTypeName TransferTypeName [id] RestInputReferenceChain [repeat dotReference]  T [type] Rules [repeat rule_definition]
   % T is the name of a structured type.
   % we don't allow nested SEQUENCES at this
   % point in time.

   deconstruct * [id] T
       UniqueTypeName [id]
   deconstruct RestInputReferenceChain
       '. ElementName [id] Tail [repeat dotReference]

   % we already know that TypeName exists, because we have
   % renamed the type references. If it is wrong rules in
   % step 3 will have already produced an error message.

    deconstruct * [type_rule_definition] Rules
       '[ UniqueTypeName  '^ TypeName[id] '] ::= St [structured_type] SclA [opt scl_additions]

    construct NewName [id]
    	ElementName [errorIfNotDefinedInStructure TypeName TransferTypeName St]
	     [replaceByUniqueElementName St]

    % get the type of the field.
    deconstruct * [struct_element] St
	'[ _ [id] '^ ElementName '] T2 [type]

    construct NewChainElement [dotReference]
        '. NewName
    replace [repeat dotReference]
       ChainSoFar [repeat dotReference]
    by
       ChainSoFar  [. NewChainElement]
            [recursiveElementName TransferTypeName Tail T2 Rules]
end function

% is the current elemnnt part of an alias type
%function recursiveAliasTypeName RestInputReferenceChain T Rules
%end function

% is the current elemnnt  an elementAt() -- Not Implemented yet
% currently removed from grammar
%function recursiveElementAt RestInputReferenceChain T Rules
%   deconstruct RestInputReferenceChain
%       '. 'elementAt( [expr]} Tail [repeat dotReference]
%end function

% if the length of RD is not zero (more fields to process)
% and ChainSoFar is the same as the scope, then the recursive
% rules failed..

function checkForFailure TransferTypeName [id] T [type] RestInputReferenceChain [repeat dotReference]  ChainBeforeReplace [repeat dotReference]
    % where there is at least one element in RestInputReferenceChain
    deconstruct RestInputReferenceChain
        '. IorR [index_or_reference]

    % and the current scope is the same as the scope before the 
    % applicaiton of the recursive rules
    match [repeat dotReference]
       ChainBeforeReplace

   deconstruct * [id] T
       UniqueTypeName [id]

    construct Message [stringlit]
	_ [+ '"Error: reference to element "]
          [quote IorR]
	  [+ '" referenced in transfer block for "]
          [+ TransferTypeName]
          [+ '" is not defined in "]
          [+ UniqueTypeName]
          [+ '"."]
          [print]
    import ErrorCount [number]
    export ErrorCount
        ErrorCount [+ 1]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 6. Check all references in Constraints are fixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 7. Create an exports table that can be used to verify imports in
%	  other modules. Also need a verify imports that reads the tables
% TODO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule createExportTable
    skipping [module_definition]
    replace $ [module_definition]
	ID [id] 'DEFINITIONS '::= 'BEGIN
		EXPORTS Types [list type_reference] ';
		Imports [opt import_block]
		Body [repeat rule_definition]
	'END
    by
	ID 'DEFINITIONS '::= 'BEGIN
	    EXPORTS Types [writeExports ID] ';       % Iterate through the contents
				    % of the module's [export_block]
	    Imports
	    Body
	'END    % No replacement
end rule

function writeExports ModuleName [id]
    replace [list type_reference]
	LIST [list type_reference]

    construct IDirSeed [stringlit]
    	"noDir"

    construct IntermediateDir [stringlit]
    	IDirSeed [getDirFromCommandLine]
	    [errorIfNoDirOnCommandLine IDirSeed]
	    %[putp "The intermediate directory is %"]

    construct outputFile [stringlit]
	    _ [+ IntermediateDir] [+ "/"] [+ ModuleName] [+ ".exports"]
	      %[putp  "Ouput file is %"]
    by
	LIST [write outputFile]
end function

function getDirFromCommandLine
    replace [stringlit]
    	_ [stringlit]
    import TXLargs [repeat stringlit]
    deconstruct * [repeat stringlit] TXLargs
    	"-Intermediate" IDir [stringlit] Rest [repeat stringlit]
    by
    	IDir
end function

function errorIfNoDirOnCommandLine InitVal [stringlit]
    match [stringlit]
    	InitVal
    construct Msg [stringlit]
    	_ [+ "Must specify intermediate directory on command line with -Intermediate <dirname>"]
	  [print]
	  [quit 1]
end function

%============================================================================
%============================================================================
%============================================================================
%============================================================================

