include "ASNOne.Grm"

function main
    replace [program]
        P [program]
    by
        P %[determinEnumValues]
           [verifyChoiceTypeDecisions]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Determin enum Values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. explicate values for enums
%%. ENUM { A, B, C} becomes ENUM{A(0),B(1),C(2)}
%%. ENUM { A, B(3), C} becomes ENUM{A(0),B(3),C(4)}
%% etc.
%%
%% 

%rule determinEnumValues
%   replace 
%.  by
%end rule


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Check Choice rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% 1. check that each type decision that contains a choice 
%%   value has all alteratives labeled.
%% 2. Check that each use of the type decision is guarded
%%    by a forward choice constraint (TODO)

function verifyChoiceTypeDecisions
    replace [program]
        P [program]
    export ListOfChoiceDecisions [repeat id]
        _ % empty
    by
        P [checkChoiceTags]
          %[checkChoiceTDUses]
end function

rule checkChoiceTags
    replace $ [type_decision_definition]
       '[ UniqueTypeName [id] '^ ShortTypeName [id] '] '::= TD [type_decision] SCLA [opt scl_additions]
    % does the type decision contain a semantic choice?
    deconstruct * [type_choice_option] TD
        TCO [type_choice_option]
    by
       '[ UniqueTypeName '^ UniqueTypeName ']   '::= TD [errorIfNoChoiceOption ShortTypeName]  SCLA 
end rule

function errorIfNoChoiceOption TypeName [id]
    replace * [opt type_choice_option]
        % empty
    construct ErrorMsg [stringlit]
        _ [+ TypeName]
          [+ ": both has and doen't have semantic options, must be consistent"]
          [print]
    by
        % empty
end function