#--variantList='success failure failureexit error scripterror skip'

#Declare test finalization array and call function with parameter
FINS=( "myTestFin $TTRO_variantCase" )

#Initialization handle the skip case
if [[ "$TTRO_variantCase" == "skip" ]]; then
	setVar 'TTPN_skip' 'true'
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
		failure)
			failureOccurred='true'
			return 0 ;;
		failureexit)
			failureExit ;;
		error)
			return 1 ;;
		scripterror)
			executewrongcommand ;;
	esac
}

# Demo of test finalization function
function myTestFin {
	echo "----- $FUNCNAME $1 -----"
}