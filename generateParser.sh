#!/bin/bash

# TODO - have to add some extra flags for translation such as -nocallback

InDir="SCL5"
TmpDir="INTERMEDIATE"
OutDir="GENSOURCE"
BuildDir="BUILD"
Debug=""
Callback=""
Submodule=""
Copy="No"
TxlDir=""

printHelp(){
        echo "Usage: $0 [-h] [-c] [-i SCL5Dir] [-t IntDir] [-o OutDir] [-b BuildDir]"
	echo " -h (--help): print this message"
	echo " -c (--copy): copy files from OutDir to BuildDir (Default No)"
	echo " -i (--input) SCL5Dir: Directory that contains input SCL5 parser spec files (Default SCL5)"
	echo " -t (--tmp) IntDir: Intermediate Directory for Translator temp files (Default INTERMEDIATE)"
	echo " -o (--out) OutDir: Directory for generated source code (Default GENSOURCE)"
	echo " -b (--build) BuildDir: Directory to build final system (Default BUILD)"
	echo " -b (--build) BuildDir: Directory to build final system (Default BUILD)"
        echo " -k (--callback) Implement callback directives"
        echo " -s (--submodule) Do submodule optimization"
        echo " -T (--Txl) Txl directory"
}

checkForArg(){
   if [[ "$2" == 1 ]]
   then
       echo "Missing parmeter for argument $1"
       exit 1
   fi
}

checkForArg2(){
   if [[ "$2" == -* ]]
   then
       echo "Missing parmeter for argument $1"
       exit 1
   fi
}

while [[ $# -gt 0 ]]
do
    case "$1" in
      -h | --help)
        printHelp
	exit 0
	shift
	;;
      -c | --copy)
        Copy="Yes"
	shift
	;;
      -i | --input)
        checkForArg $1 $#
	# know that $2 exists if we get here
        checkForArg2 $1 $2
        InDir="$2"
	shift
	shift
	;;
      -t | --tmp)
        checkForArg $1 $#
	# know that $2 exists if we get here
        checkForArg2 $1 $2
        TmpDir="$2"
	shift
	shift
	;;
      -o | --out)
        checkForArg $1 $#
	# know that $2 exists if we get here
        checkForArg2 $1 $2
        OutDir="$2"
	shift
	shift
	;;
      -b | --build)
        checkForArg $1 $#
	# know that $2 exists if we get here
        checkForArg2 $1 $2
        BuildDir="$2"
	shift
	shift
	;;
      -d | --debug)
        Debug="-debug"
	shift
	;;
      -k | --callback)
        Callback="-callback"
        shift
        ;;
      -s | --submodule)
        Submodule="-submodule"
        shift
        ;;
     -T | --Txl)
        checkForArg $1 $#
        # know that $2 exists if we get here
        checkForArg2 $1 $2
        TxlDir="-i $2"
        shift
        shift
        ;;
      *)
      	echo "unrecognized argument"
	exit 1
	;;
    esac
done


echo "Input Directory is ${InDir}"
echo "Intermediate Directory is ${TmpDir}"
echo "Ouput Code Directory is ${OutDir}"
echo "Ouput Build Directory is ${BuildDir}"
echo "Copy to Build Directory is ${Copy}"
echo "Debug is ${Debug}"
echo "Callback is  ${Callback}"
echo "Submodule is  ${Submodule}"
echo "InputFile is  ${InputFile}"
echo TxlDir is $TxlDir

# check writing directories
if [ ! -d "$TmpDir" ]
then
   mkdir -p "$TmpDir"
fi

if [ ! -d "$OutDir" ]
then
   mkdir -p "$OutDir"
fi

if [ ! -d "$BuildDir" ]
then
   mkdir -p "$BuildDir"
fi

GenFlags=""
if [[ ! -z "$Debug" || ! -z "$Callback" || -z "$Submodule" ]]
then
    GenFlags="- ${Debug} ${Callback} ${Submodule}"
fi
CodeGenFlags=""
if [[ ! -z "$Debug" || ! -z "$Callback" || -z "$Submodule" ]]
then
    CodeGenFlags="${Debug} ${Callback} ${Submodule}"
