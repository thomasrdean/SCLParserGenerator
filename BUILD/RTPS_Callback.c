#include "globals.h"
#include "RTPS_Definitions.h"

void PING_RTPS_callback (PING_RTPS *ping_rtps, PDU *thePDU){
    if (traceFileParser) fprintf(traceFileParser, "\tRTPS PING");
}
void FULL_RTPS_callback (FULL_RTPS *full_rtps, PDU *thePDU){
    if (traceFileParser) fprintf(traceFileParser, "\tRTPS FULL");
}

void DATAPSUB_RTPS_callback (FULL_RTPS *full_rtps, DATAPSUB_RTPS *datapsub_rtps, PDU *thePDU){
    if (traceFileParser) fprintf(traceFileParser, " DATAPSUB");
}

void DATASUB_RTPS_callback (FULL_RTPS *full_rtps, DATASUB_RTPS *datasub_rtps, PDU *thePDU){
    if (traceFileParser) fprintf(traceFileParser, " DATASUB");
}

void DATAWSUB_RTPS_callback (FULL_RTPS *full_rtps, DATAWSUB_RTPS *datawsub_rtps, PDU *thePDU){
    if (traceFileParser) fprintf(traceFileParser, " DATAWSUB");
}

void DATARSUB_RTPS_callback (FULL_RTPS *full_rtps, DATARSUB_RTPS *datarsub_rtps, PDU *thePDU){
    if (traceFileParser) fprintf(traceFileParser, " DATARSUB");
}

void INFO$DST_RTPS_callback (FULL_RTPS *full_rtps, INFO$DST_RTPS *info$dst_rtps, PDU *thePDU){
    if (traceFileParser) fprintf(traceFileParser, " INFO_DST");
}

void INFO$TS_RTPS_callback (FULL_RTPS *full_rtps, INFO$TS_RTPS *info$ts_rtps, PDU *thePDU){
    if (traceFileParser) fprintf(traceFileParser, " INFO_TS");
}

void ACKNACK_RTPS_callback (FULL_RTPS *full_rtps, ACKNACK_RTPS *acknack_rtps, PDU *thePDU){
    if (traceFileParser) fprintf(traceFileParser, " ACKNACK");
}

void HEARTBEAT_RTPS_callback (FULL_RTPS *full_rtps, HEARTBEAT_RTPS *heartbeat_rtps, PDU *thePDU){
    if (traceFileParser) fprintf(traceFileParser, " HEARTBEAT");
}

void GAP_RTPS_callback (FULL_RTPS *full_rtps, GAP_RTPS *gap_rtps, PDU *thePDU){
    if (traceFileParser) fprintf(traceFileParser, " GAP");
}

