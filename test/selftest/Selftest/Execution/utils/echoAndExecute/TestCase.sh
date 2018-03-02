#--variantList='noParm emptyCommand true false simpleCommands1 simpleCommands2 noParmCheck emptyCommandCheck trueCheck falseCheck simpleCommands1Check simpleCommands2Check'

PREPS='copyAndModifyTestCollection'
STEPS="setExpections runRunTTF checkResults"

function setExpections {
	TT_suitesExecuted=0
	TT_casesExecuted=1
	case "$TTRO_variantCase" in
	noParm|emptyCommand|false|noParmCheck|emptyCommandCheck)
		echo "Variant $TTRO_variantCase"
		TT_expectResult=$errTestError
		TT_casesError=1;;
	falseCheck)
		echo "Variant $TTRO_variantCase"
		TT_expectResult=$errTestFail
		TT_casesFailed=1;;
	true|simpleCommands1|simpleCommands2|trueCheck|simpleCommands1Check|simpleCommands2Check)
		echo "Variant $TTRO_variantCase";;
	*)
		printErrorAndExit "Wrong case variant $TTRO_variantCase" $errRt;;
	esac
	
}