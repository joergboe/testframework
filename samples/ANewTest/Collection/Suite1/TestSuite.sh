# Put here more fixed variables and properties for test suite
setVar 'TTPRN_myProperty' "This is a sample property set in suite"
setVar 'TTPRN_mySuiteProperty' "This is a sample suite property"

# Put here the suite initialization steps
echo "*********************************"
echo "global Suite initialization steps"
echo "*********************************"

#Suite test preparation steps
PREPS=(\
	'mySpecialSuitePreparation "$TTRO_variantSuite"' )

FINS=mySpecialSuiteFinalization


#Function definitions for test collections
function mySpecialSuitePreparation {
	echo "**** $FUNCNAME preparing variant '$1' ****"
	echo "TTPRN_myProperty =$TTPRN_myProperty"
	echo "TTPRN_myProperty2=$TTPRN_myProperty2"
	echo "TTPRN_mySuiteProperty=$TTPRN_mySuiteProperty"
}

function mySpecialSuiteFinalization {
	echo "**** $FUNCNAME ****"
	echo "TTPRN_myProperty=$TTPRN_myProperty"
	echo "TTPRN_myProperty2=$TTPRN_myProperty2"
	echo "TTPRN_mySuiteProperty=$TTPRN_mySuiteProperty"
}