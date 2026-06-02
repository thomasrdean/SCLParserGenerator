
//
#include <string>
#include <cctype>

#include "SCLScanner.h"

extern std::string tokenNames[];

struct keyPair{
    std::string keyword;
    SCLScanner::InputToken token;
};

const keyPair keywords[]{
    {"BOOLEAN", SCLScanner::tBOOLEAN},
    {"BEGIN", SCLScanner::tBEGIN},
    {"BIG", SCLScanner::tBIG},
    {"INTEGER",SCLScanner::tINTEGER},
    {"END",SCLScanner::tEND},
    {"BIT",SCLScanner::tBIT},
    {"DEFINITIONS",SCLScanner::tDEFINITIONS},
    {"STRING",SCLScanner::tSTRING},
    {"EXPLICIT",SCLScanner::tEXPLICIT},
    {"OCTET",SCLScanner::tOCTET},
    {"NULL",SCLScanner::tNULL},
    {"EXPORTS",SCLScanner::tEXPORTS},
    {"SEQUENCE",SCLScanner::tSEQUENCE},
    {"IMPORTS",SCLScanner::tIMPORTS},
    {"OF",SCLScanner::tOF},
    {"REAL",SCLScanner::tREAL},
    {"SET",SCLScanner::tSET},
    {"INCLUDES",SCLScanner::tINCLUDES},
    {"IMPLICIT",SCLScanner::tIMPLICIT},
    {"ANY",SCLScanner::tANY},
    {"SIZE",SCLScanner::tSIZE},
    {"EXTERNAL",SCLScanner::tEXTERNAL},
    {"FROM",SCLScanner::tFROM},
    {"OBJECT",SCLScanner::tOBJECT},
    {"WITH",SCLScanner::tWITH},
    {"IDENTIFIER",SCLScanner::tIDENTIFIER},
    {"COMPONENT",SCLScanner::tCOMPONENT},
    {"OPTIONAL",SCLScanner::tOPTIONAL},
    {"PRESENT",SCLScanner::tPRESENT},
    {"DEFAULT",SCLScanner::tDEFAULT},
    {"ABSENT",SCLScanner::tABSENT},
    {"COMPONENTS",SCLScanner::tCOMPONENTS},
    {"DEFINED",SCLScanner::tDEFINED},
    {"UNIVERSAL",SCLScanner::tUNIVERSAL},
    {"BY",SCLScanner::tBY},
    {"APPLICATION",SCLScanner::tAPPLICATION},
    {"PLUS-INFINITY",SCLScanner::tPLUSINFINITY},
    {"PRIVATE",SCLScanner::tPRIVATE},
    {"MINUS-INFINITY",SCLScanner::tMINUSINFINITY},
    {"TRUE",SCLScanner::tTRUE},
    {"TAGS",SCLScanner::tTAGS},
    {"FALSE",SCLScanner::tFALSE},
    {"AUTOMATIC",SCLScanner::tAUTOMATIC},
    {"EXTENSIBILITY",SCLScanner::tEXTENSIBILITY},
    {"IMPLIED",SCLScanner::tIMPLIED},
    {"ENCODED",SCLScanner::tENCODED},
    {"CONTAINING",SCLScanner::tCONTAINING},
    {"VisibleString",SCLScanner::tVisibleString},
    {"UTCTime",SCLScanner::tUTCTime},
    {"STRING",SCLScanner::tSTRING},
    {"GeneralizedTime",SCLScanner::tGeneralizedTime},
    {"IA5String",SCLScanner::tIAString},
    {"INCLUDE",SCLScanner::tINCLUDE},
    {"",SCLScanner::tEndOfFile}
};

SCLScanner::SCLScanner(){
    // load the keyword table.
    for(int i = 0; keywords[i].token != tEndOfFile; i++){
        keys[keywords[i].keyword] = keywords[i].token;
    }
}

bool SCLScanner::pushFile(std::string fname){
    std::ifstream *iFile = new std::ifstream(fname);

    if (! iFile->is_open()){
        return false;
    }
    
    infp.push(iFile);
    iFileName.push(fname);
    curLineNumberIndex++;
    lineNumber[curLineNumberIndex] = 0;
    
    return true;
}

// method SCLScanner::nextChar()
//
// this emulates the file class get but
// handles the case when we reach the end
// of an included file and have to start reading
// again from the file that included it.

