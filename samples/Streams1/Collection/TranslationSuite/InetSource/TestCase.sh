# Translation compile test for InetSource
#Case preamble
#--variantCount=2

#Case definition
setVar 'TTRO_prepsCase' 'copyAndTransformSpl'
setVar 'TTRO_stepsCase' 'myCompile myEvaluate'

# A customized compiler step expects that the compilation
# is successfully for the firs run
# and fails in the second run
function myCompile {
	TT_mainComposite='com.ibm.streamsx.inet.sample::GetWeather'
	local result
	local rr
	compileAndIntercept
	echo "######### myCompile result $result"
	if [[ $TTRO_variantCase -eq 0 ]]; then
		if [[ $result -eq 0 ]]; then
			return 0
		else
			return $errTestFail
		fi
	else
		if [[ $result -eq 0 ]]; then
			return $errTestFail
		else
			return 0
		fi
	fi
}

# A customized evaluation
# does nothing in the firs run
# evaluates in the second step
function myEvaluate {
	if [[ $TTRO_variantCase -eq 0 ]]; then
		return 0
	fi
	if ! linewisePatternMatch "$TT_evaluationFile" '' 'CDISP9164E ERROR: CDIST0200E: InetSource operator cannot be used inside a consistent region*'; then
		failureOccurred='true'
	fi
}