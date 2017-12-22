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

#
# Search for test suites. Suites are directories with a suite definition file $TEST_SUITE_FILE
# Use global caseMap and noSuites
function searchSuites {
	local suite=""
	local myPath=""
	local x
	isDebug && printDebug "******* $FUNCNAME in directory ${directory}"
	for x in ${directory}/**/$TEST_SUITE_FILE; do
		if [[ -f $x || -h $x ]]; then # recognize links to
			isDebug && printDebug "Found Suite properties file ${x}"
			suite=""; myPath="";
			myPath="${x%/$TEST_SUITE_FILE}"
			if [[ $x == *\ * ]]; then
				printErrorAndExit "Invald path : $x\nPathes must not contain spaces." ${errRt}
			fi
			suite="${myPath##*/}" # suite name is the last part of the path
			isDebug && printDebug "Found Suite ${suite}"
			#enter an empty value here
			caseMap["${myPath}"]="" #enter an empty value here
			noSuites=$(( noSuites+1 ))
		fi
	done
	return 0
}

#
# check nested suite and duplicate test suite names. This is considered an error
# Use global caseMap
function checkSuiteList {
	local n1 n2 i j
	isDebug && printDebug "******* $FUNCNAME"
	for i in ${!caseMap[@]}; do
		for j in ${!caseMap[@]}; do
			#skip same entries
			if [ $i != $j ]; then
				#check for nested suites
				if [[ ( ${i} == ${j}* ) || ( ${j} == ${i}* ) ]]; then
					printErrorAndExit "Nested suites found\n$i\n$j\nSuites must not be nested" ${errRt}
				fi
				#check for equal names
				n1="${i##*/}"; n2="${j##*/}"
				if [ ${n1} == ${n2} ]; then
					printErrorAndExit "Same suite name found in \n$i\n$j" ${errRt}
				fi
			fi
		done
	done
	return 0
}

#
#search test cases. Cases are sub directories in suites with a case definition file $TEST_CASE_FILE
#cases are entered as value into the caseMap as space separated list 
#Check for duplicates and nested elements
# Use global caseMap
function searchCases {
	local case="" casePath=""
	local -i noCases=0
	local myPath x tmp n1 n2 i j
	local suite allSuites insertCase
	local allRegularCases=''
	isDebug && printDebug "******* $FUNCNAME"
	allSuites="${!caseMap[@]} $TTRO_inputDir" # add dummy suite as last element
	for myPath in $allSuites; do
		if [[ $myPath == $TTRO_inputDir ]]; then
			suite='--'
			caseMap[$myPath]='' #add dummy suite
		else
			suite="${myPath##*/}"
		fi
		isDebug && printDebug "search in suite: $suite $myPath"
		noCases=0
		for x in ${myPath}/**/$TEST_CASE_FILE; do
			if [[ -f $x || -h $x ]]; then # recognize also links to
				isDebug && printDebug "Found test case file ${x}"
				case=""
				casePath="${x%/$TEST_CASE_FILE}"
				isDebug && printDebug "Found case $case"
				if [[ $x == *\ * ]]; then
					"Invald path : $x\nPathes must not contain spaces." ${errRt}
				fi
				case="${casePath##*/}"
				insertCase='true'
				if [[ $suite != '--' ]]; then
					allRegularCases="$allRegularCases $x"
				else
					##remove already found cases in regular suites from dummy suite
					for i in $allRegularCases; do
						if [[ $x == $i* ]]; then
							isDebug && printDebug "Dummy suite case $x is already recognized in sute/case $i"
							insertCase=''
							break
						fi
					done
				fi
				if [[ -n $insertCase ]]; then
					#put case into caseMap
					tmp="${caseMap["$myPath"]} ${casePath}"
					caseMap["$myPath"]="${tmp}"
					noCases=$(( noCases+1 ))
				fi
			fi
		done
		isDebug && printDebug "$noCases test cases found in $myPath"

		# check nested case and duplicate test case names
		for i in ${caseMap["$myPath"]}; do
			for j in ${caseMap["$myPath"]}; do
				#skip same entries
				if [ "$i" != "$j" ]; then
					#check for nested cases
					isDebug && printDebug "check for nested cases $i $j"
					if [[ ${i} == ${j} ]]; then
						printErrorAndExit "Nested case found\n$i\n$j\nTest cases must not be nested" ${errRt}
					fi
					#check for same names
					n1="${i##*/}"; n2="${j##*/}"
					if [ "${n1}" == "${n2}" ]; then
						printErrorAndExit "Same test case name found in \n$i\n$j" ${errRt}
					fi
				fi
			done
		done
	done
	return 0
}

#
# Sort cases alphabetical and determine the final execution list
# Use global sortedSuites as input for suites (array)
# Use caseMap input map with cases found in file  system
# Use global cases the as input for case pattern (array)
# Use global executionList as output for found test cases to be executed
# Use global usedCaseIndexList the indexes of used cases forom cases array
# Use global noCases the number of found cases
function sortCases {
	local myPath suite x casePath case tmpx tmp
	local -i i j
	for ((i=0; i<${#sortedSuites[@]}; i++)); do
		myPath="${sortedSuites[$i]}"
		isDebug && printDebug "*********** take suite=${myPath}"
		if [[ $myPath == $TTRO_inputDir ]]; then
			suite=''
		else
			suite=${myPath##*/}
		fi
		executionList["$myPath"]=""
		declare -a sortedCases=$( { for x in ${caseMap["$myPath"]}; do echo "$x"; done } | sort )
		isDebug && printDebug "sortedCases=\n$sortedCases\n**********"
		for casePath in ${sortedCases}; do
			case=${casePath##*/}
			isDebug && printDebug "check if case=${case} matches"
			if [[ -n "$takeAllCases" ]]; then
				isDebug && printDebug "direct insert case=${case} into execution list"
				executionList["$myPath"]+=" ${casePath}"
				noCases=$((noCases+1))
			else
				# lookup if case matches one pattern from parameter list
				tmpx="${!cases[@]}"
				for ((j=0; j<${#cases[@]}; j++)); do
					tmp="${suite}::${case}"
					isDebug && printDebug "tmp='$tmp'"
					isDebug && printDebug "case='${cases[$j]}'"
					if [[ $tmp == ${cases[$j]} ]]; then
						isDebug && printDebug "conditional insert case=${case} into execution list"
						executionList["$myPath"]+=" ${casePath}"
						noCases=$((noCases+1))
						usedCaseIndexList=" $j"
					fi
				done
			fi
		done
	done
	return 0
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