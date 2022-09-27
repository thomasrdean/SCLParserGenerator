% Callback Annotation
% Kyle Lavorato
% Queen's University, June 2017

% Copyright 2017 Thomas Dean

% Revision history:

% 2.1 REworking for new grammar, simiplifying	- T.D. April 2021
% 2.0 Release Version				- KPL	06 06 2018
%	  All known issues resolved
% 1.3 Type decision ^ Callback 		- KPL	06 20 2017
% 1.2 Addition of Callback Final	- KPL	06 19 2017
% 1.1 Documentation and Bug Fix		- KPL	06 16 2017
% 1.0 Initial revision 				- KPL	06 14 2017

% This program searches through a SCL5 file for any "Callback" in the transfer
% statement that can be optimized. A callback can be optimized if the final
% element in the definition SEQUENCE is a SET OF [TYPE].

% The input to the program is a SCL5 file named "protocol"_UID.scl5. The input
% file has been transformed from the base scl5 already through two TXL scripts
% in the TXL pipeline to ensure all naming is unique.

% The output of this program is a SCL5 file named 
% "protocol"_UID_callbackAnnotated.scl5. The output file has added annotations
% to any detected Callback's in the input file where optimization is possible


% Base grammar

include "ASNOne.Grm"

% Local grammar overrides

redefine callback_annotation
      ...
   | '# [id] [opt callback_annotation] % Intermediate form for this TXL script
end define

% Main rule followed by other rules in topological order

function main
	replace [program]
		P [program]

	% Global variable to hold any intermediate callbacks that indicate 
	% the type decision rule that the parent callback refers to
	construct CallbackSetOf [repeat callback_annotation]
		% empty
	export CallbackSetOf

	% Global variable to hold any intermediate callbacks that indicate
	% they need a callback with annotation placed in the specified definition
	construct PlaceCallback [repeat callback_annotation]
	export PlaceCallback
	
	% Extraction of all the rule definitions
	construct AllRules [repeat rule_definition]
		_ [^ P]

	by
		P [annotateInitialCallback AllRules]
		  [annotateTypeDecision]
		  [annotateUsedTypes]
		  [replaceCallbackFinal]
end function


% Step 1: Find all original callbacks in the scl5 specification; Annotate them
% if they are optimizable and populate the referenced intermediate form 
% in global: CallbackSetOf

