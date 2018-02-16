#
# function to execute the variants of suites
# $1 the suite index to execute
# $2 is the variant to execute
# $3 nesting level of suite (parent)
# $4 the chain of suite names delim / (parent)
# $5 the chain of suite string including variants delim :: : (parent value)
# $6 parent sworkdir
# expect suiteVariants suiteErrors
function exeSuite {
	isDebug && printDebug "******* $FUNCNAME $*"
	#local suiteIndex="$1"
	#local suiteVariant="$2"
	local suite="${suitesName[$1]}"
	local suitePath="${suitesPath[$1]}"
	local nestingLevel=$(($3+1))
	local suiteNestingPath="$4"
	local suiteNestingString="$5"
	if [[ $1 -ne 0 ]]; then
		if [[ -z $suiteNestingPath ]]; then
			suiteNestingPath+="${suite}"
		else
			suiteNestingPath+="/${suite}"
		fi
		if [[ -z $suiteNestingString ]]; then
			suiteNestingString+="$suite"
		else
			suiteNestingString+="::$suite"
		fi
	fi
	if [[ -n $2 ]]; then
		suiteNestingString+=":$2"
	fi
	if [[ -z ${executeSuite[$1]} ]]; then
		isDebug && printDebug "$FUNCNAME: no execution of suite $suitePath: variant='$2'"
		return 0
	fi
	echo "**** START Suite: ${suite} variant='$2' in ${suitePath} *****************"
	#make and cleanup suite work dir
	local sworkdir="$TTRO_workDir"
	if [[ -n $suiteNestingPath ]]; then
		sworkdir="$sworkdir/$suiteNestingPath"
	fi
	if [[ -n $2 ]]; then
		sworkdir="$sworkdir/$2"
	fi
	isDebug && printDebug "suite workdir is $sworkdir"
	if [[ -e $sworkdir ]]; then
		if [[ $1 -ne 0 ]]; then
			rm -rf "$sworkdir"
		fi
	fi
	if [[ $1 -ne 0 ]]; then
		mkdir -p "$sworkdir"
	fi

	# count execute suites but do not count the root suite
	if [[ $nestingLevel -gt 0 ]]; then
		suiteVariants=$((suiteVariants+1))
		builtin echo "$suiteNestingString" >> "${6}/SUITE_EXECUTE"
	fi

	#execute suite variant
	local result=0
	if "${TTRO_scriptDir}/suite.sh" "$1" "$2" "${sworkdir}" "$nestingLevel" "$suiteNestingPath" "$suiteNestingString" 2>&1 | tee -i "${sworkdir}/${TEST_LOG}"; then
		result=0;
	else
		result=$?
		if [[ $result -eq $errSigint ]]; then
			printWarning "Set SIGINT Execution of suite ${suite} variant $2 ended with result=$result"
			interruptReceived=$((interruptReceived+1))
		else
			if [[ $nestingLevel -gt 0 ]]; then
				printError "Execution of suite ${suite} variant $2 ended with result=$result"
				suiteErrors=$(( suiteErrors + 1))
				builtin echo "$suiteNestingString" >> "${6}/SUITE_ERROR"
			else
				printErrorAndExit "Execution of root suite failed" $errRt
			fi
		fi
	fi
	
	#read result lists and append results to the own list
	local x
	if [[ $1 -ne 0 ]]; then
		for x in CASE_EXECUTE CASE_SKIP CASE_FAILURE CASE_ERROR CASE_SUCCESS SUITE_EXECUTE SUITE_SKIP SUITE_ERROR; do
			local inputFileName="${sworkdir}/${x}"
			local outputFileName="${6}/${x}"
			if [[ -e ${inputFileName} ]]; then
				{ while read; do
					if [[ $REPLY != \#* ]]; then
						echo "$REPLY" >> "$outputFileName"
					fi
				done } < "${inputFileName}"
			else
				printError "No result list $inputFileName in suite $sworkdir"
			fi
		done
	fi

	echo "**** END Suite: ${suite} variant='$2' in ${suitePath} *******************"
	return 0
} #/exeSuite

:
