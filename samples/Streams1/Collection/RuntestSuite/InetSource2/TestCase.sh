# Submission test for Streams
#--variantList='submitJob submitJobWithParam submitJobAndIntercept submitJobInterceptAndSuccess submitJobLogAndIntercept'
PREPS='copyOnly splCompile'
STEPS='mySubmit checkJobNo waitForFin myEvaluate'
FINS='cancelJob'

function myEvaluate {
	if ! linewisePatternMatch "$TT_dataDir/Tuples" '' '*http://httpbin.org/get*'; then
		setFailure 'No match found'
	fi
}

function mySubmit {
	case $TTRO_variantCase in
	submitJob)
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
		cat "$TT_evaluationFile"
		echo "--------"
		echo "-------- one surplus job cancel"
		cancelJob;;
	esac
}