#Here the function for test case preparation: must succeed
testPreparation() {
	echo "$FUNCNAME"
	return 0
}

#Here we use a function for the test case execution
testStep() {
	echo "$FUNCNAME Demonstrate a successful test execution"
	echo "Guard a function that maiy fail during test preparation, execution of finalization"
	if myFailedFunction 55; then
		echo "Function return success"
	else
		echo "Function returned failure $?"
	fi
	echo "Or expect the failure of the function and evaluate the result code"
	echoExecuteAndIntercept myFailedFunction 56
	echo "Function returns $TTTT_result"
	echo "Or expect failure and store the output for furthere evaluation"
	executeLogAndError myFailedFunction 57
	echo "Function returns $TTTT_result"
	echo "The output is logged in file \$TT_evaluationFile=$TT_evaluationFile"
	cat "$TT_evaluationFile"
	return 0
}

#Here we use a function for the test case finalization
testFinalization() {
	echo "$FUNCNAME goes here! It should not faikl and it should not set failure conditions. But it may fail and it may set failures, which are ignored"
	echo $-
	setFailure "Failure to be ignored"
	return 1
}

myFailedFunction() {
	echo "Hello $FUNCNAME this function returns an $1 as return code"
	return $1
}