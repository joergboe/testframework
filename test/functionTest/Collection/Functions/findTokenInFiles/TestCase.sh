#--variantList='noFiles noFilesError find notFound wrongFilename \
#--			checkTokenIsInFiles checkTokenIsInFilesFailure checkTokenIsNotInFiles checkTokenIsNotInFilesFailure'

testStep() {
	case "$TTRO_variantCase" in
	noFiles)
		if findTokenInFiles '' 'ERROR'; then
			setFailure "wrong result 0"
		else
			printInfo "Correct result WARNING expected"
		fi;;
	noFilesError)
		if findTokenInFiles 'true' 'ERROR'; then
			setFailure "wrong result 0"
		else
			setFailure "wrong result 0"
		fi;;
	find)
		if findTokenInFiles '' 'ERROR' $TTRO_inputDirCase/f1 $TTRO_inputDirCase/f2; then
			printInfo "Correct result"
		else
			setFailure "wrong result 1"
		fi;;
	notFound)
		if findTokenInFiles '' 'ERROXR' $TTRO_inputDirCase/f1 $TTRO_inputDirCase/f2; then
			setFailure "wrong result 0"
		else
			printInfo "Correct result"
		fi;;
	wrongFilename)
		if findTokenInFiles '' 'ERROXR' $TTRO_inputDirCase/f1 $TTRO_inputDirCase/f2 $TTRO_inputDirCase/f3; then
			setFailure "wrong result 0"
		else
			setFailure "wrong result 0"
		fi;;
	checkTokenIsInFiles)
		checkTokenIsInFiles '' 'ERROR' $TTRO_inputDirCase/f1 $TTRO_inputDirCase/f2
		echo "************** expect success *********";;
	checkTokenIsInFilesFailure)
		checkTokenIsInFiles '' 'ERROXR' $TTRO_inputDirCase/f1 $TTRO_inputDirCase/f2
		echo "************** expect failure *********";;
	checkTokenIsNotInFiles)
		checkTokenIsNotInFiles '' 'ERROXR' $TTRO_inputDirCase/f1 $TTRO_inputDirCase/f2
		echo "************** expect success *********";;
	checkTokenIsNotInFilesFailure)
		checkTokenIsNotInFiles '' 'ERROR' $TTRO_inputDirCase/f1 $TTRO_inputDirCase/f2
		echo "************** expect failure *********";;
	*)
		printErrorAndExit "Wrong case $TTRO_variantCase" $errRt;;
	esac
}