% Generate Header
% Ali El-Shakankiry
% Queen's University, Jan 2017

% Copyright 2017 Thomas Dean

% Revision history:

% 2.1 Fixed bug of LL(1) not properly checking that all entries in a type
% 	  decision have an annotation, generating false lookahead blocks
%								- KPL	08 29 2018
% 2.0 Release Version			- KPL	06 06 2018
%	  All known issues resolved
% 1.3 	Bug fix for LL(1) transfer statements on user defined types;
% 		Can only optimize if the field has the same offset in all 
% 		occurances				- KPL 	06 04 2017
% 1.2 	Documentation			- KPL	06 27 2017
% 1.1 	Callback annotation 	- KPL	06 14 2017
% 1.0 	Initial revision 		- AES 	01 01 2017 

% This program walks through a uniquely named SCL5 description of a protocol
% and searches for areas to optimize the parse. A type decision parse can
% be optimized if each element of the type decision has a kind/type element
% that is constrained to be a unique value in that type decision. These
% are then optimizable as when the code is generated the kind can be parsed
% and then based on the unique value of it, the type of the type decision is
% then known and can be parsed. Otherwise each type must be attempted to be
% fully parsed until the parse succeeds, indicating the correct type was found.

% The input to the program is a SCL5 file named "protocol"_callbackAnnotated.scl5.
% The input file is a SCL5 description of a protocol that has unique naming of all
% declaration and references and has attempted to optimize callbacks by adding
% callback annotations

% The output of this program is a SCL5 file named "protocol"_UID_annotated.scl5.
% The output file is the imput SCL5 file with parse optimizations added as annotations
% in the respective rule definitions. Additionally callback optimizations will be
% removed when found in conflict with parse optimizations.


% Base grammars

include "ASNOne.Grm"
include "annot.ovr"

% Local grammar overrides

% Main rule followed by other rules in topological order

function main
    replace [program]
	P [program]

    % Global variable to hold the [id]'s of rules that need
    % to have the @ callback annotation removed
    %construct RemoveAT [repeat id]
    	% empty
    %export RemoveAT

    % Global variable to hold the [id]'s of rules that need
    % to have a callback with the [id] [id] annotation removed
    %construct RemoveID [repeat id]
    	% empty
    %export RemoveID

    construct TypeRules [repeat type_rule_definition]
	_ [^ P]	% Extract all of the original type rule definitions from the program
    construct TypeDecisions [repeat type_decision_definition]
	_ [^ P]	% Extract all of the original type rule definitions from the program

    by
	P [annotatePOS]
	  [annotateGlobals TypeRules TypeDecisions]
	  [calculateSizes]
	  [checkTypeSizes]
	  [annotateStructRulesNewRules] 
	  [fixTypeDecisions]
	  %[checkforOptimization]
	  %[removeOptimizedCallbackANN]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 1. POS annotation
