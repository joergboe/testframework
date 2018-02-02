if [[ "$TTRO_variantSuite" == "skip" ]]; then
	TTPN_skip='true'
fi

function testStep {
	echo "------ $FUNCNAME execute test step in suite variant $TTRO_variantSuite -------"
	case $TTRO_variantSuite in
		success)
			return 0;;
		failure)
			failureExit;;
		error)
			return 1;;
	esac
}