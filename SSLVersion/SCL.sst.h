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
	tIdent,						/* 0 */
	tStringL,					/* 1 */
	tIntegerL,					/* 2 */
	tLT,						/* 3 */
	tLE,						/* 4 */
	tLSFT,						/* 5 */
	tGT,						/* 6 */
	tGE,						/* 7 */
	tRS,						/* 8 */
	tASSIGN,					/* 9 */
	tEQ,						/* 10 */
	tNEQ,						/* 11 */
	tIS,						/* 12 */
	tBOR,						/* 13 */
	tROR,						/* 14 */
	tBAND,						/* 15 */
	tRAND,						/* 16 */
	tSemicolon,					/* 17 */
	tABSENT,					/* 18 */
	tANY,						/* 19 */
	tAPPLICATION,					/* 20 */
	tAUTOMATIC,					/* 21 */
	tBOOLEAN,					/* 22 */
	tBEGIN,						/* 23 */
	tBIG,						/* 24 */
	tBIT,						/* 25 */
	tBY,						/* 26 */
	tCOMPONENT,					/* 27 */
	tCOMPONENTS,					/* 28 */
	tCONTAINING,					/* 29 */
	tDEFAULT,					/* 30 */
	tDEFINED,					/* 31 */
	tDEFINITIONS,					/* 32 */
	tENCODED,					/* 33 */
	tEND,						/* 34 */
	tEXPLICIT,					/* 35 */
	tEXPORTS,					/* 36 */
	tEXTENSIBILITY,					/* 37 */
	tEXTERNAL,					/* 38 */
	tFALSE,						/* 39 */
	tFROM,						/* 40 */
	tGeneralizedTime,				/* 41 */
	tIAString,					/* 42 */
	tIDENTIFIER,					/* 43 */
	tIMPLICIT,					/* 44 */
	tIMPLIED,					/* 45 */
	tIMPORTS,					/* 46 */
	tINCLUDE,					/* 47 */
	tINCLUDES,					/* 48 */
	tINTEGER,					/* 49 */
	tMINUSINFINITY,					/* 50 */
	tNULL,						/* 51 */
	tOCTET,						/* 52 */
	tOBJECT,					/* 53 */
	tOF,						/* 54 */
	tOPTIONAL,					/* 55 */
	tPRESENT,					/* 56 */
	tPLUSINFINITY,					/* 57 */
	tPRIVATE,					/* 58 */
	tREAL,						/* 59 */
	tSEQUENCE,					/* 60 */
	tSET,						/* 61 */
	tSIZE,						/* 62 */
	tSTRING,					/* 63 */
	tTAGS,						/* 64 */
	tTRUE,						/* 65 */
	tUNIVERSAL,					/* 66 */
	tUTCTime,					/* 67 */
	tVisibleString,					/* 68 */
	tWITH,						/* 69 */
	tNewLine,					/* 70 */
	tEndOfFile,					/* 71 */
	tIllegal,					/* 72 */
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

