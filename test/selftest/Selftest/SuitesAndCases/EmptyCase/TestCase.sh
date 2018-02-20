#--variantCount=4

PREPS='copyAndModifyTestCollection'
STEPS='runRunTTF myEvaluate'

declare -a options=( '--noprompt --no-browser' '-j 1 --noprompt --no-browser' '-j 1 -v --noprompt --no-browser' '-j 1 -v -d --noprompt --no-browser' )

TT_runOptions="${options[${TTRO_variantCase}]}"
TT_expectResult=$errTestError

function myEvaluate {
	if ! linewisePatternMatch './STDERROUT1.log' 'true'\
			'*\*\*\*\*\* cases  executed=1 skipped=0 failures=0 errors=1'\
			'*\*\*\*\*\* suites executed=1 skipped=0 errors=0'; then
		failureOccurred='true'
	fi
	return 0
}
