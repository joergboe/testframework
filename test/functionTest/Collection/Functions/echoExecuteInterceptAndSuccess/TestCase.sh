#--variantList='noParm emptyCommand wrongCommand succ fails simpleCommands1Succ simpleCommands2Succ simpleCommands27'

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
			echoExecuteInterceptAndSuccess;;
		emptyCommand)
			echoExecuteInterceptAndSuccess '';;
		wrongCommand)
			echoExecuteInterceptAndSuccess "bxbxbx"
			if [[ $TTTT_result -ne 127 ]]; then
				setFailure "returncode is $TTTT_result and not 0"
			fi;;
		succ)
			echoExecuteInterceptAndSuccess 'returnSucc'
			if [[ $TTTT_result -ne 0 ]]; then
				setFailure "returncode is $TTTT_result and not 0"
			fi;;
		fails)
			echoExecuteInterceptAndSuccess 'returnFail'
			if [[ $TTTT_result -ne 1 ]]; then
				setFailure "returncode is $TTTT_result and not 1"
			fi;;
		simpleCommands1Succ)
			var="Command2"
			echoExecuteInterceptAndSuccess 'expect3Params' 'Command1' "$var" '$var'
			if [[ $TTTT_result -ne 0 ]]; then
				setFailure "returncode is $TTTT_result and not 0"
			fi;;
		simpleCommands2Succ)
			var=''
			echoExecuteInterceptAndSuccess 'expect3Params' 'Command1' "$var" ''
			if [[ $TTTT_result -ne 0 ]]; then
				setFailure "returncode is $TTTT_result and not 0"
			fi;;
		simpleCommands27)
			var=''
			echoExecuteInterceptAndSuccess 'expect3Params' 'special' "$var" ''
			if [[ $TTTT_result -ne 27 ]]; then
				setFailure "returncode is $TTTT_result and not 27"
			fi;;
		*)
			printErrorAndExit "Wrong variant '$TTRO_variantCase'" $errRt
	esac
}