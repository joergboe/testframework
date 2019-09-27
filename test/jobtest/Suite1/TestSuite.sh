setVar TTPR_timeout 30

PREPS=myPrep

myPrep() {
	echo "expected result is in parallel mode:"
	echo "executed=4 failures=0 errors=2 skipped=0"
	echo
	echo "in serial mode:"
	echo "executed=4 failures=0 errors=1 skipped=0"
	echo "if 'y' was pressed during execution of case Case0ReadFromConsole"
	echo
	promptYesNo
}