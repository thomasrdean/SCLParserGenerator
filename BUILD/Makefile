CFLAGS = -g 
LDFLAGS = -g
#BASEOBJS= ARP_Generated.o UDP_Generated.o IGMP_Generated.o RTPS_Generated.o NTP_Generated.o putilities.o packet.o StringHash.o DNS_Generated.o
#BASEOBJS= ARP_Generated.o putilities.o packet.o StringHash.o IGMP_Generated.o
BASEOBJS= putilities.o sutilities.o packet.o StringHash.o \
    DNS_Generated.o DNS_Serialize.o DNS_Print.o DNS_Callback.o\
    ARP_Generated.o ARP_Serialize.o ARP_Print.o ARP_Callback.o\
    RTPS_Generated.o RTPS_Serialize.o RTPS_Print.o RTPS_Callback.o\
    IGMP_Generated.o IGMP_Serialize.o IGMP_Print.o IGMP_Callback.o\
    UDP_Generated.o UDP_Serialize.o UDP_Print.o   \
    NTP_Generated.o NTP_Serialize.o NTP_Print.o  

OBJS= $(BASEOBJS) #callback.o

# no constraint engine, so no learn mode, but leave in the makefile for integration for now
all: bin/pcapparse

bin/pcapparse:  pmain.o $(OBJS)
	gcc -o bin/pcapparse $(LDFLAGS) pmain.o $(OBJS) -lpcap 

bin/pcapdebug: pmain.o $(OBJS)
	gcc -O0 -o bin/pcapdebug $(LDFLAGS) pmain.o $(OBJS) -lpcap

clean:
	rm -f *.o bin/pcapparse bin/pcapdebug bin/pcapparseLearn bin/pcapdebugLearn

# MAIN
pmain.o: globals.h 

# PARSER  - assumes the network protocols for DND research
# need to generalize this

#UDP_Generated.o: globals.h  UDP_Definitions.h

IGMP_Generated.o: globals.h  IGMP_Definitions.h putilities.h
IGMP_Serialize.o: globals.h  IGMP_Definitions.h IGMP_Serialize.h sutilities.h
IGMP_Print.o: globals.h  IGMP_Definitions.h IGMP_Print.h sutilities.h
IGMP_Callback.o: globals.h  IGMP_Definitions.h 

RTPS_Generated.o: globals.h  RTPS_Definitions.h
RTPS_Serialize.o: globals.h  RTPS_Definitions.h RTPS_Serialize.h sutilities.h
RTPS_Print.o: globals.h  RTPS_Definitions.h RTPS_Print.h sutilities.h
RTPS_Callback.o: globals.h  RTPS_Definitions.h

ARP_Generated.o: globals.h ARP_Definitions.h putilities.h
ARP_Serialize.o: globals.h ARP_Definitions.h ARP_Serialize.h sutilities.h
ARP_Print.o: globals.h ARP_Definitions.h ARP_Print.h sutilities.h
ARP_Callback.o: globals.h ARP_Definitions.h

DNS_Generated.o: globals.h DNS_Definitions.h putilities.h
DNS_Serialize.o: globals.h DNS_Definitions.h DNS_Serialize.h sutilities.h
DNS_Print.o: globals.h DNS_Definitions.h DNS_Print.h sutilities.h
DNS_Callback.o: globals.h DNS_Definitions.h 

putilities.o: putilities.h
sutilities.o: sutilities.h

packet.o: globals.h packet.h

StringHash.o: StringHash.h

callback.o: globals.h StringHash.h #IGMP_Generated.h RTPS_Generated.h
