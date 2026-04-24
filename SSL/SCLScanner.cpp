
//
#include "SCL.sst.h"
#include "SCLScanner.h" // includes SCLScanner.h

SCLScanner::SCLScanner(){
};

InputToken SCLScanner::nextToken(){
    return tEndOfFile;
}
