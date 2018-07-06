#Here we use a function for the test case
# execution
function testStep {
	echo "$FUNCNAME Demonstrate a successful test execution"
	echo "Guard a function that maiy fail during test preparation, execution of finalization"
	if myFailedFunction; then
		echo "Function return success"
	else
		echo "Function returned failure $?"
	fi
	return 0
}

function myFailedFunction {
	echo "Hello $FUNCNAME this function returns an error"
	return 1
}