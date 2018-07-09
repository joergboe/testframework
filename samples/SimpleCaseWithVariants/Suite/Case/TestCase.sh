 #-- variantList='success fail-ure \
 #-- error script_error skip'

#Declare test finalization array and call function with parameter
FINS=( "myTestFin $TTRO_variantCase" )

#Initialization handle the skip case
if [[ "$TTRO_variantCase" == "skip" ]]; then
	setSkip
fi

# Demonstrates an testcase which produces an
# - success
# - failure (set the variable failureOccurred)
# - failure (exit with errorExit)
# - error the function returns 1
# - error there is a script error
function testStep {
	echo "----- Excecute $FUNCNAME variant is : $TTRO_variantCase -----"
	case $TTRO_variantCase in
		success)
			return 0 ;;
		fail-ure)
			setFailure "user defined failure";;
		error)
			return 1 ;;
		script_error)
			executewrongcommand ;;
	esac
}

# Demo of test finalization function
function myTestFin {
	echo "----- $FUNCNAME $1 -----"
}