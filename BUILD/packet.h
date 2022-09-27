/*+
 * File:    Packet.h
 *
 * Purpose: Interface to the packet reader.
 *
 * Revision History:
 *
 * 1.0  - Thomas R. Dean June 2004
 *  - Initial Version
-*/

#ifndef _PACKET_H_
#define _PACKET_H_

typedef struct _pdu {
    unsigned char * data;   // The actual PDU data
    unsigned long len;      // PDULENGTH
    unsigned long watermark; //watermark to determine if the curPos was set outside the pdu length by doToken set to "len by readPDU
    unsigned long curPos;   // Current parse position 0..len
    unsigned long curBitPos;    // current position within a bit 0..8
    unsigned long remaining;
                    // used when parsing flags.
   	struct HeaderInfo * header;
} PDU;

/* read a PDU from a file */
PDU * readPDU(char *);

#endif /* _PACKET_H_ */
