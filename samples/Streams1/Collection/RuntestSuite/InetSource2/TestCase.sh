# Translation compile test for InetSource

PREPS='copyOnly splCompile'
STEPS='submitJob checkJobNo waitForFin myEvaluate'
FINS='cancelJob'

function myEvaluate {
	if ! linewisePatternMatch "$TT_dataDir/Tuples" '' '*http://httpbin.org/get*'; then
		setFailure
	fi
}