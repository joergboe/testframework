#--variantList='step step2 prep'

echo "Variant step demonstrate an failed test case step with a function that returns a value not equal zero"
echo "Variant step2 demonstrate an failed test case step with an external command that returns a value not equal zero"
echo "Variant prep demonstrates an failure during test preparation"
echo "Both variants execute finally the testFinalization function"

PREPS='myprep'
STEPS='mytest'
FINS=( 'echo "----- $FUNCNAME Execute finalization of the test step -----"' )

myprep() {
	if [[ "$TTRO_variantCase" == "prep" ]]; then
		echoAndExecute myFailedFunction
	fi
}

mytest() {
	echo "----- Guard a function or command that may fail $FUNCNAME -----"
	if myFailedFunction; then
		echo "----- The called function return success -----"
	else
		echo "----- The called function returned failure code $? -----"
	fi
	echo "----- If this function not guarded, the test case exits -----"
	if [[ "$TTRO_variantCase" == "step" ]]; then
		echoAndExecute myFailedFunction
	fi
	if [[ "$TTRO_variantCase" == "step2" ]]; then
		/bin/false
	fi
	#this statement is not reached
	echo "*********** This must not be seen ********************************"
	return 0
}

myFailedFunction() {
	echo "----- Hello $FUNCNAME this function returns an error -----"
	return 55
}