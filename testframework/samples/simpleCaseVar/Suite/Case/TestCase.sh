#--variantList:=success failure error scripterror

#Declare test finalization array and call function with parameter
testFin=( "myTestFin $TTRO_caseVariant" )

# Demonstrates an testcase which produces an
# - success
# - failure (set the variable failureOccurred)
# - error the function returns 1
# - error there is a script error
function testStep {
	echo "----- Excecute $FUNCNAME variant is : $TTRO_caseVariant -----"
	case $TTRO_caseVariant in
		success)
			return 0 ;;
		failure)
			failureOccurred='true'
			return 0 ;;
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