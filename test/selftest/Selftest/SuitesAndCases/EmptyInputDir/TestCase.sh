#--variantCount=4

PREPS='copyAndModifyTestCollection'
STEPS='executeCase myEvaluate'

declare -a options=( '--noprompt' '--noprompt -j 1' '--noprompt -j 1 -v' '--noprompt -j 1 -v -d' )

function executeCase {
	echo $TTRO_inputDirCase
	if echoAndExecute $TTPN_binDir/runTTF --directory "$TTRO_inputDirCase/testCollection" ${options[$TTRO_variantCase]} 2>&1 | tee STDERROUT1.log; then
		return 0
	else
		return $errTestFail
	fi
}

function myEvaluate {
	if ! linewisePatternMatch './STDERROUT1.log' 'true'\
		'\*\*\*\*\* suite variants=0 errors during suite execution=0'\
		'\*\*\*\*\* case variants=0 skipped=0 failures=0 errors=0'; then

		#if ! linewisePatternMatch './STDERROUT1.log' '' '*ERROR: No test collection file *TestCollection.sh found*'; then
		failureOccurred='true'
	fi
	return 0
}