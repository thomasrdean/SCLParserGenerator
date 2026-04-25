#include <iostream>
#include <fstream>
#include <map>

class SCLScanner {
public:
    SCLScanner();
    void setFile(std::ifstream *inFile){
        infp = inFile;
    }
    
    InputToken nextToken();
    const std::string tokenToString(InputToken);
    
private:
    std::ifstream * infp;
    char c = -1;
    std::string ident;
    std::map<std::string,InputToken> keys;
};
