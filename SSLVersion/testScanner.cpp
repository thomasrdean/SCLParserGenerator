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

#include "SCLScanner.h"

int main(int argc, char * argv[]){
    if (argc < 2){
        std::cerr << "Usage " << argv[0] << " infile" << std::endl;
        exit(1);
    }

    SCLScanner scanner;

    if (!scanner.pushFile(argv[1])){
        std::cerr << argv[0] << ": could not open " << argv[1] << "for read" << std::endl;
        exit(1);
    }

    SCLScanner::InputToken theToken = scanner.nextToken();

    while (theToken != SCLScanner::tEndOfFile){
        std::cout << scanner.tokenToString(theToken) << std::endl;
    }

}


