#--variantList='failure error'

# Variant failure demonstrate an failed test case
# Variant error demonstrates an failure during test preparation
# which is turend into an error
# Both variants execute finally the testFinalization function
testStep() {
	if [[ "$TTRO_variantCase" == "failure" ]]; then
		echo "----- Execute test and fail -----"
		setFailure "CUSTOM FAILURE"
	fi
}

testPreparation() {
	if [[ "$TTRO_variantCase" == "error" ]]; then
		echo "----- Execute test and fail -----"
		setFailure "CUSTOM FAILURE"
	fi
}

# Demonstrate the execution of the finalization function
testFinalization() {
	echo "----- $FUNCNAME Execute finalization of the test step -----"
}
