#--variantCount=4

PREPS='copyAndModifyTestCollection'
STEPS=('TT_runOptions=${options[$TTRO_variantCase]}' 'runRunTTF myEvaluate')

declare -a options=( '--noprompt' '-j 1 --noprompt' '-j 1 -v --noprompt' '-j 1 -v -d --noprompt' )

function myEvaluate {
	if ! linewisePatternMatch './STDERROUT1.log' 'true'\
	            '*\*\*\*\*\* case variants=0 skipped=0 failures=0 errors=0'\
	            '*\*\*\*\*\* suite variants=0 errors during suite execution=0'
	            '*\*\*\*\*\* collection variants=1 errors during collection execution=0'; then
		ailureOccurred='true'
	fi
	return 0
}