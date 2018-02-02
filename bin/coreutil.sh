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
	local suiteNestingPath=''
	local suiteNestingString=''
	if [[ $1 -ne 0 ]]; then
		if [[ -z $4 ]]; then
			suiteNestingPath+="${suite}"
		else
			suiteNestingPath+="/${suite}"
		fi
		if [[ -z $5 ]]; then
			suiteNestingString="$suite"
		else
			suiteNestingString="::$suite"
		fi
	fi
	if [[ -n $2 ]]; then
		suiteNestingString+=":$2"
	fi
	if [[ -z ${executeSuite[$1]} ]]; then
		isDebug && printDebug "$FUNCNAME: skip empty suite $suitePath: variant='$2'"
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

	# count execute suites
	if [[ $1 -ne 0 ]]; then
		suiteVariants=$((suiteVariants+1))
		builtin echo "$suiteNestingString" >> "${6}/SUITE_VARIANT_LIST"
	fi

	#execute suite variant
	local result=0
	if "${TTRO_scriptDir}/suite.sh" "$1" "$2" "${sworkdir}" "$nestingLevel" "$suiteNestingPath" "$suiteNestingString" 2>&1 | tee -i "${sworkdir}/${TEST_LOG}"; then
		result=0;
	else
		result=$?
		if [[ $result -eq $errSigint ]]; then
			printWarning "Set SIGINT Execution of suite ${suite} variant $2 ended with result=$result"
			interruptReceived="true"
		else
			printError "Execution of suite ${suite} variant $2 ended with result=$result"
			suiteErrors=$(( suiteErrors + 1))
			builtin echo "$suiteNestingString" >> "${6}/SUITE_ERROR_LIST"
		fi
	fi
	
	#read result lists and append results to the own list
	local x
	if [[ $1 -ne 0 ]]; then
		for x in VARIANT SUCCESS SKIP FAILURE ERROR SUITE_ERROR SUITE_VARIANT; do
			local inputFileName="${sworkdir}/${x}_LIST"
			local outputFileName="${6}/${x}_LIST"
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
