# Put here more fixed variables and properties for test suite
#--TTPN_myProperty:=This is a sample property set in suite
#--TTPN_mySuiteProperty:=This is a sample suite property

# Put here the suite initialization steps
echo "*********************************"
echo "global Suite initialization steps"
echo "*********************************"

#Suite test preparation steps
PREPS=(\
	'mySpecialSuitePreparation "$TTRO_suiteVariant"' )

FINS=mySpecialSuiteFinalization


#Function definitions for test collections
function mySpecialSuitePreparation {
	echo "**** $FUNCNAME preparing variant '$1' ****"
	echo "TTPN_myProperty =$TTPN_myProperty"
	echo "TTPN_myProperty2=$TTPN_myProperty2"
	echo "TTPN_mySuiteProperty=$TTPN_mySuiteProperty"
}

function mySpecialSuiteFinalization {
	echo "**** $FUNCNAME ****"
	echo "TTPN_myProperty=$TTPN_myProperty"
	echo "TTPN_myProperty2=$TTPN_myProperty2"
	echo "TTPN_mySuiteProperty=$TTPN_mySuiteProperty"
}