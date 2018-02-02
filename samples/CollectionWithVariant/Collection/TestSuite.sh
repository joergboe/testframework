
#--variantList='success failure skip error'

function testPreparation {
	if [[ "$TTRO_variantSuite" == "success" ]]; then #show this in the first variant only
		cat <<-EOF
		********************************************************************************
		********************************************************************************
		This sample demonstrates the execution of a single test case
		in a test collection with 4 variants
		The test case returns success in the first variant, failure in the second variant.
		It is skipped in the third anr returns error in the last variant
		*********************************************************************************
		*********************************************************************************
	
		Press enter to continue:
		EOF
		read
	fi
	return 0
}
