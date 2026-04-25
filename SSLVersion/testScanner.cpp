//
//  testScanner.cpp
//  
//
//  Created by Thomas Dean on 2026-04-22.
//

#include <iostream>
#include <fstream>
#include <cstdlib>
#include <string>

#include "SCL.sst.h"
#include "SCLScanner.h"

int main(int argc, char * argv[]){
    if (argc < 2){
        std::cerr << "Usage " << argv[0] << " infile" << std::endl;
        exit(1);
    }

    std::ifstream iFile(argv[1]);

    if (! iFile.is_open()){
        std::cerr << argv[0] << ": could not open " << argv[1] << "for read" << std::endl;
        exit(1);
    }

    SCLScanner scanner;

    scanner.setFile(&iFile);

    InputToken theToken = scanner.nextToken();

    while (theToken != tEndOfFile){
        std::cout << scanner.tokenToString(theToken) << std::endl;
    }


    iFile.close();
}


