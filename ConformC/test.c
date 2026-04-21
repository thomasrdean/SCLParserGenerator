/*+
 * Regression Program R1
 *
 * Note, for endianness, this program was written on intel which is little endian
 * 
 * SCL5 contains explicit little endian for each of the 6 types
 *	Real 8
 *	Integer 8
 *	Real 4	
 *	Integer 4
 *	Integer 2
 *	integer 1
-*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "globals.h"
#include "packet.h"
#include "putilities.h"
#include "sutilities.h"
#include "R13_Definitions.h"
#include "R13_Serialize.h"
#include "R13_Print.h"

#include "endian.h"

int main() {

    PDU_R13 pdu;

    pdu.t1 = 1;
    pdu.t2 = 0;
    pdu.t3 = 0;
    pdu.t4 = 0;
    pdu.d1 = (DATA_R13*) malloc(sizeof(DATA_R13));
    pdu.d1 -> type  = INT4_R13_VAL;
    pdu.d1->item.int4_r13.val =  2;
    pdu.d2 = NULL;
    pdu.d3 = NULL;
    pdu.d4 = NULL;
    
    printf("**********\n");
    printPDU_R13(stdout,&pdu,0, -1);
    printf("**********\n");
}