% - add @ POS to elemenets that are used in POS constraints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule annotatePOS
    replace $ [type_rule_definition]
	'[ UniqueID [id] '^ ShortName [id] '] '::= 'SEQUENCE OptSize [opt size_constraint] '{
		Fields [list struct_element] OptComma [opt ',]
	'} Encoding [opt encoding_grammar_indicator] 
	'<transfer>
	    TransStmts [repeat transfer_statement]
	'</transfer>
	ConsBlock [opt constraints_block]

    % guard
    deconstruct * [pos_expression] TransStmts
    	_ [pos_expression]

    % Extract all the POS constraints so they can be searched
    construct POSConstraints [repeat pos_expression]
	_ [^ TransStmts]

    % Annotate all the [struct_element]'s with @ POS where required
    by
	'[ UniqueID '^ ShortName '] '::= 'SEQUENCE OptSize '{

	    Fields [checkMatchingPOSConstraint POSConstraints]
	   
	    OptComma
	'} Encoding
	'<transfer>
	    TransStmts
	'</transfer>
	ConsBlock
end rule


% Check each [struct_element] in the fields to see if its Unique Name matches the 
% name in a POS constraint. If it does  add @POS to the field name declaration
%
rule checkMatchingPOSConstraint POSConstraints [repeat pos_expression]
    replace $ [struct_element]
	'[ UniqueID [id] '^ FieldName [id]  '] Annots [repeat annotation_item] Type [type]
    deconstruct * [pos_expression] POSConstraints
	'POS '( '[ UniqueID '^ _ [id] '] ')
    by
	'[ UniqueID '^ FieldName '] '@ 'POS Annots Type
end rule


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 2 Globals - A type decision with GLOBAL(X) and @GLOBL(X) == V for
% each of the types referred to by the GLOBAL
% To substeps
%   1 name check. Check that every name in a global constraint (i.e. GLOBAL(X) == V)
%     is delcared on a type decision somehere
%   2. Copy to the ference in the type decision. E.g. if type rule A has GLOBAL(X)==3
%    then Z ::= (A | ...) becomes Z ::= (A @ GLOBAL 3 | ... )
%   3. check that all type references have annotations mark type_decl for the
%	type decision with @BROKEN_GLOBAL if not
%   4. check that there are no duplciates, mark tuype_decl for the
%	type decision with @BROKEN_GLOBAL if not
%   5. mark type_decl in the type decision definition as @GLOBAL if not marked
%	as @BOKEN_GLOBAL
%
% TODO - should have a rule to ensure that all GLOBALS in type structures
% are used in equivalence expressions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function annotateGlobals TypeRules[repeat type_rule_definition] TypeDecisions [repeat type_decision_definition]
    replace [program]
    	P [program]
    by
    	P [checkEachGlobalValConstraint TypeDecisions]
          %[copyToTypeDefAnnotation]
	  [annotateGlobalTypeDecision TypeRules]
end function

% Step 2.1 Check that Global vars referenced in type definfitions were declared in
% type decisions
rule checkEachGlobalValConstraint TypeDecisions [repeat type_decision_definition]
    replace $ [type_rule_definition]
	'[ UniqueID [id] '^ ShortName [id] '] '::= 'SEQUENCE OptSize [opt size_constraint] '{
		Fields [list struct_element] OptComma [opt ',]
	'} Encoding [opt encoding_grammar_indicator] 
	'<transfer>
	    TransStmts [repeat transfer_statement]
	'</transfer>
	ConsBlock [opt constraints_block]

    % guard
    deconstruct * [global_expression] TransStmts
    	_ [global_expression]

    % Extract all the POS constraints so they can be searched
    construct GlobalExpressions [repeat global_expression]
	_ [^ TransStmts]

    construct Warning [id]
    	ShortName [warnIfNotDeclared TypeDecisions each GlobalExpressions]

    % Annotate all the [struct_element]'s with @ POS where required
    by
	'[ UniqueID '^ ShortName '] '::= 'SEQUENCE OptSize '{
	    Fields
	    OptComma
	'} Encoding
	'<transfer>
	    TransStmts
	'</transfer>
	ConsBlock
end rule

function warnIfNotDeclared TypeDecisions [repeat type_decision_definition] aGlobalExpression[global_expression]
    match [id]
	ShortName [id]

    deconstruct not * [global_expression] TypeDecisions
	aGlobalExpression

    deconstruct aGlobalExpression
   	'GLOBAL '( GVar [id] ')

    construct Msg [stringlit]
        _ [+ '"Global variable "]
	  [+ GVar ]
	  [+ '" referenced in type definition "]
	  [+ ShortName]
	  [+ '" has not be defined in a type decision"]
	  [print]

end function


% step 2.2 - Copy annotations from Type rules to references in type decisions
rule annotateGlobalTypeDecision TypeRules [repeat type_rule_definition]
    replace $ [type_decision_definition]
       TypeDecDef [type_decision_definition]

    % guard so that we only work on type decision with global var
    deconstruct * [global_expression] TypeDecDef
        'GLOBAL '( GVar[id] ')

    by
    	
       TypeDecDef
          % first do markup on all of the type references
          [annotateRefsInTypeDecision GVar TypeRules]

	  % verify that all have an annotation and error if not
	  [verifyAllRefsAreGlobalAnnotated]

	  % verify that alll values are mutuall exclusive
	  [verifyGlobalsMutuallyExclusive]
	  % if so, add the annotation to the tye_decl for
	  % the type decision
	  [annotateGlobalDeclaration]
end rule

function annotateRefsInTypeDecision GVar [id] TypeRules [repeat type_rule_definition]
    replace [type_decision_definition]
	'[ UniqueID [id] '^ ShortName [id]  '] Annots [repeat annotation_item] '::= TD [type_decision]
	SCLAdd [opt scl_additions] 

    by
	'[ UniqueID '^ ShortName '] Annots '::= 
	    TD [annotateEachTypeReference GVar TypeRules]
	SCLAdd
end function

% copyt the global constraint to each branch of the type decision.
rule annotateEachTypeReference GVar [id]  TypeRules [repeat type_rule_definition]
    replace $ [type_reference]
    	UniqueID [id] 
    deconstruct * [type_rule_definition] TypeRules
	'[ UniqueID '^ ShortName [id] '] '::= 'SEQUENCE OptSize [opt size_constraint] '{
                Fields [list struct_element] OptComma [opt ',]
        '} Encoding [opt encoding_grammar_indicator]
        '<transfer>
            TransStmts [repeat transfer_statement]
        '</transfer>
        ConsBlock [opt constraints_block]

    construct Msg [id]
       ShortName %[checkIfGlobal GVar] -- TODO check that the global in this structure is based on GVar
       		% error if not, because next deconstruct will fail silently.

    deconstruct * [back_block] TransStmts
        'Back '{ 'GLOBAL '( GVar ') '== Val [number] '} % should be value_expression and covert hex/stringlit  to value
    by
    	UniqueID @ GLOBAL Val
end rule

% check all of the type_refs in the type decision. Genereate
% an error message if one is missing a global annotation.

function verifyAllRefsAreGlobalAnnotated
    replace [type_decision_definition]
	'[ UniqueID [id] '^ ShortName [id]  '] Annots [repeat annotation_item] '::= TD [type_decision]
	SCLAdd [opt scl_additions] 

    construct AllTypeRefs [repeat type_reference]
    	_ [^ TD]
    construct Msg [id]
	ShortName [checkForMissingGlobalAnnotation ShortName each AllTypeRefs]
    deconstruct not Msg
    	ShortName
    by
	'[ UniqueID  '^ ShortName '] '@ 'BROKEN_GLOBAL Annots  '::= TD
	SCLAdd
end function

function checkForMissingGlobalAnnotation ShortName [id] aTypeRef [type_reference]
    replace [id]
	_ [id]

    deconstruct not * [global_annotation] aTypeRef
    	_ [global_annotation]

    deconstruct * [id] aTypeRef
    	TypeRefName [id]

    construct Msg [stringlit]
    	_ [+ '"Type reference "]
	  [+ TypeRefName]
	  [+ '" in type decision "]
	  [+ ShortName]
	  [+ '" does not have a global constraint"]
	  [print]
    by
    	'BROKEN_GLOBAL
end function

% verify that alll values are mutuall exclusive and if so, 
% add the annotation to the tye_decl for the type decision

define global_bin
   [number] [repeat id] [NL]
end define

function verifyGlobalsMutuallyExclusive
    replace [type_decision_definition]
	'[ UniqueID [id] '^ ShortName [id]  '] Annots [repeat annotation_item] '::= TD [type_decision]
	SCLAdd [opt scl_additions] 

    % verify all of the annotations on the type decision are mutually exclusive
    construct AllTypeRefs [repeat type_reference]
        _ [^ TD]

    % we use an each rule to add a bin that contains a number
    % and the typerefs that use that number. Aftewards we see
    % if a bin  has more than one. We could generate an error
    % message as soon as we see a duplicate, but then if there
    % are three, there would be too many error messages
    construct Bins [repeat global_bin]
    	_ [addGlobalTypeRef each AllTypeRefs]
	  %[putp "bins are %"]
	  [checkForGlobalBinWithMoreThanOneEntry ShortName]
    deconstruct * [repeat id] Bins
        Id1 [id] Id2 [id] Rest [repeat id]

    % if so, add annotation to result
    by
	'[ UniqueID  '^ ShortName '] '@ 'BROKEN_GLOBAL Annots  '::= TD
	SCLAdd
end function

function annotateGlobalDeclaration
    replace [type_decision_definition]
	'[ UniqueID [id] '^ ShortName [id]  '] Annots [repeat annotation_item] '::= TD [type_decision]
	SCLAdd [opt scl_additions] 

    % check that the previous rules didn't mark it as broken
    deconstruct not * [broken_global_annotation] Annots
    	_ [broken_global_annotation]

    by
	'[ UniqueID  '^ ShortName '] '@ 'GLOBAL Annots  '::= TD
	SCLAdd
end function

function addGlobalTypeRef aTypeRef [type_reference]
     replace [repeat global_bin]
        Bins [repeat global_bin]
     by
        % order of functions is important. 
	% if you run addToExisting after addNew,
	% it will always match. So we first
	% attpemtp to add to an existing bin
	% and add a bin if that fails.
     	Bins [addToExistingBin aTypeRef]
	     [addNewBin aTypeRef]
end function

function addNewBin aTypeRef [type_reference]
     deconstruct aTypeRef
        Name [id] '@ 'GLOBAL Val [number]
     replace [repeat global_bin]
        Bins [repeat global_bin]
     deconstruct not * [global_bin] Bins
         Val List [repeat id]
     by
     	  Val Name Bins
end function

function addToExistingBin aTypeRef [type_reference]
     deconstruct aTypeRef
        Name [id] '@ 'GLOBAL Val [number]
     replace * [repeat global_bin]
     	Val List [repeat id] Bins [repeat global_bin]
     by
     	Val Name List Bins
end function 

rule checkForGlobalBinWithMoreThanOneEntry TDName [id]
    replace $ [global_bin]
    	Val [number] List [repeat id]

    % at least two items
    deconstruct List
    	ID1 [id] ID2 [id] Rest [repeat id]

    construct Msg [stringlit]
        _ [+ '"Type Decision "]
	  [+ TDName]
	  [+ '" has one value ("]
	  [+ Val]
	  [+ '") for multiple choices:"]
	  [addEachIdToGlobalErrMsg each List]
	  [print]
    by
    	Val List
end rule

function addEachIdToGlobalErrMsg aTypeRefName [id]
    replace [stringlit]
	S [stringlit]
    by
	S [+ '" "]
	  [+ aTypeRefName]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 3, find all the constant positions for Structure definitions, and the
%   sizes of all user defined types
% approach? 
% rule that runs until the program doesn'tchange
%	- extract structure definitions
%     - one pass rule that applies to each stducture definition
%     - use recursive subrule that:
%	   -- skips over fields that are already position
%          -- then checks the following fields to see if size is known
%	   -- once not, rest are marked as VAR
%	   -- added, if a following element is constant size, then
%	      @VAR N where n is size is used, since the pos is not known
%		but the size is.
%
% also looks at type deicisiions and if the sizes are not all the same
% or any are var, marks as var
%
% Probably would be more efficience if we did a toplogical sort to
% do them in order, but none of these will be particularly large.
%
% Probably a way to refactor to remove some of the redunancy, but
% this now works and is reasonably modular T.D.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule calculateSizes
    replace [program]
    	P [program] 


    construct NewP [program]
    	P [updatePosAndSizesStructs P]
	  [updateSizeTypeDecision P]

    deconstruct not NewP
    	P
    by
        NewP
end rule

% report ay type_decls without annotations
rule checkTypeSizes
    replace $ [type_decl]
       '[ Long [id] '^ Short [id] ']  Annots [repeat annotation_item]
    deconstruct not * [pos_size_annotation] Annots
    	_ [pos_size_annotation]

    construct Msg [stringlit]
    	_ [+ '"Type declaration "]
	  [+ Short]
	  [+ '" does not have a calcualted size (Const or Var)"]
	  [print]

    by
       '[ Long '^ Short ']  Annots
end rule

rule updatePosAndSizesStructs P [program]
    replace $ [type_rule_definition]
	'[ UniqueID [id] '^ TypeName [id] '] Annots [repeat annotation_item] '::= 'SEQUENCE OptSize [opt size_constraint] '{
	    Fields [list struct_element] 
	    OptComma [opt ',]
	'} 
	SCLAdd [opt scl_additions]

    % If we have marked this one at the top level, it is completed
    deconstruct not * [pos_size_annotation] Annots
    	_ [pos_size_annotation]

    construct NewFields [list struct_element]
        Fields 
	    [skipPosAndSize P]
	    %[skipVar P]
	    [calcPosAndSize '0 P]
	    [calcVar P]

    construct NewAnnots [repeat annotation_item]
    	Annots [promoteSizeIfConst NewFields]
	       [promoteIfVar NewFields]
    
    by
	'[ UniqueID '^ TypeName '] NewAnnots '::= 'SEQUENCE OptSize '{
	    NewFields 
	    OptComma
	'}
	SCLAdd
end rule

%recurse down the list skipping fields that already
% have a position and size annotation until we get to
% fields without a position and size (or the end)

function skipPosAndSize Prog [program]
   replace [list struct_element]
      Name [decl] Annots [repeat annotation_item] T [type]
       , Rest [list struct_element]
   deconstruct * [const_pos_size_annotation] Annots
      P [const_pos_size_annotation]

   % note if P is VAR, then CurPos will remain 0, but
   % if P is Var then all of rest should also be Var and
   % calPosAndSize will do nothing.
   construct NextPos [number]
   	_ [retrieveNextPos P]
   by
      Name Annots T
       , Rest 
	    [skipPosAndSize Prog]
	    [calcPosAndSize NextPos Prog]
	    [calcVar Prog]
end function

function retrieveNextPos P [const_pos_size_annotation]
    deconstruct P
    	'@ 'CONST Pos[number] Size [number]
    replace [number]
       _ [number]
    by
        Pos [+ Size]
end function

%recurse down the list adding position and size to fields
% until we get a type whose size is unknown, a type whose
% type is var, or the end

function calcPosAndSize CurPos [number] Prog [program]
    replace [list struct_element]
	Name [decl] Annots [repeat annotation_item] T [type]
	, Rest [list struct_element]
    deconstruct not * [pos_size_annotation] Annots
	_ [pos_size_annotation]

    % find the size of the field from the type
    construct NewAnnot [repeat annotation_item]
   	Annots [addSizeBuiltInConstant CurPos T]
	       [addSizeUserDefinedConst CurPos T Prog]

    % only continue if a position was calculated
    deconstruct * [const_pos_size_annotation] NewAnnot
	P [const_pos_size_annotation]

    construct NextPos [number]
   	_ [retrieveNextPos P]

   by
      Name NewAnnot T
       , Rest 
	    [calcPosAndSize NextPos Prog]
	    [calcVar Prog]
end function

function addSizeBuiltInConstant CurPos [number] T [type]
    deconstruct * [size_constraint] T
    	'( 'SIZE Size [number] 'BYTES ')
    deconstruct not  * [optional] T
    	'OPTIONAL
    deconstruct not  * [slack] T
    	_ [slack]
    deconstruct not  * [align] T
    	_ [align]

    replace [repeat annotation_item]
    	A [repeat annotation_item]
    by
    	'@ 'CONST CurPos Size A
end function

function addSizeUserDefinedConst CurPos [number] T [type] Prog [program]
    deconstruct  T
    	UserTypeName [id] '( 'SIZE 'DEFINED ') TA [repeat type_attribute]
    deconstruct not  * [optional] TA
    	'OPTIONAL
    deconstruct not  * [slack] TA
    	_ [slack]
    deconstruct not  * [align] TA
    	_ [align]

    deconstruct * [type_decl] Prog
    	'[ UserTypeName '^ _ [id] '] TypeAnnots [repeat annotation_item]
    deconstruct * [pos_size_annotation] TypeAnnots
        '@ CONST _ [number] Size [number]

    replace [repeat annotation_item]
    	A [repeat annotation_item]
    by
    	'@ 'CONST CurPos Size A
end function

function skipVar Prog [program]
   replace [list struct_element]
      Name [decl] Annots [repeat annotation_item] T [type]
       , Rest [list struct_element]
   deconstruct * [var_pos_size_annotation] Annots
      P [var_pos_size_annotation]

   by
      Name Annots T
       , Rest 
	    [skipVar Prog]
	    [markVar Prog]
end function


% A field with varying size is VAR
% TODO - T may also be a type decision
function calcVar Prog[program]
   replace [list struct_element]
      Name [decl] Annots [repeat annotation_item] T [type]
       , Rest [list struct_element]

   deconstruct not * [pos_size_annotation] Annots
      _ [pos_size_annotation]

   construct NewAnnot [repeat annotation_item]
   	Annots [addVarUserDefined T Prog]
	       [addVarOptional T]
	       [addVarAlign T]
	       [addVarConstrained T]
	       [addVarSlack T]

   deconstruct * [pos_size_annotation] NewAnnot
   	P [pos_size_annotation]

   by
      Name NewAnnot T
       , Rest [markVar Prog]
end function

function addVarUserDefined T [type] Prog [program]
    deconstruct  T
    	UserTypeName [id] '( 'SIZE 'DEFINED ') TA [repeat type_attribute]

    deconstruct * [type_decl] Prog
    	'[ UserTypeName '^ _ [id] '] TypeAnnots [repeat annotation_item]

    deconstruct * [pos_size_annotation] TypeAnnots
        '@ 'VAR

    replace [repeat annotation_item]
    	A [repeat annotation_item]
    by
    	'@ 'VAR A
end function

function addVarOptional T [type]
    deconstruct * [optional] T
    	'OPTIONAL
    replace [repeat annotation_item]
    	A [repeat annotation_item]
    by
    	'@ 'VAR A
end function

function addVarAlign T [type]
    deconstruct * [align] T
    	_ [align]
    replace [repeat annotation_item]
    	A [repeat annotation_item]
    by
    	'@ 'VAR A
end function

% assume size constrained means it is governed by
% a forward constraint and there for variable
function addVarConstrained T [type]
    deconstruct * [size_constraint] T
    	'( 'SIZE 'CONSTRAINED ')

    replace [repeat annotation_item]
    	A [repeat annotation_item]
    by
    	'@ 'VAR A
end function

% technically we should be able to compute this, but for
% now being conservative.  This depends on if
% the structure is the top level or where it is in the packet.
% Same with align.
% all it means is we may have to do extra checks on the numbe of
% bytes avaiable, and may have to fall back to a non LL parsing strategy.

function addVarSlack T [type]
    deconstruct * [slack] T
    	_ [slack]
    replace [repeat annotation_item]
    	A [repeat annotation_item]
    by
    	'@ 'VAR A
end function

% once one field is var, all the rest are var
% TODO. This should add a size marker to @Var if the
% field is a constant size
function markVar Prog [program]
   replace [list struct_element]
      Name [decl] Annots [repeat annotation_item] T [type]
       , Rest [list struct_element]

   deconstruct not * [pos_size_annotation] Annots
      _ [pos_size_annotation]

   construct DefaultVarAnnot [annotation_item]
   	'@ 'VAR

   construct NewVarAnnot [annotation_item]
   	DefaultVarAnnot 
		[addVarBuiltInConstant T]
	       	[addVarUserDefinedConst T Prog]

   by
      Name NewVarAnnot Annots T
       , Rest [markVar Prog]
end function

function addVarBuiltInConstant T [type]
    deconstruct * [size_constraint] T
    	'( 'SIZE Size [number] 'BYTES ')
    deconstruct not  * [optional] T
    	'OPTIONAL
    deconstruct not  * [slack] T
    	_ [slack]
    deconstruct not  * [align] T
    	_ [align]

    replace [annotation_item]
	'@ VAR 
    by
    	'@ 'VAR Size
end function

function addVarUserDefinedConst T [type] Prog [program]
    deconstruct  T
    	UserTypeName [id] '( 'SIZE 'DEFINED ') TA [repeat type_attribute]
    deconstruct not  * [optional] TA
    	'OPTIONAL
    deconstruct not  * [slack] TA
    	_ [slack]
    deconstruct not  * [align] TA
    	_ [align]

    deconstruct * [type_decl] Prog
    	'[ UserTypeName '^ _ [id] '] TypeAnnots [repeat annotation_item]

    deconstruct * [pos_size_annotation] TypeAnnots
        '@ CONST _ [number] Size [number]

    replace [annotation_item]
    	'@ 'VAR
    by
    	'@ 'VAR Size
end function

function promoteSizeIfConst Fields [list struct_element]

    % get last field - only matches last since no Rest
    deconstruct * [list struct_element] Fields
        ED [element_decl] Type [type]
    deconstruct * [pos_size_annotation] ED
    	'@ 'CONST Pos [number] Size [number]
    	
    replace [repeat annotation_item]
    	Annots [repeat annotation_item]
    by
        % size of structure (if constant) is position of last field + size of last field
    	'@ 'CONST '0 Pos [+ Size]  Annots
end function

function promoteIfVar Fields [list struct_element]
    % get last field - only matches last since no Rest
    deconstruct * [list struct_element] Fields
        ED [element_decl] Type [type]
    deconstruct * [pos_size_annotation] ED
    	'@ 'VAR _ [opt number]
    replace [repeat annotation_item]
    	Annots [repeat annotation_item]
    by
    	'@ 'VAR Annots
end function

rule updateSizeTypeDecision P [program]
    replace $ [type_decision_definition]
	'[ Long [id] '^ Short [id] '] Annots [repeat annotation_item] '::= TypeDec [type_decision]
	SCLAadd [opt scl_additions]  

    % If we have marked this one at the top level, it is completed
    deconstruct not * [pos_size_annotation] Annots
    	_ [pos_size_annotation]

    construct NewAnnots [repeat annotation_item]
    	Annots [addVarIfImport TypeDec]
	       [checkAllTDSizes Short P TypeDec]

    by
	'[ Long '^ Short '] NewAnnots '::= TypeDec
	SCLAadd
end rule

function addVarIfImport TypeDec [type_decision]
    deconstruct * [type_reference] TypeDec
    	ID [id] Dot [dotID]
    replace [repeat annotation_item]
    	Annots [repeat annotation_item]
    by
    	'@ 'VAR Annots
end function

function checkAllTDSizes ShortName [id] P [program] TypeDec [type_decision]
    % no imports
    deconstruct not * [type_reference] TypeDec
    	ID [id] Dot [dotID]
    
    construct TypeRefs [repeat type_reference]
    	_ [^ TypeDec]

   construct NumRefs [number]
   	_ [length TypeRefs]
	
    construct Sizes [repeat number]
        _ [addTypeSizeIfKnown P each TypeRefs]
	  %[debugCheckSizeAgainsTyeRefs ShortName NumRefs]

    construct NumSizes [number]
        _ [length Sizes]

     where NumSizes [= NumRefs]

     construct UniqueSizes [repeat number]
     	Sizes [removeDuplicates]
	
    replace [repeat annotation_item]
    	Annots [repeat annotation_item]
    by
    	Annots 
	    [addSizeAnnotationIfOne UniqueSizes]
	    [addSizeAnnotationIfZero UniqueSizes]
	    [addVarAnnotationIfMore UniqueSizes]
end function

function addTypeSizeIfKnown P [program] aTypeRef [type_reference]
   deconstruct aTypeRef
   	TypeName [id]
   deconstruct * [type_decl] P
   	'[ TypeName '^ _ [id] '] Annots [repeat annotation_item]
   deconstruct * [pos_size_annotation] Annots
       PosSize [pos_size_annotation]
   replace [repeat number]
   	L [repeat number]
   by
	L [addSizeIfConst PosSize]
	  [addZeroIfVar PosSize]
end  function

function addSizeIfConst PosSize [pos_size_annotation]
   deconstruct PosSize
      '@ 'CONST _ [number] Size [number]
   replace [repeat number]
   	L [repeat number]
   by
	Size L
end function

function addZeroIfVar PosSize [pos_size_annotation]
   deconstruct PosSize
      '@ 'VAR
   replace [repeat number]
   	L [repeat number]
   by
	'0 L
end function

function debugCheckSizeAgainsTyeRefs Short [id] NumRefs [number]
    match [repeat number]
    	NList [repeat number]
    construct NumNums [number]
    	_ [length NList]
    where not
    	NumNums [= NumRefs]
    construct message [stringlit]
    	_ [+ '"Type decision "]
	  [+ Short]
	  [+ '" does not yet have all types known ("]
	  [+ NumRefs]
	  [+ '","]
	  [+ NumNums]
	  [+ '")"]
	  [print]
end function

function removeDuplicates
    replace [repeat number]
       First [number] Rest [repeat number]
    by
       First
       Rest [removeNumber First]
            [removeDuplicates]       
end function

rule removeNumber First [number]
    replace [repeat number]
       First Rest [repeat number]
    by
       Rest
end rule	

function addSizeAnnotationIfOne UniqueSizes [repeat number]
   deconstruct UniqueSizes
   	OneNum [number]
   where not
   	OneNum [= 0]
   replace [repeat annotation_item]
   	Annots [repeat annotation_item]
   by
   	'@ 'CONST '0 OneNum Annots
end function

function addSizeAnnotationIfZero UniqueSizes [repeat number]
   deconstruct UniqueSizes
   	'0
   replace [repeat annotation_item]
   	Annots [repeat annotation_item]
   by
   	'@ 'VAR Annots
end function

function addVarAnnotationIfMore UniqueSizes [repeat number]
   deconstruct UniqueSizes
   	OneNum [number] TwoNum [number] Rest [repeat number]
   replace [repeat annotation_item]
   	Annots [repeat annotation_item]
   by
   	'@ 'VAR Annots
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 4, Turn back constrraints into LLK annotations on the type_decl
% for structured types
%
%   e.g. [X_M ^ X] @VAR ::= SEQUENCE {
%           ...
%        }
%        <transfer>
%           Back ={ firstField == 3 }
%           Back ={ thridField == 3  || thridField == 4 }
%        </transfer>
% where first field has length 1, thrid field is at position 9 and length 2
% becomes
%   e.g. [X_M ^ X] @ LL 0 1 3 @ LL 9 2 3,4  @VAR ::= SEQUENCE {
% var fields are not coppied.
%
% Assumptions. Conjunctions are written as separate Back constraints
% If a disjunction uses different variables, then not usable for LLK
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% need a new copy of type rules with annotations
function annotateStructRulesNewRules
   replace [program]
      P [program]
   construct TypeRules [repeat type_rule_definition]
      _ [^ P]
   by
      P [annotateStructRules  TypeRules]
end function 

rule annotateStructRules TypeRules [repeat type_rule_definition]
    replace $ [type_rule_definition]
	'[ UniqueID [id] '^ TypeName [id] '] Annots [repeat annotation_item] '::= 'SEQUENCE OptSize [opt size_constraint] '{
	    Fields [list struct_element] 
	    OptComma [opt ',]
	'} Encoding [opt encoding_grammar_indicator]
	'<transfer>
	    TransStmts [repeat transfer_statement]
	'</transfer>
	ConstBlock [opt constraints_block]
    by
	'[ UniqueID '^ TypeName '] Annots [convertBackToAnnotation Fields TypeRules each TransStmts]
		'::= 'SEQUENCE OptSize  '{
	    Fields 
	    OptComma
	'} Encoding
	'<transfer>
	    TransStmts
	'</transfer>
	ConstBlock
end rule

% four cases to find
% single variable == expression
% single variable.variable == expression
% single variable == expression || single variable == expression -> where they are the same variable
% single variable.variable == expression || single variable.variable == expression -> where they are the same variable
% divide into two major cases, one with OR, one without or., then when calculating offset and size,
% check for dot

function convertBackToAnnotation Fields [list struct_element] TypeRules [repeat type_rule_definition] aTransStmt [transfer_statement]
    deconstruct aTransStmt
    	Back { Expn [or_expression]}
    replace [repeat annotation_item]
	Annots [repeat annotation_item]
    by
    	Annots
	  [doSingleExpression Fields TypeRules Expn]
	  [doMultipleExpression Fields TypeRules Expn]
end function

% TODO
% Should be  [relational_expression] and check for a constant value.
% should also check that the value fits in the size of the type reference.
function doSingleExpression Fields [list struct_element] TypeRules[repeat type_rule_definition] Expn [or_expression]
    deconstruct Expn
    	RefElement [referenced_element] == Lit [literal_value]
 
    % get numeric value
    construct Value [list number]
       _ [addIfNumber Lit]
         %[convertIfHex Lit]
         [addIfCharlit Lit]


    replace [repeat annotation_item]
	Annots [repeat annotation_item]

    % get pos and size from RefElement
    construct LLKAnnots [repeat annotation_item]
        Annots
	  [getPosAndSizeDirect Fields RefElement Value]
  	  [getPosAndSizeInDirect Fields RefElement Value TypeRules]

    by
    	LLKAnnots
end function

% more than one or expression. 
% all have to have the same reference element on the LHS of the comparison to ber used for LLK optimization
% TODO
% Should be  [relational_expression] and check for a constant value.
% should also check that the value fits in the size of the type reference.

function doMultipleExpression Fields [list struct_element] TypeRules[repeat type_rule_definition] Expn [or_expression]
    deconstruct Expn
    	RefElement [referenced_element] == Lit [literal_value] || RefElement == Lit2 [literal_value] Rest [repeat or_and_expression]

    % check all of the Remaining and_or_expression are the same shape and use the same RefrenceElement
    where all 
    	RefElement [matchFormandLHS each Rest]

    % extract all of the Lits
    construct Lits [repeat literal_value]
        _ [. Lit]
	  [. Lit2]
	  [addRestLLKBacks each Rest]


 
    % get numeric value
    construct Value [list number]
       _ [addIfNumber each Lits]
         %[convertIfHex Lit]
         [addIfCharlit each Lits]


    replace [repeat annotation_item]
	Annots [repeat annotation_item]

    % get pos and size from RefElement
    construct LLKAnnots [repeat annotation_item]
        Annots
	  [getPosAndSizeDirect Fields RefElement Value]
  	  [getPosAndSizeInDirect Fields RefElement Value TypeRules]

    by
    	LLKAnnots
end function

function addRestLLKBacks anExpn [or_and_expression]
    deconstruct anExpn
	|| RefElement [referenced_element] == Lit [literal_value]
   replace [repeat literal_value]
   	List [repeat literal_value]
   by
   	List [. Lit]
end function

function matchFormandLHS anExpn [or_and_expression]
    match [referenced_element]
    	RefElement [referenced_element]
    deconstruct anExpn
	|| RefElement == Lit [literal_value]
end function

function addIfNumber Lit[literal_value]
   deconstruct Lit
   	N [number]
   replace [list number]
   	List [list number]
    by
    	N, List
end function

function addIfCharlit Lit[literal_value]
   deconstruct Lit
   	Val [charlit]
   construct N [number]
      _ [convertCharlitToNumber Val]
   replace [list number]
   	List [list number]
    by
    	N, List
end function

function convertCharlitToNumber Val [charlit]
    replace [number]
        _ [number]
    construct SLen [number]
        _ [# Val] [+ 1]   % Length of the [charlit] increased by 1
    construct Number [number]
       _ [addEachCharAsNumber Val SLen '1]
   by
      Number
end function

function addEachCharAsNumber Val [charlit] Slen [number] i [number]
    where
       i [< Slen]
    construct E [number]
       i [+ 1]
    construct C [charlit]
        Val [: i i]
    construct LetterVal [number]
          _ [doLookup C]
    %construct Msg [stringlit]
    	%_ [+ '"Converting "]
	  %[+ C]
	  %[+ '" to "]
	  %[+ LetterVal]
	  %[print]
    replace [number]
        N [number]
    by
        N [* '256] [+ LetterVal]  %[putp '"The number is now %"]
	[addEachCharAsNumber Val Slen E]
end function

define charIntPair
  [charlit] [number]
end define

function doLookup C[charlit]
    construct Tbl [repeat charIntPair]
        ''R' '82 ''T' '84 ''P' '80 ''S' '83 ''X' '88
    replace [number]
        _ [number]
    deconstruct * [charIntPair] Tbl
        C N [number]
    by
        N
end function

function getPosAndSizeDirect Fields [list struct_element] RefElement [referenced_element] Value[list number]
    deconstruct RefElement
    	'[ UniqueName [id] '^ _ [id] ']
 
    deconstruct * [element_decl] Fields
    	'[ UniqueName '^ _ [id] '] ElementAnnots [repeat annotation_item]

    deconstruct * [pos_size_annotation] ElementAnnots
       '@ 'CONST Pos [number] Size [number]
	
    replace [repeat annotation_item]
	Annots [repeat annotation_item]
    by
    	@LL Pos Size Value Annots
end function

% TODO  write the chain rule to have  more than one dot.
% also assumes that a . refers to a struct type
function getPosAndSizeInDirect Fields [list struct_element] RefElement [referenced_element] Value[list number] TypeRules [repeat type_rule_definition]
    deconstruct RefElement
    	'[ UniqueName [id] . SubUnique [id] %DtsRest [repeat dotReference]
	    '^ _ [referenced_element] ']

    % find type
    deconstruct * [struct_element] Fields
    	'[ UniqueName '^ _ [id] '] ElementAnnots [repeat annotation_item] TypeName [id] _[opt size_constraint] _ [repeat type_attribute]

    % only matters if element is constant
    deconstruct * [pos_size_annotation] ElementAnnots
       '@ 'CONST ElementPos [number] Size [number]

% Thes type rules don't have the annotations!!
    deconstruct * [type_rule_definition] TypeRules
	'[ TypeName  '^ _ [id] '] TypeAnnots [repeat annotation_item] '::= 'SEQUENCE _ [opt size_constraint] '{
	    TypeFields [list struct_element] 
	    _ [opt ',]
	'} _ [opt scl_additions]

    deconstruct * [struct_element] TypeFields
    	'[ SubUnique '^ _ [id] '] TypeElementAnnots [repeat annotation_item] T [type]

    % only matters if element is constant
    deconstruct * [pos_size_annotation] TypeElementAnnots
       '@ 'CONST TypeElementPos [number] TypeSize [number]
	
    replace [repeat annotation_item]
	Annots [repeat annotation_item]
    by
    	@LL ElementPos [+ TypeElementPos] TypeSize Value Annots
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 5, Copy annotations to uses in Type Decisions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fixTypeDecisions
    replace [program]
  	P [program]
    construct TypeRules [repeat type_rule_definition]
	_ [^ P]
    by
    	P [fixEachTypeDecision TypeRules]
end function

rule fixEachTypeDecision TypeRules [repeat type_rule_definition]
    replace $ [type_decision_definition]
	 '[ UniqueID [id] '^ Short [id] '] Annot [annotation] '::= TypeDec [type_decision] SCLAdd [opt scl_additions]
    construct TypeDec2 [type_decision]
    	TypeDec [annotateEachReference TypeRules]
 
    construct SCLAdd2 [opt scl_additions]
    	SCLAdd [buildLLKBlock Short TypeDec2]
    by
	 '[ UniqueID '^ Short '] Annot '::= TypeDec2 SCLAdd2
end rule

rule annotateEachReference TypeRules [repeat type_rule_definition]
    replace $ [type_reference]
       Name [id] Annot [repeat annotation_item]
    deconstruct * [type_decl] TypeRules
       '[ Name '^ _ [id] '] Annots [repeat annotation_item]
    construct LLK [repeat llk_annotation]
        _ [^ Annots]
	  [sortLLKAnnotation] 
    construct LLKA [repeat annotation_item]
   	_ [reparse LLK]
    by
       Name LLKA [. Annot]
end rule

% only ever about 3 or 4 of these, so a simple bubble sort
% will do. Sort by posisiont
rule sortLLKAnnotation
    replace [repeat llk_annotation]
        @ LL Pos1 [number] Size1 [number] Vals1 [list number]
        @ LL Pos2 [number] Size2 [number] Vals2 [list number]
	Rest [repeat llk_annotation]
    where
    	Pos1 [> Pos2]
    by
        @ LL Pos2 Size2 Vals2
        @ LL Pos1 Size1 Vals1
	Rest
end rule

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 6, Group type decision by offset and check for unique values
%  and create LLK grouping block for code generation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% here we need to add an llk lookeadhead block, add to annot.ovr
% collect the same offset and see if they are the same size.
% if sizes are different then it is not optimizable, and the defualt try fail is used.
% If one is missing then it goes in the missing block, which is tried if non of the
% the others succeed. If more than one match, then they end up together to try again
% with anther offset.
%
% Example 1
% A @ LL 0 2 1 | B @ LL 0 1 2 ....
%   - not optimizabl because don't know how many bytes to read.  Technically could build somthing but woul be more complex
%     than just calling parseA and parseB because they will fail right away.
% Example 2
% A @ LL 0 1 1 | B @ LL 0 1 2 | C | D @ LL 0 1 3 | E @ LL 0 1 3
%  - C had no lookahead, D and E have same lookahead
% - read 1 byte at ofest 0. If 1 then parseA, if 2 then parseB, if 3, firt call parseD and if it
%   fails call parse E. If all fail, then call parseC, if it fails, reutrn false.
% <lookahead>
%    { 0 1		-- offset and size
%      1 @ A
%      2 @ B
%      3 @ D,E		-- order here must be same order as in Type decision
%      * @ C
%    }
% </lookahead>
% A @ LL 0 1 1 | B @ LL 0 1 2 | C | D @ LL 0 1 3 | E @ LL 0 1 3 @ 4 2 25 | F @ LL 0 1 3 @ 4 3 27 | G @ LL 0 3 @ 4 2 27
% Example 3
%    { 0 1		-- offset and size
%      1 @ A
%      2 @ B
%      3 @ D,E,F,G	- F has different size at offset 4 than E and G so not optimizable for that level.
%      * @ C
% Example 4
% A @ LL 0 1 1 | B @ LL 0 1 2 | C | D @ LL 0 1 3 | E @ LL 0 1 3 @ 4 2 25 | F @ LL 0 1 3 @ 4 2 27 | G @ LL 0 3 @ 4 2 27
%    { 0 1		-- offset and size
%      1 @ A		-- value and TypeName
%      2 @ B
%      3 @ { 4 2	-- offset and size
%            25 @ E
%            27 @ F,G	-- order here must be same order as in Type decision
%	      * @ D
%          }
%      * @ C
%    }
%    }
%
% Strategy - build first level based on first offset (check same size), then add 
%	  each value to the table and list ids if more than one e.g. First Output of Example 3 is 
%    { 0 1		-- offset and size
%      1 @ A		-- value and TypeName
%      2 @ B
%      3 @ D, E @ 4 2 5, F @ 4 2 27, G @ 4 2 27
%      * @ C
%    }
% note that the * entry may actually have offset values, just not one for the first offset value.
% - each entry that has more than one type name is then examined for a further offset (including the * entry)
% if there is a futher offset for one or more of the types in the list, then for the smallest remainig offset
% redo the list.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO - we have an opt of an opt... this should be fixed.
% change main grammr to be not scl_additions (i.e. not opt)
% and the rules that depend on it.
function buildLLKBlock Short [id] TypeDec2 [type_decision]
    % at least on llk_annotation present
    deconstruct * [llk_annotation] TypeDec2
    	_ [llk_annotation]

    replace * [opt optimizable_block]
	_ [opt optimizable_block]
	
    construct TypeRefs [repeat type_reference]
	_ [^  TypeDec2]


    construct OBlock [opt lookahead_block]
	_ [buildNestedBlock Short TypeRefs]
    deconstruct OBlock
    	Block [lookahead_block]
    by
	<lookahead>
	    Block
	</lookahead>
end function


function buildNestedBlock Short [id] TypeRefs [repeat type_reference]
    % Findthe minimum offset in the typerefs.
    % start by finding the first offset in the references
    deconstruct * [llk_annotation] TypeRefs
    	@ LL Offset [number] Size [number] Vals [list number]

    % See if any are smaller
    construct MinOffset [number]
	Offset [findMinOffset each TypeRefs]

    %construct Msg [stringlit]
    	%_ [+ '"Min offset for type decision "]
	  %[+ Short]
	  %[+ '" is "]
	  %[+ MinOffset]
	  %[print]

    % check all offsets at the min Offset have the same size
    % as the Min Offset

    deconstruct * [llk_annotation] TypeRefs
       @ LL MinOffset SizeOfMin [number] MinVals [list number]

    % TODO should create a rule to print a message if they don't all have the same size
    %construct Msg2 [stringlit]
    	%_ [+ '"At leat one min offset for type decision "]
	  %[+ Short]
	  %[+ '" is of size "]
	  %[+ SizeOfMin]
	  %[print]

    % get all the typerefs with a given offset
    construct TypeRefsWithMinOffset [repeat type_reference]
	_ [addIfOffsetIs MinOffset each TypeRefs]
	  %[putp "Typerefs with offset are %"]

    where all
    	SizeOfMin [checkSizeIfOffset MinOffset each TypeRefsWithMinOffset]

    %construct Msg3 [stringlit]
    	%_ [+ '"All min offsets for type decision "]
	  %[+ Short]
	  %[+ '" are of size "]
	  %[+ SizeOfMin]
	  %[print]


    %construct TypeRefsWithoutMinOffset [repeat type_reference]
	%_ [addIfOffsetIsNot MinOffset each TypeRefs]
	  %[putp "Typrefs without offset are %"]

    construct Cases [repeat switch_case]
       _ [addCase MinOffset each TypeRefsWithMinOffset]
         [sortCasesByValue]
         [addDefaultCase MinOffset each TypeRefs]
	 %[message '"The cases are:"]
	 [optimizeSubCases Short]
	 %[print]

    replace [opt lookahead_block]
	LB [opt lookahead_block]
    by
	'{ MinOffset SizeOfMin
	    Cases
	'}
end function

function findMinOffset aTypeRef [type_reference]
    deconstruct * [llk_annotation] aTypeRef
    	'@ LL Offset [number] Size [number] Vals [list number]
    replace [number]
   	CurMinOffset [number]
    where
    	Offset [< CurMinOffset]
    by
 	Offset
end function

function checkSizeIfOffset MinOffset [number] aTypeRef [type_reference]
    deconstruct * [llk_annotation] aTypeRef
    	'@ LL MinOffset  Size [number] Vals [list number]
     
    match [number]
   	Size
end function

function addIfOffsetIs MinOffset [number] aTypeRef [type_reference]
    deconstruct * [llk_annotation] aTypeRef
    	'@ LL MinOffset _ [number] Values [list number]
    replace [repeat type_reference]
	TypeRefsWithMinOffset [repeat type_reference]
    by
    	TypeRefsWithMinOffset [. aTypeRef]
end function

function addIfOffsetIsNot MinOffset [number] aTypeRef [type_reference]
    deconstruct not * [llk_annotation] aTypeRef
    	'@ LL MinOffset _ [number] Values [list number]
    replace [repeat type_reference]
	TypeRefsWithoutMinOffset [repeat type_reference]
    by
    	TypeRefsWithoutMinOffset [. aTypeRef]
end function

% important that the order of the type ids must be in the same order as the spec
function addCase MinOffset [number] aTypeRef [type_reference]
    % no LLK optimizaiton of .ids
    deconstruct aTypeRef
    	Name [id] Annots [annotation]
    deconstruct * [llk_annotation] Annots
    	'@ LL MinOffset _ [number] Values [list number]
    replace [repeat switch_case]
	Cases [repeat switch_case]
    by
        % add if value there goes first to prevent duplicates
    	Cases
	    [addIfValueThere MinOffset aTypeRef each Values]
	    [addIfValueNotThere MinOffset aTypeRef each Values]
end function

function addIfValueThere Offset [number] Name [type_reference] aValue [number]
    replace * [switch_case]
        aValue '@ Refs [list type_reference]
    construct Name2 [type_reference]
    	Name [removeLLKAnnotation Offset]
    by
        aValue '@ Refs [, Name2]
end function 
	
function addIfValueNotThere Offset [number] Name [type_reference] aValue [number]
    replace [repeat switch_case]
        Cases [repeat switch_case]
    deconstruct  not * [switch_case] Cases
        aValue '@ Refs [list type_reference]
    by
        aValue '@ Name [removeLLKAnnotation Offset]
	Cases
end function

function removeLLKAnnotation Offset [number]
    replace * [repeat annotation_item]
    	'@ LL Offset _ [number] Values [list number]
	Rest  [repeat annotation_item]
    by
    	Rest
end function

function addDefaultCase MinOffset [number] aTypeRef [type_reference]
    % no LLK optimizaiton of .ids
    deconstruct aTypeRef
    	Name [id] Annots [annotation]
    % does not have MinOffset as a lookahead
    deconstruct not * [llk_annotation] Annots
    	'@ LL MinOffset _ [number] Values [list number]
    replace [repeat switch_case]
	Cases [repeat switch_case]
    by
        % add if value there goes first to prevent duplicates
    	Cases
	    [addIfDefaultThere aTypeRef]
	    [addIfDefaultNotThere aTypeRef]
end function

function addIfDefaultNotThere aTypeRef [type_reference]
    replace [repeat switch_case]
        Cases [repeat switch_case]

    deconstruct not * [def_case] Cases
    	_ [def_case]

    construct DefCase [switch_case]
        '* '@ aTypeRef

    by
	Cases [. DefCase]
end function

function addIfDefaultThere aTypeRef [type_reference]
    replace * [def_case]
        '* '@ Refs [list type_reference]
    by
        '* '@ Refs [, aTypeRef]
end function

function addDefaultCaseNotThere MinOffset [number] aTypeRef [type_reference]
    % no LLK optimizaiton of .ids
    deconstruct aTypeRef
    	Name [id] Annots [annotation]
    % does not have MinOffset as a lookahead
    deconstruct not * [llk_annotation] Annots
    	'@ LL MinOffset _ [number] Values [list number]
    replace * [def_case]
        '* '@ Refs [list type_reference]
    by
        '* '@ Refs [, aTypeRef]
end function

rule sortCasesByValue
    replace [repeat switch_case]
	N1 [number] '@ List1 [list type_reference]
	N2 [number] '@ List2 [list type_reference]
	Rest [repeat switch_case]
    where
    	N2 [< N1]
    by
	N2  '@ List2
	N1  '@ List1
	Rest
end rule

rule optimizeSubCases Short [id]

    replace $ [refs_or_sub_block]
	TypeRefs [list type_reference]

    % Findthe minimum offset in the typerefs.
    % start by finding the first offset in the references
    deconstruct * [llk_annotation] TypeRefs
    	@ LL Offset [number] Size [number] Vals [list number]

    % See if any are smaller
    construct MinOffset [number]
	Offset [findMinOffset each TypeRefs]

    %construct Msg [stringlit]
    	%_ [+ '"Min offset for nested type decision case "]
	  %[+ Short]
	  %[+ '" is "]
	  %[+ MinOffset]
	  %[print]

    % check all offsets at the min Offset have the same size
    % as the Min Offset

    deconstruct * [llk_annotation] TypeRefs
       @ LL MinOffset SizeOfMin [number] MinVals [list number]

    % TODO should create a rule to print a message if they don't all have the same size
    %construct Msg2 [stringlit]
    	%_ [+ '"At leat one min offset for nested type decision case "]
	  %[+ Short]
	  %[+ '" is of size "]
	  %[+ SizeOfMin]
	  %[print]

    % get all the typerefs with a given offset
    construct TypeRefsWithMinOffset [repeat type_reference]
	_ [addIfOffsetIs MinOffset each TypeRefs]
	  %[putp "Typerefs with offset are %"]

    % this has to only apply those with the offset.
    where all
    	SizeOfMin [checkSizeIfOffset MinOffset each TypeRefsWithMinOffset]

    %construct Msg3 [stringlit]
    	%_ [+ '"All min offsets for nested type decision case "]
	  %[+ Short]
	  %[+ '" are of size "]
	  %[+ SizeOfMin]
	  %[print]

    construct Cases [repeat switch_case]
       _ [addCase MinOffset each TypeRefsWithMinOffset]
         [sortCasesByValue]
         [addDefaultCase MinOffset each TypeRefs]
	 %[message '"The cases are:"]
	 [optimizeSubCases Short]
	 %[print]

    by
	'{ MinOffset SizeOfMin
	    Cases
	'}
end rule

