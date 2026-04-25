
//
#include <string>
#include <cctype>
#include "SCL.sst.h"
#include "SCLScanner.h"

extern std::string tokenNames[];

struct keyPair{
    std::string keyword;
    InputToken token;
};

const keyPair keywords[]{
    {"BOOLEAN", tBOOLEAN},
    {"BEGIN", tBEGIN},
    {"BIG", tBIG},
    {"INTEGER",tINTEGER},
    {"END",tEND},
    {"BIT",tBIT},
    {"DEFINITIONS",tDEFINITIONS},
    {"STRING",tSTRING},
    {"EXPLICIT",tEXPLICIT},
    {"OCTET",tOCTET},
    {"NULL",tNULL},
    {"EXPORTS",tEXPORTS},
    {"SEQUENCE",tSEQUENCE},
    {"IMPORTS",tIMPORTS},
    {"OF",tOF},
    {"REAL",tREAL},
    {"SET",tSET},
    {"INCLUDES",tINCLUDES},
    {"IMPLICIT",tIMPLICIT},
    {"ANY",tANY},
    {"SIZE",tSIZE},
    {"EXTERNAL",tEXTERNAL},
    {"FROM",tFROM},
    {"OBJECT",tOBJECT},
    {"WITH",tWITH},
    {"IDENTIFIER",tIDENTIFIER},
    {"COMPONENT",tCOMPONENT},
    {"OPTIONAL",tOPTIONAL},
    {"PRESENT",tPRESENT},
    {"DEFAULT",tDEFAULT},
    {"ABSENT",tABSENT},
    {"COMPONENTS",tCOMPONENTS},
    {"DEFINED",tDEFINED},
    {"UNIVERSAL",tUNIVERSAL},
    {"BY",tBY},
    {"APPLICATION",tAPPLICATION},
    {"PLUS-INFINITY",tPLUSINFINITY},
    {"PRIVATE",tPRIVATE},
    {"MINUS-INFINITY",tMINUSINFINITY},
    {"TRUE",tTRUE},
    {"TAGS",tTAGS},
    {"FALSE",tFALSE},
    {"AUTOMATIC",tAUTOMATIC},
    {"EXTENSIBILITY",tEXTENSIBILITY},
    {"IMPLIED",tIMPLIED},
    {"ENCODED",tENCODED},
    {"CONTAINING",tCONTAINING},
    {"VisibleString",tVisibleString},
    {"UTCTime",tUTCTime},
    {"STRING",tSTRING},
    {"GeneralizedTime",tGeneralizedTime},
    {"IA5String",tIAString},
    {"INCLUDE",tINCLUDE},
    {"",tEndOfFile}
};

SCLScanner::SCLScanner(){
    for(int i = 0; keywords[i].token != tEndOfFile; i++){
        keys[keywords[i].keyword] = keywords[i].token;
    }
};

InputToken SCLScanner::nextToken(){
    // check lookahead
    if (c == -1){
        if (!infp->get(c)) return tEndOfFile;
    }
    
    // skip spaces
    while(isspace(c)){
        if (!infp->get(c)) return tEndOfFile;
    }
    
    switch (c){
        case ':':
            // must be ::=
            if (!infp->get(c)) return tEndOfFile;
            if (c != ':'){
                std::cerr << ": is not valid by itself" << std::endl;
                return tIllegal;
            }
            if (!infp->get(c)) return tEndOfFile;
            if (c != '='){
                std::cerr << ":= is not valid by itself" << std::endl;
                return tIllegal;
            }
            c = -1; // no current lookahead character
            return (tIS);
        case '=':
            // could be assign or equals
            if (!infp->get(c)) return tEndOfFile;
            if (c == '='){
                c = -1;
                return (tASSIGN);
            }
            return tEQ;
        case '!':
            // must be !=
            if (!infp->get(c)) return tEndOfFile;
            if (c != '='){
                std::cerr << "! is not valid by itself" << std::endl;
                return tIllegal;
            }
            c = -1;
            return tNEQ;
        
        // < << </ <= >> >=  | || & &&

        default:
            if (isalpha(c)){
                ident = "";
                while(isalpha(c)|| c == '_' || c == '-'){
                    ident.push_back(c);
                    if (!infp->get(c)) return tIdent;
                }
            }
            std::cout << "hi" << std::endl;
    }
    
    return tEndOfFile;
}

const std::string SCLScanner::tokenToString(InputToken t){
    if (t == tSyntaxError) return "Syntax Error";
    if (t > tIllegal) return  "Unkown Input Token";
    return tokenNames[t];
}
