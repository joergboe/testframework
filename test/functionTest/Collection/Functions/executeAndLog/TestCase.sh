#--variantList='noParm emptyCommand expectSucc expectError simpleCommands1Succ simpleCommands2Succ simpleCommands27'

checkedCase=''
if [[ $TTRO_variantCase == *Check ]]; then
	checkedCase='true'
fi

function expect3Params {
	echo "expect3Params number of params=$#"
	echo "expect3Params \$1='$1' \$2='$2' \$3='$3'"
	if [[ $# -ne 3 ]]; then
		printError "$FUNCNAME Unexpected number of params $#"
		setFailure "$FUNCNAME Unexpected number of params $#"
	fi
	if [[ $1 == 'special' ]]; then
		return 27
	else
		return 0
	fi
}

function returnSucc {
	echo "returnSucc"
	return 0
}

function returnFail {
	echo "returnFail"
	return 1
}

function testStep {
	case "$TTRO_variantCase" in
		noParm)
			executeAndLog;;
		emptyCommand)
			executeAndLog ''
			if [[ $TTTT_result -ne 127 ]]; then
				setFailure "returncode is $TTTT_result and not 127"
			fi;;
		expectSucc)
			executeAndLog 'returnSucc'
			if [[ $TTTT_result -ne 0 ]]; then
				setFailure "returncode is $TTTT_result and not 0"
			fi
			if ! linewisePatternMatch "$TT_evaluationFile" '' 'returnSucc*'; then setFailure; fi;;
		expectError)
			executeAndLog 'returnFail'
			if [[ $TTTT_result -ne 1 ]]; then
				setFailure "returncode is $TTTT_result and not 1"
			fi
			if ! linewisePatternMatch "$TT_evaluationFile" '' 'returnFail*'; then setFailure; fi;;
		simpleCommands1Succ)
			var="Command2"
			executeAndLog 'expect3Params' 'Command1' "\$var $var" '$var '
			if [[ $TTTT_result -ne 0 ]]; then
				setFailure "returncode is $TTTT_result and not 0"
			fi
			if ! linewisePatternMatch "$TT_evaluationFile" '' 'expect3Params*'; then setFailure; fi;;
		simpleCommands2Succ)
			var=''
			executeAndLog 'expect3Params' 'Command1' "$var" ''
			if [[ $TTTT_result -ne 0 ]]; then
				setFailure "returncode is $TTTT_result and not 0"
			fi
			if ! linewisePatternMatch "$TT_evaluationFile" '' 'expect3Params*'; then setFailure; fi;;
		simpleCommands27)
			var=''
			executeAndLog 'expect3Params' 'special' "$var" ''
			if [[ $TTTT_result -ne 27 ]]; then
				setFailure "returncode is $TTTT_result and not 27"
			fi
			if ! linewisePatternMatch "$TT_evaluationFile" '' 'expect3Params*'; then setFailure; fi;;
		*)
			printErrorAndExit "Wrong variant '$TTRO_variantCase'" $errRt
	esac
}