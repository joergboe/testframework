#--variantList='noDirs noDirsError noFiles find notFound wrongDirname fileNotReadable \
#--		checkTokenIsInDirs checkTokenIsInDirsFail checkTokenIsNotInDir scheckTokenIsNotInDirsFail'

testStep() {
	case "$TTRO_variantCase" in
	noDirs)
		if findTokenInDirs '' 'ERROR' '*.txt'; then
			setFailure "wrong result 0"
		else
			printInfo "Correct result WARNING expected"
		fi;;
	noDirsError)
		if findTokenInDirs 'true' 'ERROR' '*.txt'; then
			setFailure "wrong result 0, exit is expected"
		else
			setFailure "wrong result 0, exit is expected"
		fi;;
	noFiles)
		if findTokenInDirs '' 'ERROR' '*.xxx' "$TTRO_inputDirCase/d1" "$TTRO_inputDirCase/d2"; then
			setFailure "wrong result 0"
		else
			printInfo "Correct result, WARNING expected"
		fi;;
	find)
		if findTokenInDirs '' 'ERROR' '*.txt' "$TTRO_inputDirCase/d1" "$TTRO_inputDirCase/d2"; then
			printInfo "Correct result"
		else
			setFailure "wrong result 1"
		fi;;
	notFound)
		if findTokenInDirs '' 'ERROXR' '*.txt' "$TTRO_inputDirCase/d1" "$TTRO_inputDirCase/d2"; then
			setFailure "wrong result 0"
		else
			printInfo "Correct result"
		fi;;
	wrongDirname)
		if findTokenInDirs '' 'ERROXR' '*.txt' "$TTRO_inputDirCase/d1" "$TTRO_inputDirCase/d2" "$TTRO_inputDirCase/dx3"; then
			setFailure "wrong result 0, exit expected"
		else
			setFailure "wrong result 0, exit expected"
		fi;;
	fileNotReadable)
		echo "**** change file perms ***"
		chmod -r "$TTRO_inputDirCase/d3/f3.txt"
		if findTokenInDirs '' 'ERROXR' '*.txt' "$TTRO_inputDirCase/d1" "$TTRO_inputDirCase/d2" "$TTRO_inputDirCase/d3"; then
			setFailure "wrong result 0"
		else
			setFailure "wrong result 0"
		fi;;
	checkTokenIsInDirs)
		checkTokenIsInDirs '' 'ERROR' '*.txt' "$TTRO_inputDirCase/d1" "$TTRO_inputDirCase/d2"
		echo "*********** expect success ************";;
	checkTokenIsInDirsFail)
		checkTokenIsInDirs '' 'ERROXR' '*.txt' "$TTRO_inputDirCase/d1" "$TTRO_inputDirCase/d2"
		echo "*********** expect failure ************";;
	checkTokenIsNotInDir)
		checkTokenIsNotInDirs '' 'ERROXR' '*.txt' "$TTRO_inputDirCase/d1" "$TTRO_inputDirCase/d2"
		echo "*********** expect success ************";;
	scheckTokenIsNotInDirsFail)
		checkTokenIsNotInDirs '' 'ERROR' '*.txt' "$TTRO_inputDirCase/d1" "$TTRO_inputDirCase/d2"
		echo "*********** expect failure ************";;
	*)
		printErrorAndExit "Wrong case $TTRO_variantCase" $errRt;;
	esac
}

testFinalization() {
	if  [[ $TTRO_variantCase == fileNotReadable ]]; then
		echo "**** restore file perms ***"
		chmod +r "$TTRO_inputDirCase/d3/f3.txt"
	fi
}