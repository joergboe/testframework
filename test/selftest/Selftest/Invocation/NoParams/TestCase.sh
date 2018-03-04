
STEPS='noParams myEvaluate'

function noParams {
	if $TTPRN_binDir/runTTF 2>&1 | tee STDERROUT1.log; then
		return $errTestFail
	else
		result=$?
		if [[ $result -ne $errInvocation ]]; then
			return $errTestFail
		else
			return 0
		fi
	fi
}

function myEvaluate {
	linewisePatternMatch './STDERROUT1.log' "" '*ERROR: No input directory specified*'
}