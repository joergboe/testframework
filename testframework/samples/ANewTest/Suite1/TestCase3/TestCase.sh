# Put here more fixed variables and properties for test suite
#--TTPN_myProperty:=This is a sample property set in case
#--TTPN_myCaseProperty:=This is a sample case property

#Case definition
#demonstrate the usage of test definitions with functions
#--variantCount=5

# Put here the global initialization steps
echo "********************************"
echo "global Case initialization steps"
echo "********************************"
if [[ $TTRO_caseVariant -eq 4 ]]; then
	setVar 'TTPN_skip' 'true'
fi


#Function definitions for test collections
function testPreparation {
	echo "**** $FUNCNAME ****"
	echo "TTPN_myProperty =$TTPN_myProperty"
	echo "TTPN_myProperty2=$TTPN_myProperty2"
	echo "TTPN_mySuiteProperty=$TTPN_mySuiteProperty"
	echo "TTPN_myCaseProperty=$TTPN_myCaseProperty"
}

function testFinalization {
	echo " **** $FUNCNAME ****"
	echo "TTPN_myProperty=$TTPN_myProperty"
	echo "TTPN_myProperty2=$TTPN_myProperty2"
	echo "TTPN_mySuiteProperty=$TTPN_mySuiteProperty"
	echo "TTPN_myCaseProperty=$TTPN_myCaseProperty"
}

function testStep {
	echo " **** $FUNCNAME ****"
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

