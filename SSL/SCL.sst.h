#pragma once
/* Semantic Operations */

typedef enum {
	oCall = 0,					/* 0 */
	oReturn,					/* 1 */
	oRuleEnd,					/* 2 */
	oJump,						/* 3 */
	oInput,						/* 4 */
	oInputAny,					/* 5 */
	oInputChoice,					/* 6 */
	oEmit,						/* 7 */
	oError,						/* 8 */
	oChoice,					/* 9 */
	oChoiceEnd,					/* 10 */
	oSetParameter,					/* 11 */
	oSetResult,					/* 12 */
	oSetResultFromInput,				/* 13 */
} TableOperation;

/* Input Tokens */

typedef enum {
	tSyntaxError = -1,				/* -1 */
	tLT,						/* 0 */
	tGT,						/* 1 */
	tASSIGN,					/* 2 */
	tEQ,						/* 3 */
	tNEQ,						/* 4 */
	tIS,						/* 5 */
	tSemicolon,					/* 6 */
	tBOOLEAN,					/* 7 */
	tBEGIN,						/* 8 */
	tBIG,						/* 9 */
	tBIT,						/* 10 */
	tDEFINITIONS,					/* 11 */
	tEND,						/* 12 */
	tEXPLICIT,					/* 13 */
	tEXPORTS,					/* 14 */
	tIMPLICIT,					/* 15 */
	tIMPORTS,					/* 16 */
	tINCLUDES,					/* 17 */
	tINTEGER,					/* 18 */
	tNULL,						/* 19 */
	tOCTET,						/* 20 */
	tOF,						/* 21 */
	tSEQUENCE,					/* 22 */
	tSTRING,					/* 23 */
	tREAL,						/* 24 */
	tSET,						/* 25 */
	tANY,						/* 26 */
	tSIZE,						/* 27 */
	tEXTERNAL,					/* 28 */
	tFROM,						/* 29 */
	tOBJECT,					/* 30 */
	tWITH,						/* 31 */
	tIDENTIFIER,					/* 32 */
	tCOMPONENT,					/* 33 */
	tOPTIONAL,					/* 34 */
	tPRESENT,					/* 35 */
	tDEFAULT,					/* 36 */
	tABSENT,					/* 37 */
	tCOMPONENTS,					/* 38 */
	tDEFINED,					/* 39 */
	tUNIVERSAL,					/* 40 */
	tBY,						/* 41 */
	tAPPLICATION,					/* 42 */
	tPLUSINFINITY,					/* 43 */
	tPRIVATE,					/* 44 */
	tMINUSINFINITY,					/* 45 */
	tTRUE,						/* 46 */
	tTAGS,						/* 47 */
	tFALSE,						/* 48 */
	tAUTOMATIC,					/* 49 */
	tEXTENSIBILITY,					/* 50 */
	tIMPLIED,					/* 51 */
	tENCODED,					/* 52 */
	tCONTAINING,					/* 53 */
	tVisibleString,					/* 54 */
	tUTCTime,					/* 55 */
	tGeneralizedTime,				/* 56 */
	tIAString,					/* 57 */
	tINCLUDE,					/* 58 */
	tIdent,						/* 59 */
	tStringL,					/* 60 */
	tIntegerL,					/* 61 */
	tNewLine,					/* 62 */
	tEndOfFile,					/* 63 */
} InputToken;

/* Output Tokens */

typedef enum {
	aOutputToken = 0,				/* 0 */
} OutputToken;

/* Input/Output Tokens */


/* Error Codes */

typedef enum {
	eNoError = 0,					/* 0 */
	eSyntaxError,					/* 1 */
	ePrematureEndOfFile,				/* 2 */
	eExtraneousProgramText,				/* 3 */
	eFirstUserError = 10,				/* 10 */
	eSslStackOverflow = 40,				/* 40 */
} ErrorCode;

/* Type Values */

