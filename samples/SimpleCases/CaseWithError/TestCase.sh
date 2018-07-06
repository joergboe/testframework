STEPS=( 'mytest' )
FINS='mytestfin'

# Demonstrate the execution of the finalization function
function mytestfin {
	echo "----- $FUNCNAME Execute finalization of the test step -----"
}

function mytest {
	echo "----- Guard a function or command that may fail $FUNCNAME -----"
	if myFailedFunction; then
		echo "----- The called function return success -----"
	else
		echo "----- The called function returned failure code $? -----"
	fi
	echo "----- If this function not guarded, the test case exits -----"
	myFailedFunction
	#this statement is nopt reached
	return 0
}

function myFailedFunction {
	echo "----- Hello $FUNCNAME this function returns an error -----"
	return 55
}