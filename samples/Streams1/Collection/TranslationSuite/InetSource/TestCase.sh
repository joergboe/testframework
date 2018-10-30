# Translation compile test for InetSource
#Case preamble
#--variantCount=2

#Case definition
PREPS=(
	'copyAndMorphSpl'
	'TT_mainComposite=com.ibm.streamsx.inet.sample::GetWeather'
)
STEPS='myCompile
	myEvaluate'

# A customized compiler step expects that the compilation
# is successfully for the first variant
# and fails in the all other variants
function myCompile {
	splCompileAndIntercept
	echo "######### myCompile result $TTTT_result"
	if [[ $TTRO_variantCase -eq 0 ]]; then
		if [[ $TTTT_result -eq 0 ]]; then
			return 0
		else
			setFailure "wrong result $TTTT_result"
		fi
	else
		if [[ $TTTT_result -eq 0 ]]; then
			setFailure "wrong result $TTTT_result"
		else
			return 0
		fi
	fi
}

# A customized evaluation
# does nothing in the first variant
# evaluates in the second variant
function myEvaluate {
	if [[ $TTRO_variantCase -eq 0 ]]; then
		return 0
	fi
	if ! linewisePatternMatch "$TT_evaluationFile" '' 'CDISP9164E ERROR: CDIST0200E: InetSource operator cannot be used inside a consistent region*'; then
		setFailure
	fi
}