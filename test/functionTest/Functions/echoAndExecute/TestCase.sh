#--variantList='noParm emptyCommand true false simpleCommands1 simpleCommands2 noParmCheck emptyCommandCheck trueCheck falseCheck simpleCommands1Check simpleCommands2Check'

checkedCase=''
if [[ $TTRO_variantCase == *Check ]]; then
	checkedCase='true'
fi

function expect3Params {
	echo "expect3Params number of params=$#"
	echo "expect3Params \$1='$1' \$2='$2' \$3='$3'"
	if [[ $# -ne 3 ]]; then
		printError "Unexpected number of params"
		setFailure "Unexpected number of params"
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
		noParm*)
			if [[ -n $checkedCase ]]; then
				if echoAndExecute; then echo true; else setFailure "failure in $TTRO_variantCase"; fi
			else
				echoAndExecute
			fi;;
		emptyCommand*)
			if [[ -n $checkedCase ]]; then
				if echoAndExecute ''; then echo true; else setFailure "failure in $TTRO_variantCase"; fi
			else
				echoAndExecute ''
			fi;;
		true*)
			if [[ -n $checkedCase ]]; then
				if echoAndExecute 'returnSucc'; then echo true; else setFailure "failure in $TTRO_variantCase"; fi
			else
				echoAndExecute 'returnSucc'
			fi;;
		false*)
			if [[ -n $checkedCase ]]; then
				if echoAndExecute 'returnFail'; then echo true; else setFailure "failure in $TTRO_variantCase"; fi
			else
				echoAndExecute 'returnFail'
			fi;;
		simpleCommands1*)
			var="Command2"
			if [[ -n $checkedCase ]]; then
				if echoAndExecute 'expect3Params' 'Command1' "$var" '$var'; then echo true; else setFailure "failure in $TTRO_variantCase"; fi
			else
				echoAndExecute 'expect3Params' 'Command1' "$var" '$var'
			fi;;
		simpleCommands2*)
			var=''
			if [[ -n $checkedCase ]]; then
				if echoAndExecute 'expect3Params' 'Command1' "$var" ''; then echo true; else setFailure "failure in $TTRO_variantCase"; fi
			else
				echoAndExecute 'expect3Params' 'Command1' "$var" ''
			fi;;
		*)
			printErrorAndExit "Wrong variant '$TTRO_variantCase'" $errRt
	esac
}