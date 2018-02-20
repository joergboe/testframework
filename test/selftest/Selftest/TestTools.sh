############################################
# Tools for the selftest collection
############################################

TTRO_help_copyAndModifyTestCollection='
#	This function copies source dir into dest dir
#	and renames file TTestCase.sh into TestCase.sh ..'
function copyAndModifyTestCollection {
	if [[ $# -ne 0 ]]; then printErrorAndExit "$FUNCNAME invalid no of params. Number of Params is $#" $errRt; fi
	isDebug && printDebug "$FUNCNAME $*"
	local sourceDir="$TTRO_inputDirCase/testCollection"
	local destDir="$TTRO_workDirCase"
	if [[ -d $destDir ]]; then
		cp -rp "$sourceDir" "$destDir"
		local x
		for x in $TEST_PROPERTIES $TEST_SUITE_FILE $TEST_CASE_FILE; do
			renameInSubdirs "$destDir/testCollection" "T$x" "$x"
		done
	fi
}

TTRO_help_runRunTTF='
# Execute the test freamework with input directory testCollection intercept error
#	TT_runOptions - additional options
#	TT_caseList - the case list
#	TTexpectedResult - the expected result code a number or X when to be ignored'
function runRunTTF {
	isDebug && printDebug "$FUNCNAME $*"
	local result
	if echoAndExecute $TTPN_binDir/runTTF --directory "$TTRO_workDirCase/testCollection" $TT_runOptions $TT_caseList 2>&1 | tee STDERROUT1.log; then
		result=0
	else
		result=$?
	fi
	if [[ $TT_expectResult -eq 0 ]]; then
		if [[ $result -eq 0 ]]; then
			return 0
		else
			printError "result is $result. Expected is $TT_expectResult"
			failureOccurred='true'
		fi
	elif [[ $TT_expectResult == 'X' ]]; then
		if [[ $result -ne 0 ]]; then
			return 0
		else
			printWarning "result is $result. Expected is $TT_expectResult"
			return 0
		fi
	else
		if [[ $TT_expectResult -eq $result ]]; then
			return 0
		else
			printError "result is $result. Expected is $TT_expectResult"
			failureOccurred='true'
		fi
	fi
}

#define required variables default
setVar 'TT_expectResult' 0
setVar 'TT_runOptions' ''
setVar 'TT_caseList' ''
