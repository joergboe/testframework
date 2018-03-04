if [[ "$TTRO_variantSuite" == "skip" ]]; then
	skip
fi

function testStep {
	echo "------ $FUNCNAME execute test step in suite variant $TTRO_variantSuite -------"
	case $TTRO_variantSuite in
		success)
			return 0;;
		failure)
			setFailure;;
		error)
			return 1;;
	esac
}