fi

# Do generation
for file in ${InDir}/*.scl5
do
    #echo $file

    fullfilename=`basename -- "$file"`
    filename="${fullfilename%.*}"

    echo Processing "$filename"
    # Unique naming for all declarations
    txl -q ${TxlDir} $file 01UID_decl.txl > ${TmpDir}/"$filename"_decl.scl5
    ret=$?; if [ $ret -ne 0 ]; then exit $ret; fi;

    # Unique naming for all References
    # todo - add parameter for module file direcotry (incase INTERMEDIATE has been overridden)
    txl -q ${TxlDir} ${TmpDir}/"$filename"_decl.scl5 02UID_ref.txl  - -Intermediate "${TmpDir}" > ${TmpDir}/"$filename"_ref.scl5
    ret=$?; if [ $ret -ne 0 ]; then exit $ret; fi;

    # Callback annotation
    txl -q ${TxlDir} ${TmpDir}/"$filename"_ref.scl5 04Callback_Annotation.txl  > ${TmpDir}/"$filename"_callback.scl5
    ret=$?; if [ $ret -ne 0 ]; then exit $ret; fi;

    # LL annotation
    txl -q ${TxlDir} ${TmpDir}/"$filename"_callback.scl5 05LLOptimization.txl  > ${TmpDir}/"$filename"_opt1.scl5
    ret=$?; if [ $ret -ne 0 ]; then exit $ret; fi;

    # leaving LLK optimization for a bit

    # Old generate headers
#   txl -q ${TxlDir} ${TmpDir}/"$filename"_optk.scl5 07GenerateHeader.txl ${GenFlags} > ${TmpDir}/"$filename"_hdrs_unsorted.scl5
#   txl -q ${TxlDir} ${TmpDir}/"$filename"_hdrs_unsorted.scl5 08SortHeader.txl > ${OutDir}/"$filename"_Generated.h

    # New generate headers
   txl -q ${TxlDir} ${TmpDir}/"$filename"_opt1.scl5 07GenerateHeader.txl ${GenFlags} > ${OutDir}/"$filename"_Definitions.h
    ret=$?; if [ $ret -ne 0 ]; then exit $ret; fi;

    # generate code
    txl -q -s 500 ${TxlDir} ${TmpDir}/"$filename"_opt1.scl5 09GenerateSource.txl - ${CodeGenFlags} > ${OutDir}/"$filename"_Generated.c
    ret=$?; if [ $ret -ne 0 ]; then exit $ret; fi;

    txl -q -s 500 ${TxlDir} ${TmpDir}/"$filename"_opt1.scl5 10GenerateSerial.txl - ${CodeGenFlags} > ${OutDir}/"$filename"_Serialize.c
    ret=$?; if [ $ret -ne 0 ]; then exit $ret; fi;
    grep '^SerializeBuffer.*;$' ${OutDir}/"$filename"_Serialize.c > ${OutDir}/"$filename"_Serialize.h

    txl -q -s 500 ${TxlDir} ${TmpDir}/"$filename"_opt1.scl5 11GeneratePrint.txl - ${CodeGenFlags} > ${OutDir}/"$filename"_Print.c
    ret=$?; if [ $ret -ne 0 ]; then exit $ret; fi;
    grep '^void.*;$' ${OutDir}/"$filename"_Print.c > ${OutDir}/"$filename"_Print.h
done

# do exports check last, code is already
# generated, but its like a linker error
# need to ensure all .exports files are created
# before checking.

for file in ${InDir}/*.scl5
do
    #echo $file

    fullfilename=`basename -- "$file"`
    filename="${fullfilename%.*}"

    echo Checking Imports for "$filename"
    txl -q ${TxlDir} ${TmpDir}/"$filename"_ref.scl5 03CheckImports.txl > /dev/null
    ret=$?; if [ $ret -ne 0 ]; then exit $ret; fi;
done

if [[ "$Copy" == "Yes" ]]
then
   echo "Copying generated files to ${BuildDir}"
   cp "${OutDir}"/* "${BuildDir}"/
fi
