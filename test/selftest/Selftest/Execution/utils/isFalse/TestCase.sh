#--variantList='varNotExists varFalse varTrue'

PREPS='copyAndModifyTestCollection'
STEPS="setExpections runRunTTF checkResults"

function setExpections {
	TT_suitesExecuted=0
	TT_casesExecuted=1
	case "$TTRO_variantCase" in
	varNotExists)
		echo "Variant $TTRO_variantCase"
		TT_expectResult=$errTestError;
		TT_casesError=1;;
	varFalse)
		echo "Variant $TTRO_variantCase";;
	varTrue)
		echo "Variant $TTRO_variantCase";;
	*)
		printErrorAndExit "Wrong case variant $TTRO_variantCase" $errRt;;
	esac
	
}
