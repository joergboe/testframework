# Put here more fixed variables and properties for test suite
#--TTPN_myProperty:=This is a sample property set in case
#--TTPN_myCaseProperty:=This is a sample case property

#Case definition
#demonstrate the usage of array test definitions
#--variantCount=5
TTRO_casePrepArr=( mySpecialCasePreparation )
TTRO_caseFinArr=( mySpecialCaseFinalization )
TTRO_caseStepArr=( 'myTestStep 5' )

# Put here the global initialization steps
echo "********************************"
echo "global Case initialization steps"
echo "********************************"
if [[ $TTRO_caseVariant -eq 4 ]]; then
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
	echo " **** $FUNCNAME $1 ****"
	if [[ $TTRO_caseVariant -eq 0 ]]; then
		echo "Variant 0 returns with success"
		return 0
	elif [[ $TTRO_caseVariant -eq 1 ]]; then
		echo "Variant 1 calls failure exit"
		failureExit
	elif [[ $TTRO_caseVariant -eq 2 ]]; then
		echo "Variant 2 returns with another failure return code"
		return 1
	else
		echo "Variant 3 activates a scrip error"
		dsdsdsfsdfafaerfearfafae
		return 0
	fi
}

