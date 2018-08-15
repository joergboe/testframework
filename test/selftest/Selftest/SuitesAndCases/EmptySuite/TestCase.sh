#--variantCount=4

PREPS=copyAndModifyTestCollection
STEPS='getOptions runRunTTF myEvaluate'

declare -a options=( '--noprompt --no-browser' '-j 1 --noprompt --no-browser' '-j 1 -v --noprompt --no-browser' '-j 1 -v -d --noprompt --no-browser' )

function getOptions {
	TT_runOptions="${options[$TTRO_variantCase]}"
}

function myEvaluate {
	linewisePatternMatchInterceptAndSuccess './STDERROUT1.log' 'true'\
	                          '*\*\*\*\*\* cases  executed=0 failures=0 errors=0 skipped=0'\
	                          '*\*\*\*\*\* suites executed=1 errors=0 skipped=0'
	return 0
}
