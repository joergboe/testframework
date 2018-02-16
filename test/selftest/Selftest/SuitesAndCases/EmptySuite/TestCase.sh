#--variantCount=4

PREPS=copyAndModifyTestCollection
STEPS='getOptions runRunTTF myEvaluate'

declare -a options=( '--noprompt' '-j 1 --noprompt' '-j 1 -v --noprompt' '-j 1 -v -d --noprompt' )

function getOptions {
	TT_runOptions="${options[$TTRO_variantCase]}"
}

function myEvaluate {
	if ! linewisePatternMatch './STDERROUT1.log' 'true'\
	                          '*\*\*\*\*\* cases  executed=0 skipped=0 failures=0 errors=0'\
	                          '*\*\*\*\*\* suites executed=1 skipped=0 errors=0'; then
		failureOccurred='true'
	fi
	return 0
}
