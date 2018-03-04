# Demonstrate an failed test case
# The failure is signalled with the function failureExit
function testStep {
	echo "----- Execute test and fail -----"
	setFailure "CUSTOM FAILURE"
}

# Demonstrate the execution of the finalization function
function testFinalization {
	echo "----- $FUNCNAME Execute finalization of the test step -----"
}
