setVar TTPR_timeout 30

PREPS=myPrep

myPrep() {
	echo "expected result is in parallel mode:"
	echo "executed=4 failures=0 errors=2 skipped=0"
	echo "Test case error for case Case0ReadFromConsole"
	echo "Test case error (timout) for case Case1EndlessSync"
	echo
	echo "in serial mode:"
	echo "executed=4 failures=0 errors=1 skipped=0"
	echo "if 'y' was pressed during execution of case Case0ReadFromConsole"
	echo "Test case error (timout) for case Case1EndlessSync"
	echo
	echo "Finally check wheter no job 'endless.sh' is running after execution"
	echo "of the test framework"
	promptYesNo
}