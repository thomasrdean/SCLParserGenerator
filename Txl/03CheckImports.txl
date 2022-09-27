%%+
%% Program: 03CheckImports.txl
%%
%%  This program checks that the imports in one SCL module
%%  match the exports in the module
%%-

include "ASNOne.Grm"


function main
    replace [program]
	P [program]
    by
	P [checkImports]
end function

% one pass rule to visit the imports of each module
% pass the module name into the rule that checks the import list
rule checkImports
    skipping [module_definition]
    replace $ [module_definition]
	ModuleName [id] 'DEFINITIONS '::= 'BEGIN
	    Exports [opt export_block]
	    'IMPORTS List [list import_list+] ';
	    Body [repeat rule_definition]
	'END
    by
	ModuleName 'DEFINITIONS '::= 'BEGIN 
	    Exports
	    'IMPORTS List [checkImportList ModuleName] ';
	    Body
	'END
end rule


% read the list of names (in unique form)
% exported by the module. The file has the 
% form moduleName.exports and is in the INTERMEDIATE directory
rule checkImportList ModuleName [id]
    replace $ [import_list]
	    List [list decl] 'FROM ImportModuleName [id]
    construct File [stringlit]
	    _ [+ "INTERMEDIATE/"] [+ ImportModuleName] [+ ".exports"]
    construct ExportedNames [repeat id]	
	    _ [read File]
    by
	    List  [checkEachImport ModuleName ImportModuleName ExportedNames] 'FROM ImportModuleName
end rule

% visit each name in the imports list.
% check that the name is contained in the list names
% read from the exprts file.
rule checkEachImport ModuleName [id] ImportModuleName [id] ImportedNames [repeat id]
    replace $ [decl]
	'[ UniqueName [id] ^ ShortName [id] ']

    deconstruct not * [id] ImportedNames
	UniqueName

    construct Ms [stringlit]
	_ [+ "Name \""]
	  [+ ShortName]
	  [+ "\" in module \""]
	  [+ ModuleName]
	  [+ "\" is not exported from module \""]
	  [+ ImportModuleName]
	  [+ "\""]
	  [print]
    by
	'[ UniqueName ^ ShortName ']
end rule