bool SCLScanner::nextChar(char &c){
    while(!infp.empty()){
        if (!infp.top()->get(c)){
            infp.top()->close();
            infp.pop();
            curLineNumberIndex--;
            iFileName.pop();
        } else {
            return true;
        }
    }
    c = EOF;
    return false;
}

SCLScanner::curPosT SCLScanner::curPos(){
    return {iFileName.top(),lineNumber[curLineNumberIndex]};
}

SCLScanner::InputToken SCLScanner::nextToken(){
    // check lookahead
    if (c == -1){
        if (!nextChar(c)) return tEndOfFile;
    }
    
    // skip spaces
    while(isspace(c)){
        if (c == '\n') {
            lineNumber[curLineNumberIndex]++;
        }
        if (!nextChar(c)) {
            c = -1;
            return tEndOfFile;
        }
    }
    while(c != EOF){
        switch (c){
            case '-':
                // minus sign or comment
                if (!nextChar(c)) return tMinus;
                if (c == '-'){
                    // we have a comment.
                    // -- means comment to end of line
                    // --/ /-- is a multiline comment.
                    // EOF at this point in time is the end of single line file and comment
                    if (!nextChar(c)) return tEndOfFile;
                    if (c == '/'){
                        // TODO - finish multiline comment
                        // multiline comment --/ /--
                        while(nextChar(c)){
                            if (c){}
                        }
                        // if we break before end of comment, then tEOF occured at end of file
                        return tEndOfFile;
                    }
                    // not muiltiline comment
                    while (c != '\n'){
                        if (!nextChar(c)) return tEndOfFile;
                    }
                    // end of comment, get another character for next round.
                    if (!nextChar(c)) return tEndOfFile;
                }
                break;
            case ':':
                // must be ::=
                if (!nextChar(c)) return tIllegal;
                if (c != ':'){
                    std::cerr << ": is not valid by itself" << std::endl;
                    return tIllegal;
                }
                if (!nextChar(c)) return tIllegal;
                if (c != '='){
                    std::cerr << ":= is not valid by itself" << std::endl;
                    return tIllegal;
                }
                c = -1; // no current lookahead character
                return (tIS);
            case '=':
                // could be assign or equals
                if (!nextChar(c)) return tEndOfFile;
                if (c == '='){
                    c = -1;
                    return (tASSIGN);
                }
                return tEQ;
            case '!':
                // must be !=
                if (!nextChar(c)) return tEndOfFile;
                if (c != '='){
                    std::cerr << "! is not valid by itself" << std::endl;
                    return tIllegal;
                }
                c = -1;
                return tNEQ;
                
            case '<':
                // < << </ <=
                if (!nextChar(c)) return tLT;
                switch (c){
                    case '<':
                        c = -1;
                        return tLSFT;
                    case '/':
                        c = -1;
                        return tOPENX;
                    case '=':
                        c = -1;
                        return tLE;
                    default:
                        // keep c for next round
                        return tLT;
                }
                
            case '>':
                // > >> >=
                if (!nextChar(c)) return tGT;
                switch (c){
                    case '>':
                        c = -1;
                        return tRSFT;
                    case '=':
                        c = -1;
                        return tGE;
                    default:
                        // keep c for next round
                        return tGT;
                }
            case '|':
                // | ||
                if (!nextChar(c)) return tBOR;
                if (c == '|'){
                    c = -1;
                    return tROR;
                }
                return tBOR;
                
            case '&':
                // & &&
                if (!nextChar(c)) return tBAND;
                if (c == '&'){
                    c = -1;
                    return tRAND;
                }
                return tBAND;
            
            case ';':
                c = -1;
                return tSemicolon;
                
            case '+':
                c = -1;
                return tPlus;
                
            default:
                if (isalpha(c)){
                    ident = "";
                    while(isalpha(c)|| c == '_' || c == '-'){
                        ident.push_back(c);
                        nextChar(c);
                    }
                    // check for keyword first
                    return tIdent;
                }
                std::cout << "hi" << std::endl;
        }
    }
    return tEndOfFile;
}

const std::string SCLScanner::tokenToString(InputToken t){
    if (t == tSyntaxError) return "Syntax Error";
    if (t > tIllegal) return  "Unkown Input Token";
    return tokenNames[t];
}
