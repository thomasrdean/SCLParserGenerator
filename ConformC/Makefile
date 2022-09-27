

all: diff

# for genereated filles
GENDIR=../ConformSrc/

# for packet.h
BLDIR=../BUILD/
RLIBS=objs/putilities.o objs/sutilities.o

GENINC=$(BLDIR)/globals.h $(BLDIR)/packet.h $(BLDIR)/putilities.h
SERINC=$(BLDIR)/globals.h $(BLDIR)/packet.h $(BLDIR)/sutilities.h

IFLAGS=-I$(GENDIR) -I$(BLDIR)

diff: allExecs

allExecs: bin/R1 bin/R2 bin/R3 bin/R4 bin/R5 bin/R6 bin/R7 bin/R8 bin/R9 bin/R10 bin/R11 bin/R12

clean:
	rm objs/* bin/*

# putlities from ../BUILD
objs/putilities.o: $(BLDIR)/putilities.c
	cc -g -c -o objs/putilities.o -I$(BLDIR) $(BLDIR)/putilities.c
objs/sutilities.o: $(BLDIR)/sutilities.c
	cc -g -c -o objs/sutilities.o -I$(BLDIR) $(BLDIR)/sutilities.c

# Conformance GTests
bin/R1: objs/R1_Generated.o objs/R1_Serialize.o objs/R1_Print.o objs/R1.o $(RLIBS)
	cc -g -o bin/R1 objs/R1.o objs/R1_Generated.o objs/R1_Serialize.o objs/R1_Print.o $(RLIBS)
objs/R1_Generated.o: $(GENDIR)/R1_Definitions.h $(GENDIR)R1_Generated.c $(GENINC)
	cc -g -c -o objs/R1_Generated.o $(IFLAGS)  $(GENDIR)/R1_Generated.c
objs/R1_Serialize.o: $(GENDIR)/R1_Definitions.h $(GENDIR)R1_Serialize.c $(SERINC)
	cc -g -c -o objs/R1_Serialize.o $(IFLAGS)  $(GENDIR)/R1_Serialize.c
objs/R1_Print.o: $(GENDIR)/R1_Definitions.h $(GENDIR)R1_Print.c $(SERINC)
	cc -g -c -o objs/R1_Print.o $(IFLAGS)  $(GENDIR)/R1_Print.c
objs/R1.o: R1.c $(GENDIR)/R1_Definitions.h $(GENDIR)/R1_Serialize.h $(GENDIR)/R1_Print.h endian.h
	cc -g -c -o objs/R1.o $(IFLAGS) R1.c

bin/R2: objs/R2_Generated.o objs/R2_Serialize.o objs/R2_Print.o objs/R2.o $(RLIBS)
	cc -g -o bin/R2 objs/R2.o objs/R2_Generated.o objs/R2_Serialize.o objs/R2_Print.o $(RLIBS)
objs/R2_Generated.o: $(GENDIR)/R2_Definitions.h $(GENDIR)/R2_Generated.c $(GENINC)
	cc -g -c -o objs/R2_Generated.o $(IFLAGS) $(GENDIR)/R2_Generated.c
objs/R2_Serialize.o: $(GENDIR)/R2_Serialize.h $(GENDIR)/R2_Serialize.c $(SERINC)
	cc -g -c -o objs/R2_Serialize.o $(IFLAGS) $(GENDIR)/R2_Serialize.c
objs/R2_Print.o: $(GENDIR)/R2_Print.h $(GENDIR)/R2_Print.c $(SERINC)
	cc -g -c -o objs/R2_Print.o $(IFLAGS) $(GENDIR)/R2_Print.c
objs/R2.o: R2.c $(GENDIR)/R2_Definitions.h endian.h $(GENDIR)/R2_Serialize.h $(GENDIR)/R2_Print.h
	cc -g -c -o objs/R2.o $(IFLAGS) R2.c

bin/R3: objs/R3_Generated.o objs/R3_Serialize.o objs/R3.o objs/R3_Print.o $(RLIBS)
	cc -g -o bin/R3 objs/R3.o objs/R3_Generated.o objs/R3_Serialize.o objs/R3_Print.o $(RLIBS)
objs/R3_Generated.o: $(GENDIR)/R3_Definitions.h $(GENDIR)/R3_Generated.c $(GENINC)
	cc -g -c -o objs/R3_Generated.o $(IFLAGS) $(GENDIR)/R3_Generated.c
objs/R3_Serialize.o: $(GENDIR)/R3_Serialize.h $(GENDIR)/R3_Serialize.c $(SERINC)
	cc -g -c -o objs/R3_Serialize.o $(IFLAGS) $(GENDIR)/R3_Serialize.c
objs/R3_Print.o: $(GENDIR)/R3_Print.h $(GENDIR)/R3_Print.c $(SERINC)
	cc -g -c -o objs/R3_Print.o $(IFLAGS) $(GENDIR)/R3_Print.c
objs/R3.o: R3.c $(GENDIR)/R3_Definitions.h endian.h $(GENDIR)/R3_Serialize.h $(GENDIR)/R3_Print.h
	cc -g -c -o objs/R3.o $(IFLAGS) R3.c

bin/R4: objs/R4_Generated.o objs/R4_Serialize.o objs/R4.o objs/R4_Print.o $(RLIBS)
	cc -g -o bin/R4 objs/R4.o objs/R4_Generated.o objs/R4_Serialize.o objs/R4_Print.o $(RLIBS)
objs/R4_Generated.o: $(GENDIR)/R4_Definitions.h $(GENDIR)/R4_Generated.c $(GENINC)
	cc -g -c -o objs/R4_Generated.o $(IFLAGS) $(GENDIR)/R4_Generated.c
objs/R4_Serialize.o: $(GENDIR)/R4_Serialize.h $(GENDIR)/R4_Serialize.c $(SERINC)
	cc -g -c -o objs/R4_Serialize.o $(IFLAGS) $(GENDIR)/R4_Serialize.c
objs/R4_Print.o: $(GENDIR)/R4_Print.h $(GENDIR)/R4_Print.c $(SERINC)
	cc -g -c -o objs/R4_Print.o $(IFLAGS) $(GENDIR)/R4_Print.c
objs/R4.o: R4.c $(GENDIR)/R4_Definitions.h endian.h $(GENDIR)/R4_Print.h $(GENDIR)/R4_Print.h 
	cc -g -c -o objs/R4.o $(IFLAGS) R4.c

bin/R5: objs/R5_Generated.o objs/R5_Serialize.o objs/R5.o objs/R5_Print.o $(RLIBS)
	cc -g -o bin/R5 objs/R5.o objs/R5_Generated.o objs/R5_Serialize.o objs/R5_Print.o $(RLIBS)
objs/R5_Generated.o: $(GENDIR)/R5_Definitions.h $(GENDIR)/R5_Generated.c $(GENINC)
	cc -g -c -o objs/R5_Generated.o $(IFLAGS) $(GENDIR)/R5_Generated.c
objs/R5_Serialize.o: $(GENDIR)/R5_Serialize.h $(GENDIR)/R5_Serialize.c $(SERINC)
	cc -g -c -o objs/R5_Serialize.o $(IFLAGS) $(GENDIR)/R5_Serialize.c
objs/R5_Print.o: $(GENDIR)/R5_Print.h $(GENDIR)/R5_Print.c $(SERINC)
	cc -g -c -o objs/R5_Print.o $(IFLAGS) $(GENDIR)/R5_Print.c
objs/R5.o: R5.c $(GENDIR)/R5_Definitions.h endian.h $(GENDIR)/R5_Serialize.h $(GENDIR)/R5_Print.h 
	cc -g -c -o objs/R5.o $(IFLAGS) R5.c

bin/R6: objs/R6_Generated.o objs/R6_Serialize.o objs/R6.o objs/R6_Print.o $(RLIBS)
	cc -g -o bin/R6 objs/R6.o objs/R6_Generated.o objs/R6_Serialize.o objs/R6_Print.o $(RLIBS)
objs/R6_Generated.o: $(GENDIR)/R6_Definitions.h $(GENDIR)/R6_Generated.c $(GENINC)
	cc -g -c -o objs/R6_Generated.o $(IFLAGS) $(GENDIR)/R6_Generated.c
objs/R6_Serialize.o: $(GENDIR)/R6_Serialize.h $(GENDIR)/R6_Serialize.c $(SERINC)
	cc -g -c -o objs/R6_Serialize.o $(IFLAGS) $(GENDIR)/R6_Serialize.c
objs/R6_Print.o: $(GENDIR)/R6_Print.h $(GENDIR)/R6_Print.c $(SERINC)
	cc -g -c -o objs/R6_Print.o $(IFLAGS) $(GENDIR)/R6_Print.c
objs/R6.o: R6.c $(GENDIR)/R6_Definitions.h endian.h $(GENDIR)/R6_Serialize.h $(GENDIR)/R6_Print.h
	cc -g -c -o objs/R6.o $(IFLAGS) R6.c

bin/R7: objs/R7_Generated.o objs/R7_Serialize.o objs/R7.o objs/R7_Print.o $(RLIBS)
	cc -g -o bin/R7 objs/R7.o objs/R7_Generated.o objs/R7_Serialize.o objs/R7_Print.o $(RLIBS)
objs/R7_Generated.o: $(GENDIR)/R7_Definitions.h $(GENDIR)/R7_Generated.c $(GENINC)
	cc -g -c -o objs/R7_Generated.o $(IFLAGS) $(GENDIR)/R7_Generated.c
objs/R7_Serialize.o: $(GENDIR)/R7_Serialize.h $(GENDIR)/R7_Serialize.c $(SERINC)
	cc -g -c -o objs/R7_Serialize.o $(IFLAGS) $(GENDIR)/R7_Serialize.c
objs/R7_Print.o: $(GENDIR)/R7_Print.h $(GENDIR)/R7_Print.c $(SERINC)
	cc -g -c -o objs/R7_Print.o $(IFLAGS) $(GENDIR)/R7_Print.c
objs/R7.o: R7.c $(GENDIR)/R7_Definitions.h endian.h $(GENDIR)/R7_Serialize.h $(GENDIR)/R7_Print.h
	cc -g -c -o objs/R7.o $(IFLAGS) R7.c

bin/R8: objs/R8_Generated.o objs/R8_Serialize.o objs/R8.o objs/R8_Print.o $(RLIBS)
	cc -g -o bin/R8 objs/R8.o objs/R8_Generated.o objs/R8_Serialize.o objs/R8_Print.o $(RLIBS)
objs/R8_Generated.o: $(GENDIR)/R8_Definitions.h $(GENDIR)/R8_Generated.c $(GENINC)
	cc -g -c -o objs/R8_Generated.o $(IFLAGS) $(GENDIR)/R8_Generated.c
objs/R8_Serialize.o: $(GENDIR)/R8_Serialize.h $(GENDIR)/R8_Serialize.c $(SERINC)
	cc -g -c -o objs/R8_Serialize.o $(IFLAGS) $(GENDIR)/R8_Serialize.c
objs/R8_Print.o: $(GENDIR)/R8_Print.h $(GENDIR)/R8_Print.c $(SERINC)
	cc -g -c -o objs/R8_Print.o $(IFLAGS) $(GENDIR)/R8_Print.c
objs/R8.o: R8.c $(GENDIR)/R8_Definitions.h endian.h $(GENDIR)/R8_Serialize.h $(GENDIR)/R8_Print.h
	cc -g -c -o objs/R8.o $(IFLAGS) R8.c

bin/R9: objs/R9_Generated.o objs/R9_Serialize.o objs/R9.o objs/R9_Print.o $(RLIBS)
	cc -g -o bin/R9 objs/R9.o objs/R9_Generated.o objs/R9_Serialize.o objs/R9_Print.o $(RLIBS)
objs/R9_Generated.o: $(GENDIR)/R9_Definitions.h $(GENDIR)/R9_Generated.c $(GENINC)
	cc -g -c -o objs/R9_Generated.o $(IFLAGS) $(GENDIR)/R9_Generated.c
objs/R9_Serialize.o: $(GENDIR)/R9_Serialize.h $(GENDIR)/R9_Serialize.c $(SERINC)
	cc -g -c -o objs/R9_Serialize.o $(IFLAGS) $(GENDIR)/R9_Serialize.c
objs/R9_Print.o: $(GENDIR)/R9_Print.h $(GENDIR)/R9_Print.c $(SERINC)
	cc -g -c -o objs/R9_Print.o $(IFLAGS) $(GENDIR)/R9_Print.c
objs/R9.o: R9.c $(GENDIR)/R9_Definitions.h endian.h $(GENDIR)/R9_Serialize.h $(GENDIR)/R9_Print.h
	cc -g -c -o objs/R9.o $(IFLAGS) R9.c

bin/R10: objs/R10_Generated.o objs/R10_Serialize.o objs/R10.o objs/R10_Print.o $(RLIBS)
	cc -g -o bin/R10 objs/R10.o objs/R10_Generated.o objs/R10_Serialize.o objs/R10_Print.o $(RLIBS)
objs/R10_Generated.o: $(GENDIR)/R10_Definitions.h $(GENDIR)/R10_Generated.c $(GENINC)
	cc -g -c -o objs/R10_Generated.o $(IFLAGS) $(GENDIR)/R10_Generated.c
objs/R10_Serialize.o: $(GENDIR)/R10_Serialize.h $(GENDIR)/R10_Serialize.c $(SERINC)
	cc -g -c -o objs/R10_Serialize.o $(IFLAGS) $(GENDIR)/R10_Serialize.c
objs/R10_Print.o: $(GENDIR)/R10_Print.h $(GENDIR)/R10_Print.c $(SERINC)
	cc -g -c -o objs/R10_Print.o $(IFLAGS) $(GENDIR)/R10_Print.c
objs/R10.o: R10.c $(GENDIR)/R10_Definitions.h endian.h $(GENDIR)/R10_Serialize.h $(GENDIR)/R10_Print.h
	cc -g -c -o objs/R10.o $(IFLAGS) R10.c

bin/R11: objs/R11_Generated.o objs/R11_Serialize.o objs/R11.o objs/R11_Print.o $(RLIBS)
	cc -g -o bin/R11 objs/R11.o objs/R11_Generated.o objs/R11_Serialize.o objs/R11_Print.o $(RLIBS)
objs/R11_Generated.o: $(GENDIR)/R11_Definitions.h $(GENDIR)/R11_Generated.c $(GENINC)
	cc -g -c -o objs/R11_Generated.o $(IFLAGS) $(GENDIR)/R11_Generated.c
objs/R11_Serialize.o: $(GENDIR)/R11_Serialize.h $(GENDIR)/R11_Serialize.c $(SERINC)
	cc -g -c -o objs/R11_Serialize.o $(IFLAGS) $(GENDIR)/R11_Serialize.c
objs/R11_Print.o: $(GENDIR)/R11_Print.h $(GENDIR)/R11_Print.c $(SERINC)
	cc -g -c -o objs/R11_Print.o $(IFLAGS) $(GENDIR)/R11_Print.c
objs/R11.o: R11.c $(GENDIR)/R11_Definitions.h endian.h $(GENDIR)/R11_Serialize.h $(GENDIR)/R11_Print.h
	cc -g -c -o objs/R11.o $(IFLAGS) R11.c

bin/R12: objs/R12_Generated.o objs/R12_Serialize.o objs/R12.o objs/R12_Print.o $(RLIBS)
	cc -g -o bin/R12 objs/R12.o objs/R12_Generated.o objs/R12_Serialize.o objs/R12_Print.o $(RLIBS)
objs/R12_Generated.o: $(GENDIR)/R12_Definitions.h $(GENDIR)/R12_Generated.c $(GENINC)
	cc -g -c -o objs/R12_Generated.o $(IFLAGS) $(GENDIR)/R12_Generated.c
objs/R12_Serialize.o: $(GENDIR)/R12_Serialize.h $(GENDIR)/R12_Serialize.c $(SERINC)
	cc -g -c -o objs/R12_Serialize.o $(IFLAGS) $(GENDIR)/R12_Serialize.c
objs/R12_Print.o: $(GENDIR)/R12_Print.h $(GENDIR)/R12_Print.c $(SERINC)
	cc -g -c -o objs/R12_Print.o $(IFLAGS) $(GENDIR)/R12_Print.c
objs/R12.o: R12.c $(GENDIR)/R12_Definitions.h endian.h $(GENDIR)/R12_Serialize.h $(GENDIR)/R12_Print.h
	cc -g -c -o objs/R12.o $(IFLAGS) R12.c
