
#--variantList='success failure skip error skipSuite errorSuite'
if [[ $TTRO_variantSuite == 'skipSuite' ]]; then
	setSkip 'User defined skip reason'
fi

function testPreparation {
	if [[ "$TTRO_variantSuite" == "success" ]]; then #show this in the first variant only
		cat <<-EOF
		********************************************************************************
		********************************************************************************
		This sample demonstrates the execution of a single test case
		in a test suite with 4 variants
		The test case returns success in the first variant, failure in the second variant.
		It is skipped in the third anr returns error in the 4. variant
		The variant skipSuite skips the execuition of the whole suite
		The variant errorSuite simulates an error during test suite execution
		*********************************************************************************
		*********************************************************************************
	
		Press enter to continue:
		EOF
		read
	fi
	if [[ "$TTRO_variantSuite" == "errorSuite" ]]; then
		exit 55
	fi
	return 0
}
