#--variantList='noParm wrongCode emptyCommand expectSucc expectSuccFails expectError expectErrorFails simpleCommands1Succ simpleCommands2Succ simpleCommands27 simpleCommands27Fails'

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
			echoExecuteAndIntercept;;
		wrongCode)
			echoExecuteAndIntercept 'thisIsWrong' 'returnSucc';;
		emptyCommand)
			echoExecuteAndIntercept 'success' '';;
		expectSucc)
			echoExecuteAndIntercept 'success' 'returnSucc';;
		expectSuccFails)
			echoExecuteAndIntercept 'success' 'returnFail';;
		expectError)
			echoExecuteAndIntercept 'error' 'returnFail';;
		expectErrorFails)
			echoExecuteAndIntercept 'error' 'returnSucc';;
		simpleCommands1Succ)
			var="Command2"
			echoExecuteAndIntercept 'success' 'expect3Params' 'Command1' "$var" '$var';;
		simpleCommands2Succ)
			var=''
			echoExecuteAndIntercept 'success' 'expect3Params' 'Command1' "$var" '';;
		simpleCommands27)
			var=''
			echoExecuteAndIntercept '27' 'expect3Params' 'special' "$var" '';;
		simpleCommands27Fails)
			var=''
			echoExecuteAndIntercept '28' 'expect3Params' 'special' "$var" '';;
		*)
			printErrorAndExit "Wrong variant '$TTRO_variantCase'" $errRt
	esac
}