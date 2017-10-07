# Demonstrate an failed test case
# The failure is signalled with the function failureExit
function step {
	echo "----- Execute test -----"
	failureExit
}

# Demonstrate the execution of the finalization function
function fin {
	echo "----- $FUNCNAME Execute finalization of the test step -----"
}
