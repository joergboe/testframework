#Case preamble
#--variantCount=5

#Case definition
#demonstrate the usage of array test definitions
PREPS=( mySpecialCasePreparation )
FINS=( mySpecialCaseFinalization )
STEPS=( 'myTestStep 5' )

# Put here more fixed variables and properties for test case
setVar 'TTPRN_myProperty' "This is a sample property set in case"
setVar 'TTPRN_myCaseProperty' "This is a sample case property"

# Put here the global initialization steps
echo "********************************"
echo "global Case initialization steps"
echo "********************************"
if [[ $TTRO_variantCase -eq 4 ]]; then
	skip
fi

#Function definitions for test collections
function mySpecialCasePreparation {
	echo "**** $FUNCNAME ****"
	echo "TTPRN_myProperty =$TTPRN_myProperty"
	echo "TTPRN_myProperty2=$TTPRN_myProperty2"
	echo "TTPRN_mySuiteProperty=$TTPRN_mySuiteProperty"
	echo "TTPRN_myCaseProperty=$TTPRN_myCaseProperty"
}

function mySpecialCaseFinalization {
	echo " **** $FUNCNAME ****"
	echo "TTPRN_myProperty=$TTPRN_myProperty"
	echo "TTPRN_myProperty2=$TTPRN_myProperty2"
	echo "TTPRN_mySuiteProperty=$TTPRN_mySuiteProperty"
	echo "TTPRN_myCaseProperty=$TTPRN_myCaseProperty"
}

function myTestStep {
	echo " **** $FUNCNAME $1 ****"
	if [[ $TTRO_variantCase -eq 0 ]]; then
		echo "Variant 0 returns with success"
		return 0
	elif [[ $TTRO_variantCase -eq 1 ]]; then
		echo "Variant 1 calls failure exit"
		setFailure "CUSTOM ERROR"
	elif [[ $TTRO_variantCase -eq 2 ]]; then
		echo "Variant 2 returns with another failure return code"
		return 1
	else
		echo "Variant 3 activates a scrip error"
		dsdsdsfsdfafaerfearfafae
		return 0
	fi
}

