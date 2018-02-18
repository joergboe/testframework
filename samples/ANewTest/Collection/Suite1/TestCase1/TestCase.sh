#Case preamble
#--variantCount=5

#Case defintion
#Use list variables
PREPS=mySpecialCasePreparation
FINS=mySpecialCaseFinalization
STEPS=myTestStep

# Put here more fixed variables and properties for test case
setVar 'TTPN_myProperty' "This is a sample property set in case"
setVar 'TTPN_myCaseProperty' 'This is a sample case property'

# Put here the global initialization steps
echo "********************************"
echo "global Case initialization steps"
echo "********************************"
if [[ $TTRO_variantCase -eq 4 ]]; then
	setVar 'TTPN_skip' 'true'
fi

#Function definitions for test collections
function mySpecialCasePreparation {
	echo "**** $FUNCNAME ****"
	echo "TTPN_myProperty =$TTPN_myProperty"
	echo "TTPN_myProperty2=$TTPN_myProperty2"
	echo "TTPN_mySuiteProperty=$TTPN_mySuiteProperty"
	echo "TTPN_myCaseProperty=$TTPN_myCaseProperty"
}

function mySpecialCaseFinalization {
	echo " **** $FUNCNAME ****"
	echo "TTPN_myProperty=$TTPN_myProperty"
	echo "TTPN_myProperty2=$TTPN_myProperty2"
	echo "TTPN_mySuiteProperty=$TTPN_mySuiteProperty"
	echo "TTPN_myCaseProperty=$TTPN_myCaseProperty"
}

function myTestStep {
	echo " **** $FUNCNAME ****"
	if [[ $TTRO_variantCase -eq 0 ]]; then
		echo "Variant 0 returns with success"
		return 0
	elif [[ $TTRO_variantCase -eq 1 ]]; then
		echo "Variant 1 calls failure exit"
		failureExit
	elif [[ $TTRO_variantCase -eq 2 ]]; then
		echo "Variant 2 returns with another failure return code"
		return 1
	else
		echo "Variant 3 activates a scrip error"
		dsdsdsfsdfafaerfearfafae
		return 0
	fi
}
