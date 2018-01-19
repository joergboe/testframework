#####################################################
# Utilities for the main testframework script
#####################################################

#
# usage description
#
function usage {
	local command=${0##*/}
	cat <<-EOF

	usage: ${command} [option ..] [case ..];

	OPTIONS:
	-h|--help                : display this help
	--man                    : display man page
	--ref                    : display function reference. This function requires a specified input directory.
	-w|--workdir  VALUE      : The working directory. Here are all work files and results are stored. Default is ./${DEFAULT_WORKDIR} .
	-f|--flat                : Use flat working directory - does not include the date/time string into the workdir path
	--noprompt               : Do not prompt berfore an existing working directory is removed.
	-i|--directory VALUE     : The input directory - the test collection directory. There is no default. This option must be entered.
	-p|--properties VALUE    : This specifies the file with the global property values. Default is file $TEST_PROPERTIES in input directory.
	                           If this path is an relative path, it is expanded relative to the input directory.
	-t|--tools VALUE         : Includes (source) files with test tool scripts. This option can be given more than one time. This overwrites then
	                           TTRO_tools environment.
	-n|--no-checks           : The script omits the checkes for the streams environment and does not attempt to start domain/instance. Saves time
	-s|--skip-ignore         : If this option is given the ignore attribute of the cases are ignored
	-j|--threads VALUE       : The number of parallel test executions. (you have ${noCpus} (virtual) cores this is default)
	                           If the value is set to 1 no parallel execution is performed
	-l|--link                : Content found in data directoy are linked to workspace not copied (Set TTPN_link=true)
	--no-start               : Supress the execution of the start sequence (Set TTPN_noStart)
	--no-stop                : Supress the execution of tear stop sequencd (Set TTPN_noStop)
	-D value                 : Set the specified TT_-, TTRO_-, TTP_- or TTPN_- variable value (Use one of varname=value)
	-v|--verbose             : Be verbose to stdout
	-V|--version             : Print the version string
	-d|--debug               : Print debug information. Debug implies verbose.
	--bashhelp               : Print some hints for the use of bash
	
	
	case                     : The list of the testcases to execute. Each pattern must be composed in the form Suite::Case.
	                           For cases without Suite context use the form ::Case. Quoting * and ? characters.
	                           The matching cases are unconditionally executed. The skip attributes are ignored irrespective of the 
	                           --skip-ignore parameter.
	                           Where Suite and case are a pattern (like file glob)
	                           If the case list is omitted, all test suites/cases found in input directory are executed and the --skip-ignore
	                           parameter is evaluated.
	
	Return Status:
	0     : Test Success
	1     : fatal error ( failed command etc. )
	${errTestFail}    : at least one test fails ( \${errTestFail} )
	${errTestError}    : at least one test error ( \${errTestError} )
	${errVersion}    : Streams version is not supported ( \${errVersion} )
	${errSuiteError}    : Error during suite execution ( \${errSuiteError} )
	${errCollError}    : Error during collection execution ( \${errCollError} )
	${errInvocation}    : Invocation error ( \${errInvocation} )
	${errScript}    : Script error ( \${errScript} )
	${errRt}    : Runntime error ( \${errRt} )
	${errEnv}    : Invalid environment ( \${errEnv} )
	${errSigint}   : SIGINT received ( \${errSigint} )
	EOF
}

#
# helpers for get parameters
#
function missOptionArg {
	printError "Missing Option argument $1 \n\n"
	usage;
	exit ${errInvocation}
}
function duplicateOption {
	printError "Duplicate option $1 \n\n"
	usage
	exit ${errInvocation}
}
function fewArgs {
	printError "To few arguments!!!\n\n"
	usage;
	exit ${errInvocation}
}
function optionInParamSection {
	printError "Option argument $1 must be placed before cases section\n\n"
	usage;
	exit ${errInvocation}
}

# Scan scan directory structure and search for suites
# $1 the directory to scan
# $2 the index of the current suite
#
# Function uses the global variables:
# suitesIndex: It increments suitesIndex once the enterd directory is a suitesIndex
#              suitesIndex=0 indicates the dummy suite
# suitesPath: The array with the absolute pathes of the suites index=0 is the dunmy suite
# level0Suites: The space separated list with the root suite indexes
# childSuites: The global map: key is the index of the suite and value is the space separated list of child suite indexes
# childCases:  The global map: key is the index of the suite and value is the space separated list of (child) case indexes 
# casesIndex: The global index of the next cases
# casesPath:  The array with the absolute pathes to the cases
#
# Function uses the variables of the actual parent
# childSuitesIndex: the index of the next child suite in the current suite
# 
function scan {
	isDebug && printDebug "******* $FUNCNAME dir to scan='$1' index of the parent suite $2 path of the parent suite=${suitesPath[$2]}"
	local parentSuite="$2"
	local mypath
	local dirlist=()
	local isSuite=''
	local isCase=''
	local mySuiteIndex="$2"
	local parentPath="${suitesPath[$parentSuite]}"
	if [[ $1 == *[[:space:]]* ]]; then
		printErrorAndExit "Pathes must not have spaces wrong component $1" ${errRt}
	fi
	for mypath in $1/*; do
		isDebug && printDebug "'$mypath'"
		local filename="${mypath##*/}"
		local mybase="${mypath%/*}"
		isDebug && printDebug "filename='$filename' mybase='$mybase'"
		if [[ -d $mypath ]]; then
			dirlist+=("$mypath")
		else
			if [[ $filename == $TEST_SUITE_FILE ]]; then
				isSuite='true'
				suitesPath[$suitesIndex]="$mybase"
				childSuitesIndex=$((childSuitesIndex+1))
				childSuites[$parentSuite]="${childSuites[$parentSuite]}$suitesIndex "
				childSuites[$suitesIndex]=''
				childCases[$suitesIndex]=''
				mySuiteIndex="$suitesIndex"
				if [[ parentSuite -eq 0 ]]; then
					level0Suites="${level0Suites}${suitesIndex} "
				fi
				local rpath="${mybase#$parentPath/}"
				suitesRPath[$suitesIndex]="$rpath"
				executeSuite[$suitesIndex]=''
				suitesIndex=$((suitesIndex+1))
				isDebug && printDebug "Suite found state of childSuites:"
				#declare -p childSuites
			elif [[ $filename == $TEST_CASE_FILE ]]; then
				if [[ $isSuite ]]; then
					printError "ERROR ignore Suite and Case in one directory in $mybase"
				else
					isCase='true'
					casesPath[$casesIndex]="$mybase"
					childCases[$parentSuite]="${childCases[$parentSuite]}$casesIndex "
					local rpath="${mybase#$parentPath/}"
					casesRPath[$casesIndex]="$rpath"
					executeCase[$casesIndex]=''
					casesIndex=$((casesIndex+1))
					isDebug && printDebug "Case found state of childCases:"
					#declare -p childCases
				fi
			fi
		fi
	done
	#declare -p dirlist
	if [[ "$isSuite" ]]; then
		local childSuitesIndex=0;
	fi
	local i
	for ((i=0;i<${#dirlist[@]};i++)); do
		scan "${dirlist[$i]}" "$mySuiteIndex"
	done
	isDebug && printDebug "Leave $FUNCNAME $1 childSuitesIndex=$childSuitesIndex"
	return 0
}

# print found suites and cases recursiv
# $1 suite index to print
# $2 ident
# $3 if true: print only the cases/suites to execute
# $4 if true print debug
function printSuitesCases {
	#isDebug && printDebug "******* $FUNCNAME $1 $2 $3 $4"
	local ident="$2"
	local spacer=''
	local i
	for ((i=0; i<ident; i++)); do spacer="${spacer}"$'\t'; done
	if [[ -z $3 || -n ${executeSuite[$1]} ]]; then
		if [[ -n $4 ]]; then
			printDebug "${spacer}S: ${suitesPath[$1]} rpath=${suitesRPath[$1]}"
		else
			echo "${spacer}S: ${suitesRPath[$1]}"
		fi
	fi
	local li=${childCases[$1]}
	local x
	for x in $li; do
		if [[ -z $3 || -n ${executeCase[$x]} ]]; then
			if [[ -n $4 ]]; then
				printDebug "${spacer}  C: ${casesPath[$x]} rpath=${casesRPath[$x]}"
			else
				echo "${spacer}  C: ${casesRPath[$x]}"
			fi
		fi
	done
	li=${childSuites[$1]}
	local x
	local i2=$((ident+1))
	for x in $li; do
		printSuitesCases "$x" "i2" "$3" "$4"
	done
	return 0
}

# Checks for every case if there was a matching enty in cases array
# $1 current suite index
# $2 suite depth
# $3 R path of parent suites
function checkCaseMatch {
	isDebug && printDebug "******* $FUNCNAME $*"
	local i j
	local y
	local caseToExecuteHere=''
	for i in ${childCases[$1]}; do
		y="${3}::${casesRPath[$i]}"
		isDebug && printDebug "search patter for case=$y"
		for ((j=0; j<${#cases[*]}; j++)); do
			local pattern="${cases[$j]}"
			isDebug && printDebug "check match for case: ${pattern}"
			if [[ $y == $pattern ]]; then
				isDebug && printDebug "match found for case: ${pattern}"
				executeCase[$i]='true'
				usedCaseIndexList="$usedCaseIndexList $j"
				noCasesToExecute=$((noCasesToExecute+1))
				caseToExecuteHere='true'
				break
			fi
		done
	done
	local newDeth=$(($2+1))
	local x
	local caseToExecuteInSuites=''
	for x in ${childSuites[$1]}; do
		local spath="$3/${suitesRPath[$x]}"
		local caseToExecuteParent=''
		checkCaseMatch "$x" "$newDeth" "$spath"
		if [[ -n $caseToExecuteParent ]]; then
			caseToExecuteInSuites='true'
		fi
	done
	if [[ ( -n $caseToExecuteHere ) || ( -n $caseToExecuteInSuites ) ]]; then
		isDebug && printDebug "execute suite $1 ${suitesRPath[$1]}"
		caseToExecuteParent='true'
		executeSuite[$1]='true'
	fi
}

#
# print command line parameters
#
function printParams {
	if isDebug; then
		printDebug "** Commandline parameters **"
		printDebug "TTRO_scriptDir=${TTRO_scriptDir}"
		local x
		for x in ${!singleOptions[@]}; do
			printDebug "${x}=${!x}"
		done
		for x in ${!valueOptions[@]}; do
			printDebug "${x}=${!x}"
		done
		printDebug "toolsFiles=$toolsFiles"
		local -i i
		for ((i=0; i<${#varNamesToSet[@]}; i++)); do
			printDebug "-D ${varNamesToSet[$i]}=${varValuesToSet[$i]}"
		done
		if (( ${#cases[*]} > 0 )); then
			printDebug "cases=${cases[*]}"
		else
			printDebug "cases()"
		fi
		echo "************"
	fi
}

# Function execute collection variant
# $1 is the variant
# $2 is the collection variant workdir
# $3 execute empty suites
function exeCollection {
	#make and cleanup collection varant work dir if a variant exists
	local cworkdir="$2"
	if [[ -n "$1" ]]; then
		if [[ -e $cworkdir ]]; then
			rm -rf "$cworkdir"
		fi
		mkdir -p "$cworkdir"
	fi
	collectionVariants=$(( collectionVariants + 1 ))
	# execute
	local result=0
	if "${TTRO_scriptDir}/collection.sh" "${cworkdir}" "$1" "${3}" 2>&1 | tee -i "${cworkdir}/${TEST_LOG}"; then
		result=0;
	else
		result=$?
		if [[ $result -eq $errSigint ]]; then
			printWarning "Set SIGINT Execution of collection variant $1 ended with result=$result"
			interruptReceived="true"
		else
			printError "Execution of collection variant $1 ended with result=$result"
			collectionErrors=$(( collectionErrors + 1 ))
			builtin echo "$TTRO_collection:$1" >> "$TTRO_workDirMain/COLLECTION_ERROR_LIST"
		fi
	fi
	#read result lists and transfer results to main dir in case of variants
	local x
	if [[ -n "$1" ]]; then
		for x in VARIANT SUCCESS SKIP FAILURE ERROR; do
			local inputFileName="${cworkdir}/${x}_LIST"
			local outputFileName="${TTRO_workDirMain}/${x}_LIST"
			if [[ -e ${inputFileName} ]]; then
				{ while read; do
					if [[ $REPLY != \#* ]]; then
						echo "${TTRO_collection}:$REPLY" >> "$outputFileName"
					fi
				done } < "${inputFileName}"
			else
				printError "No result list $inputFileName in suite $cworkdir"
			fi
		done
		local glob=$(<"$TTRO_workDirMain/.suiteVariants")
		local svar=$(<"$cworkdir/.suiteVariants")
		glob=$((glob + svar))
		builtin echo -n "$glob" > "$TTRO_workDirMain/.suiteVariants"
		svar=$(<"$cworkdir/.suiteErrors")
		if [[ $svar -gt 0 ]]; then
			glob=$(<"$TTRO_workDirMain/.suiteErrors")
			glob=$((glob + svar))
			builtin echo -n "$glob" > "$TTRO_workDirMain/.suiteErrors"
			while read; do
				[[ $REPLY == \#* ]] && continue
				builtin echo "$TTRO_collection:${1}::$REPLY" >> "$TTRO_workDirMain/SUITE_ERROR_LIST"
			done < "$cworkdir/SUITE_ERROR_LIST"
		fi
	fi
	
	echo "**** END Suite: collection variant='$1' *******************"
	return 0
}

:
