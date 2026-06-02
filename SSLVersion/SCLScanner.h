#include <iostream>
#include <fstream>
#include <map>

class SCLScanner {
public:

#include "SCL.tokens.h"

    struct curPosT {
        std::string name;
        int lineNo;
    };
    
    SCLScanner();

    bool pushFile(std::string fname);
    
    InputToken nextToken();
    bool nextChar(char&c);
    
    curPosT curPos();

    const std::string tokenToString(InputToken);
    
private:
    //std::ifstream * infp;
    char c = -1;
    std::string ident;
    std::map<std::string,InputToken> keys;
    std::stack<std::ifstream*> infp;
    std::stack<std::string>iFileName;
    int lineNumber[100];
    int curLineNumberIndex=-1;
};