rule annotateInitialCallback Rules [repeat rule_definition]
	replace $ [type_rule_definition]
		'[ UniqueStructureName [id] '^ ShortStructureName [id] '] '::= 'SEQUENCE OS [opt size_constraint] '{
			StructureElements [list struct_element] OptComma [opt ',]
		'} SclAdds [scl_additions]

        % rule contains a Callback annotation, but not a Final annotation.
	deconstruct * [transfer_statement] SclAdds 
		'Callback CallAnnot [opt callback_annotation]
	deconstruct not CallAnnot
		'Final

	% the finale element of the SEQUENCE must be a SET OF or SEQUENCE OF 
	% in order to be optimized
	deconstruct * [list struct_element] StructureElements
		'[ _ [id] '^ fieldName [id] '] SetOrSeq [set_or_seq_of_type] '('SIZE 'CONSTRAINED')

	% find the type that the SET OF or SEQUENCE OF is applied to
	% note this is the unique name from rename references.
	deconstruct * [id] SetOrSeq
		UniqueFieldTypeName [id]

	% the type refered to in the last field must be a type decision
	deconstruct * [type_decision_definition] Rules
		'[ UniqueFieldTypeName '^ _ [id] '] '::= '( _ [type_reference] _ [repeat alternative_decision] ') _ [opt scl_additions]
		% In order for the callback to be valid for annotation the SET OF [FieldTypeName] must be a type desicion

	% Record the fact that we need to add a callback annotation to the type decision.
	% This takes the form of an intermediate annotation withc was added with the redefine.
	% It is stored in the global variable CallbackSetOf We are storing:
	% 1. the Unique Name of the Field
	% 2. the unique name of the structure
	% 3. the short name of the field
	import CallbackSetOf [repeat callback_annotation]
	export CallbackSetOf
		'# UniqueFieldTypeName UniqueStructureName fieldName
		CallbackSetOf

	% we add the unique type name of the type decision to the callback statement
	% in the type structure. This specifies....

	construct finalCallbackAnnotation [opt callback_annotation]
		'@ UniqueStructureName fieldName % The annotation that will be added to the original callback

	by
		'[ UniqueStructureName '^ ShortStructureName '] '::= 'SEQUENCE OS '{
			StructureElements OptComma
		'}  SclAdds [annotateCallbackStmt finalCallbackAnnotation]
end rule


function annotateCallbackStmt NewCallbackAnnotation [opt callback_annotation]
   replace * [transfer_statement]
   	'Callback OptCall [opt callback_annotation]
   by
   	'Callback NewCallbackAnnotation
end function

% Step 2: Add a callback annotation to the type decision rules that are the subject
% of the SET or SEQ of modifiers in Step 1. These are listed in the global varible CallbackSetOf
% Add each type in the type decision to the global varible PlaceCallback so that the type definitions
% for those types can be annotated.

% TODO - add error checking if the type decision is the result of more than one optimization.

rule annotateTypeDecision
    replace $ [type_decision_definition]
	'[ UniqTDName [id] '^ TDName [id] '] '::= '( TR [type_reference] RTR [repeat alternative_decision] ') SclAdd [opt scl_additions]

    import CallbackSetOf [repeat callback_annotation]

    % These were added by the first stage
    % the first element is the The TypeDecision Name, the rest is two ids that
    % are the long name of the structure that is being optimized an the
    % short name of the last field in the structure.
    deconstruct * [callback_annotation] CallbackSetOf
	'# UniqTDName CallAnnot [callback_annotation]

    construct TypeReferences [repeat type_reference]
	_ [^ RTR]
	  [. TR]

    % add the list of types in the type decision to PlaceCallback. The 
    % elements are
    % 1. the name of the type in the decision
    % 2. The name of the structure that is being optimized
    % 3. the name of the field in the structure that is being optimized.
    import PlaceCallback [repeat callback_annotation]
    export PlaceCallback
	PlaceCallback [addAnnotationEachTypeInTypeDec CallAnnot each TypeReferences]

    by
	'[ UniqTDName '^ TDName '] '::= '( TR RTR ')
	SclAdd
	    [addSCLIfMissing]		% fist one adds the SCL block if it was missing
	    [addTransferIfMissing]	% second one adds the TRansfer to the SCL if it was there
	    % add a callback annotation to the Type Decision
	    [annotateTypeDecisionTransfer UniqTDName CallAnnot]
end rule

% see comments at call.
function addAnnotationEachTypeInTypeDec CallAnnot [callback_annotation] TypeRef[type_reference]
    deconstruct * [id] TypeRef
    	TypeId[id]
    replace [repeat callback_annotation]
    	L [repeat callback_annotation]
    by
	'# TypeId CallAnnot
	L
end function

% need to add a callback annotation to the transfer block of a type definition.
% if there is no scl addition on the rule, add one and add an empty transfer block
function addSCLIfMissing
    replace [opt scl_additions]
    	% empy
    by
    	'<transfer>
    	'</transfer>
end function

% need to add a callback annotation to the transfer block of a type definition.
% if there is a scl addition on the rule but no transfer rules, add an empty transfer block
function addTransferIfMissing
    replace [opt scl_additions]
	GR [opt encoding_grammar_indicator] 
	% no transfer block
	CB [opt constraints_block] 
    by
	GR 
    	'<transfer>
    	'</transfer>
	CB
end function

% add the callback annotation to the transfer block of a type decision
function annotateTypeDecisionTransfer UniqueTDName [id] CallAnnot [callback_annotation]
    replace [opt scl_additions]
	GR [opt encoding_grammar_indicator] 
	'<transfer>
	    TS [repeat transfer_statement]
	'</transfer> 
	CB [opt constraints_block] 

    % ID1 is the 
    deconstruct CallAnnot
	optimizedStructure [id] fieldName [id]

    % TODO what if there is more than one?
    construct callback [transfer_statement]
	'Callback '^ optimizedStructure fieldName
    by
	GR
	'<transfer>
	    TS [. callback]
	'</transfer>
	CB
end function

% Check if the [id] matches the [id] in LONG
function matchCallbackLong LONG [id]
        match [id]
                LONG
end function


% Step 3: Types that are used in a type decsision that is the type
% of the last field of an optimized struture have to be annoated,
% as that is where the parser makes the callback from. They
% are lised in the PlaceCallback Global Variable.

% assumption - the type refered to in a type decision is not another type decision
% assumption - they are SEQUENCE of, that SET OF as a structure is not used.

rule annotateUsedTypes
    replace $ [type_rule_definition]
	'[ UniqUsedTypeName [id] '^ ShortUsedTypeName [id] '] '::= 'SEQUENCE OS [opt size_constraint] '{
	    Fields [list struct_element] OptComma [opt ',]
	'}
	SclAdditions [opt scl_additions]

    import PlaceCallback [repeat callback_annotation]

    deconstruct * [callback_annotation] PlaceCallback
    	'# UniqUsedTypeName CallAnnot [callback_annotation]

    construct newAdditions [opt scl_additions]
	SclAdditions 
	    [addSCLIfMissing]		% fist one adds the SCL block if it was missing
	    [addTransferIfMissing]	% second one adds the TRansfer to the SCL if it was there
	    [annotateUsedTypeTransfer UniqUsedTypeName CallAnnot]

	    %[checkForMinorMatchWithTransfer UniqUsedTypeName each PlaceCallback]
    by
	'[ UniqUsedTypeName '^ ShortUsedTypeName '] '::= 'SEQUENCE OS '{
	    Fields OptComma
	'}
	newAdditions
end rule

% diff from mprevious is no '^ in annotation
function annotateUsedTypeTransfer UniqueUsedTypeName [id] CallAnnot [callback_annotation]
    replace [opt scl_additions]
	GR [opt encoding_grammar_indicator] 
	'<transfer>
	    TS [repeat transfer_statement]
	'</transfer> 
	CB [opt constraints_block] 

    % ID1 is the 
    deconstruct CallAnnot
	optimizedStructure [id] fieldName [id]

    % TODO what if there is more than one?
    construct callback [transfer_statement]
	'Callback optimizedStructure fieldName
    by
	GR
	'<transfer>
	    TS [. callback]
	'</transfer>
	CB
end function


% Step 4: Find any callbacks that have been annotated as 'Final and remove
% the annotation as the remainder of the TXL pipeline expects them to have
% no annotation
rule replaceCallbackFinal
	replace $ [type_rule_definition]
		'[ UniqueName [id] '^ ShortName [id] '] '::= 'SEQUENCE OS [opt size_constraint] '{
			ELements [list struct_element] OC [opt ',]
		'} SclAdd [opt scl_additions]
	deconstruct * [transfer_statement] SclAdd
		'Callback 'Final
	construct finalCallbackAnnotation [opt callback_annotation]
		_ 	% Remove Final annotation from the callback
																% to the callback
	by
		'[ UniqueName '^ ShortName '] '::= 'SEQUENCE OS '{
			ELements OC
		'} SclAdd [annotateCallbackStmt finalCallbackAnnotation]
end rule
