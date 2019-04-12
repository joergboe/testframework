# Submission test for Streams
##--variantList='default noTuples noWin noFin allInOne allMarkerInOne sequence sequenceAllInOne'
#--variantList='default'
PREPS='copyAndMorphSpl'
STEPS='splCompile submitJobInterceptAndSuccess checkJobNo myWaitForFin cancelJobAndLog myEvaluate1 checkLogsNoError'
FINS='cancelJob'

myWaitForFin() {
	if [[ $TTRO_variantCase == 'noFin' ]]; then
		TT_waitForFileName="$TT_dataDir/WindowMarker"
		waitForFinAndHealth
		sleep 2
	elif [[ $TTRO_variantCase == 'allInOne' ]]; then
		TT_waitForFileName="$TT_dataDir/AllTuples"
		waitForFinAndHealth
		sleep 10
	elif [[ $TTRO_variantCase == 'sequenceAllInOne' ]]; then
		TT_waitForFileName="$TT_dataDir/AllTuples33"
		waitForFinAndHealth
		sleep 2
	elif [[ $TTRO_variantCase == 'sequence' ]]; then
		TT_waitForFileName="$TT_dataDir/FinalMarker33"
		waitForFinAndHealth
		sleep 2
	else
		waitForFinAndHealth
	fi
}

myEvaluate1() {
	ls -l "$TT_dataDir"
	local prefix="$TTRO_workDirCase/$TT_dataDir"
	case "$TTRO_variantCase" in
	default)
		local filenames='Tuples WindowMarker FinalMarker'
		checkAllFilesExist "$prefix" "$filenames"
		checkLineCount "$prefix/Tuples" 30
		checkLineCount "$prefix/WindowMarker" 3
		checkLineCount "$prefix/FinalMarker" 1;;
	noTuples)
		local filenames='WindowMarker FinalMarker'
		checkAllFilesExist "$prefix" "$filenames"
		checkLineCount "$prefix/WindowMarker" 3
		checkLineCount "$prefix/FinalMarker" 1;;
	noWin)
		local filenames='FinalMarker'
		checkAllFilesExist "$prefix" "$filenames"
		checkLineCount "$prefix/FinalMarker" 1;;
	noFin)
		local filenames='Tuples WindowMarker'
		checkAllFilesExist "$prefix" "$filenames"
		checkLineCount "$prefix/Tuples" 30
		checkLineCount "$prefix/WindowMarker" 3;;
	allInOne)
		local filenames='AllTuples'
		checkAllFilesExist "$prefix" "$filenames"
		checkLineCount "$prefix/AllTuples" 34;;
	allMarkerInOne)
		local filenames='Tuples FinalMarker'
		checkAllFilesExist "$prefix" "$filenames"
		checkLineCount "$prefix/Tuples" 30
		checkLineCount "$prefix/FinalMarker" 4;;
	sequence)
		local filenumber=$(ls "$prefix" | wc -l)
		if [[ $filenumber -eq 34 ]]; then
			printInfo "Correct number of files found in datat dir : 34"
		else
			setFailure "Incorrect number of files found in datat dir : $filenumber"
		fi
		local x
		for x in $prefix/*; do
			checkLineCount "$x" 1
		done;;
	sequenceAllInOne)
		local filenumber=$(ls "$prefix" | wc -l)
		if [[ $filenumber -eq 34 ]]; then
			printInfo "Correct number of files found in datat dir : 34"
		else
			setFailure "Incorrect number of files found in datat dir : $filenumber"
		fi
		local x
		for x in $prefix/*; do
			checkLineCount "$x" 1
		done;;
	*)
		printErrorAndExit "Wrong variant $TTRO_variantCase" $errRt;;
	esac
}
