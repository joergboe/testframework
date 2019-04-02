# Submission test for Streams
#--variantList='submitJob submitJobWithParam submitJobAndIntercept submitJobInterceptAndSuccess submitJobLogAndIntercept doubleJobCancel'
PREPS=( 'echo "${explainVariants[$TTRO_variantCase]}"' 'copyOnly' 'splCompile' )
STEPS='mySubmit checkJobNo waitForFin cancelJob myCancelJob2 myEvaluate'
FINS='cancelJob'

declare -A explainVariants=( \
	['submitJob']="Submit a job with a simple submit" \
	['submitJobWithParam']="Submit a job with submission time parameters" \
	['submitJobAndIntercept']="Submit a job guarded" \
	['submitJobInterceptAndSuccess']="Submit a job and expect a successful submission" \
	['submitJobLogAndIntercept']="Submit a job guarded and provide job output as evaluation file" \
	['doubleJobCancel']="Submit a job and cancel job twice" \
)

myEvaluate() {
	if ! linewisePatternMatch "$TT_dataDir/Tuples" '' '*http*://httpbin.org/get*'; then
		setFailure 'No match found'
	fi
}

mySubmit() {
	case $TTRO_variantCase in
	submitJob|doubleJobCancel)
		submitJob
		echo "-------- TTTT_jobno=$TTTT_jobno";;
	submitJobWithParam)
		submitJob -P 'aparam=bla bla'
		echo "-------- TTTT_jobno=$TTTT_jobno";;
	submitJobAndIntercept)
		submitJobAndIntercept
		echo "-------- TTTT_jobno=$TTTT_jobno"
		echo "-------- TTTT_result=$TTTT_result";;
	submitJobInterceptAndSuccess)
		submitJobInterceptAndSuccess
		echo "-------- TTTT_jobno=$TTTT_jobno"
		echo "-------- TTTT_result=$TTTT_result";;
	submitJobLogAndIntercept)
		submitJobLogAndIntercept
		echo "-------- TTTT_jobno=$TTTT_jobno"
		echo "-------- TTTT_result=$TTTT_result"
		echo "--------"
		cat "$TT_evaluationFile";;
	esac
}

myCancelJob2() {
	if [[ $TTRO_variantCase == 'doubleJobCancel' ]]; then
		echo "-------- TTTT_jobno=$TTTT_jobno"
		echo "--------- and now one surplus cancel job"
		cancelJob
	fi
}
