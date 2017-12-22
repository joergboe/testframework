if [[ "$TTRO_variant" == "skip" ]]; then
	TTPN_skip='true'
fi

function testStep {
	echo "------ $FUNCNAME execute test step in collection variant $TTRO_variant -------"
	case $TTRO_variant in
		success)
			return 0;;
		failure)
			failureExit;;
		error)
			return 1;;
	esac
}