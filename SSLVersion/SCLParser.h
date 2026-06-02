
#include <iostream>
#include <memory>

// 

#include "SCLScanner.h"

class SCLParser {

public:

    #include "SCL.sst.h"
    
    SCLParser();
    //~SCLParser();
    
    // public interface to the walker.
    void SslWalker();

    void setTraceFile(FILE *f);
    void setInputFile(std::ifstream *inFile);
    void setOutputFile(FILE *f);

private:

    // SSL bytecodes
    // this will be instantiated in the
    // main file. This make sure it is
    // a class variable and only created once
    // for all parsers of the same class
    static int sslTable[];
    
    // Table Walker State
    
    int processing = 1; 	// are we running the table walker
    int sslPointer = 0; 	// current position in SSL bytecodes
    TableOperation operation;	// the current operation
    
    // tracing file
    FILE * tracefp = NULL;
    
    // abort flag
    int aborted = 0;
    
    /*
    * The Rule Call Stack implements Syntax/Semantic Language rule call and return.
    * Each time an oCall operation is executed, the table return address is pushed
    * onto the Rule Call Stack.  When an oReturn is executed, the return address
    * is popped from the stack.  An oReturn executed when the Rule Call Stack is
    * empty terminates table execution.
    */

    static const int sslStackSize = 127; 
    int sslStack[sslStackSize];
    int sslTop = 0;
    
    /*
    * Set by the Choice Handler to indicate whether a match was made or the
    * otherwise path was taken.  Set to true if a match was made and false
    * otherwise.  This flag is used in input choices to indicate whether the
    * choice input token should be accepted or not.
    */
    int choiceTagMatched;
    
    /*
    * These are used to hold the decoded parameter value to a parameterized
    * semantic operation and the result value returned by a choice semantic
    * operation or rule respectively.
    */

    int parameterValue;
    int resultValue;
    
    /* S/SL System Failure Codes */
    typedef enum {
        fSemanticChoiceFailed,
        fChoiceRuleFailed
    } FailureCode;
    
    
    static const int maxErrors = 20;
    int noErrors = 0;
    ErrorCode firstFatalErrorCode = eSslStackOverflow; // parser specific *fix*
    
    /* Input Tokens */

    std::unique_ptr<SCLScanner> scanner = nullptr;
    
    /* Compound Input Tokens */
    static const SCLScanner::InputToken firstCompoundToken = SCLScanner::tIntegerL; // *fix*
    static const SCLScanner::InputToken lastCompoundToken = SCLScanner::tIntegerL;  // *fix*
    
    
    /* Input Interface */
    std::ifstream    *infp = nullptr;
    SCLScanner::InputToken nextInputToken = SCLScanner::tNewLine;
    SCLScanner::InputToken savedToken;
    
    /*
    * The Compound Input Token Buffer:
    * When a compound input token is accepted from the input stream, its
    * associated value is saved in the compound token buffer for use by
    * the Semantic Mechanisms of the pass.
    */
    SCLScanner::InputToken compoundToken;
    int compoundValue;			// *fix*
    const char * compoundText;		// *fix*
    
    /* Line Counters */
    int nextLineNumber = 0;
    int lineNumber = 0;
    
    /* Output Interface */

    FILE * outfp = NULL;
    
    /* Variables Used in Syntax Error Recovery */

    int newInputLine = 0;
    SCLScanner::InputToken savedInputToken;
    
    // prototypes
    void Error(ErrorCode);
    void AcceptInputToken();
    void EmitOutputToken(OutputToken tokenToEmit);
    void SslGenerateCompoundInputToken(SCLScanner::InputToken expectedToken);
    void SslSyntaxError();
    void SslTrace(FILE*);
    void SslFailure(FailureCode);
    void SslChoice(int);
    
    // variables for semantic mechanisms *fix*
    
};
