#include <iostream>

class SCLScanner {
public:
    SCLScanner();
    void setFile(std::ifstream *inFile){
        infp = inFile;
    }
    
    InputToken nextToken();
    
private:
    std::ifstream * infp;
    char c;
};
