#--variantCount=4

PREPS='copyAndModifyTestCollection'
STEPS='runRunTTF myEvaluate'

declare -a options=( '--noprompt' '-j 1 --noprompt' '-j 1 -v --noprompt' '-j 1 -v -d --noprompt' )

TT_runOptions="${options[${TTRO_variantCase}]}"
TT_expectResult=$errTestError

function myEvaluate {
	if ! linewisePatternMatch './STDERROUT1.log' 'true'\
			'*\*\*\*\*\* case variants=1 skipped=0 failures=0 errors=1'\
			'*\*\*\*\*\* suite variants=1 errors during suite execution=0'
			'*\*\*\*\*\* collection variants=1 errors during collection execution=0'; then
		failureOccurred='true'
	fi
	return 0
}
