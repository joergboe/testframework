#--variantCount=4

PREPS='copyAndModifyTestCollection'
STEPS='executeCase myEvaluate'

declare -a options=( '--noprompt --no-browser' '--noprompt -j 1 --no-browser' '--noprompt -j 1 -v --no-browser' '--noprompt -j 1 -v -d --no-browser' )

function executeCase {
	echo $TTRO_inputDirCase
	if echoAndExecute $TTPRN_binDir/runTTF --directory "$TTRO_inputDirCase/testCollection" ${options[$TTRO_variantCase]} 2>&1 | tee STDERROUT1.log; then
		return 0
	else
		return $errTestFail
	fi
}

function myEvaluate {
	linewisePatternMatchInterceptAndSuccess './STDERROUT1.log' 'true'\
		'\*\*\*\*\* suites executed=0 errors=0 skipped=0'\
		'\*\*\*\*\* cases  executed=0 failures=0 errors=0 skipped=0'
	return 0
}