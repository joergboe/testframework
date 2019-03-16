#!/bin/bash

######################################################
# Test suite
# Testframework Test Suite execution script
######################################################

#some setup to be save
IFS=$' \t\n'
#some recomended security settings
unset -f unalias
\unalias -a
unset -f command
#more setting to be save
set -o posix;
set -o errexit; set -o errtrace; set -o nounset; set -o pipefail
shopt -s globstar nullglob

#-----------------------------------------------------
# Shutdown and interrut vars and functions
declare -i interruptReceived=0
declare -r commandname="${0##*/}"
declare caseExecutionLoopRunning=''
#start time
declare -r suiteStartTime=$(date -u +%s)
#state
declare TTTT_executionState='initializing'

# Function handle SIGINT
function handleSigint {
	if [[ $interruptReceived -eq 0 ]]; then
		printWarning "SIGINT: Test Suite will be stopped. To interrupt running test cases press ^C again"
		interruptReceived=1
	elif [[ $interruptReceived -eq 1 ]]; then
		interruptReceived=$((interruptReceived+1))
		printWarning "SIGINT: Test cases will be stopped"
	elif [[ $interruptReceived -gt 2 ]]; then
		interruptReceived=$((interruptReceived+1))
		printWarning "SIGINT: Abort Suite"
		exit $errSigint
	else
		interruptReceived=$((interruptReceived+1))
	fi
	return 0
}

# Function interruptSignalSuite
function interruptSignalSuite {
	printInfo "SIGINT received in test suite execution programm $commandname ********************"
	handleSigint
	return 0
}

trap interruptSignalSuite SIGINT

# Function errorTrapFunc
#	global error exit function - prints the caller stack
function errorTrapFunc {
	echo -e "\033[31mERROR: $FUNCNAME ***************"
	local -i i=0;
	while caller $i; do
		i=$((i+1))
	done
	echo -e "************************************************\033[0m"
}

trap errorTrapFunc ERR

#-------------------------------------
#include general files
source "${TTRO_scriptDir}/defs.sh"
source "${TTRO_scriptDir}/util.sh"
source "${TTRO_scriptDir}/coreutil.sh"

# usage and parameters
function usage {
	local command=${0##*/}
	cat <<-EOF

	usage: ${command} suiteIndex suiteVariant suiteWorkdir suiteNestingLevel suiteNestingPath suiteNestingString preamblError;

	Requires exported execution list variables
	EOF
}

isDebug && printDebug "$0 $*"
if [[ $# -ne 7 ]]; then
	usage
	exit ${errInvocation}
fi
#move all parameters into named variables
declare -rx TTRO_suiteIndex="$1"; shift
declare -rx TTRO_variantSuite="$1"; shift
declare -rx TTRO_workDirSuite="$1"; shift
declare -rx TTRO_suiteNestingLevel="$1"; shift
declare -rx TTRO_suiteNestingPath="$1"; shift
declare -rx TTRO_suiteNestingString="$1"; shift
declare -rx TTTT_preamblError="$1"; shift

#restore all execution lists from exports
eval "$TTXX_suitesPath"
eval "$TTXX_suitesName"
eval "$TTXX_executeSuite"
eval "$TTXX_childSuites"
eval "$TTXX_casesPath"
eval "$TTXX_casesName"
eval "$TTXX_executeCase"
eval "$TTXX_childCases"
eval "$TTXX_runCategoryPatternArray"

#more common vars
declare -rx TTRO_suite="${suitesName[$TTRO_suiteIndex]}"
declare -rx TTRO_inputDirSuite="${suitesPath[$TTRO_suiteIndex]}"
declare -a TTTT_categoryArray=()

declare -a cases=() # case pathes
declare -a casesNames=() # the short path
declare -i noCases=0
declare x
for x in ${childCases[$TTRO_suiteIndex]}; do
	if [[ -n ${executeCase[$x]} ]]; then
		cases+=( "${casesPath[$x]}" )
		casesNames+=( "${casesName[$x]}" )
		noCases=$((noCases+1))
	fi
done

readonly cases casesNames noCases
isDebug && printDebug "noCases=$noCases"

# enter working dir
cd "$TTRO_workDirSuite"

#prepare index.html name
indexfilename="${TTRO_workDirSuite}/suite.html"

#handle preambl error
if [[ -n $TTTT_preamblError ]]; then
	createSuiteIndex "$indexfilename"
	echo "ERROR Preambl Error" >> "$indexfilename"
	getElapsedTime "$suiteStartTime"
	endSuiteIndex "$indexfilename" "$TTTT_elapsedTime"
	printErrorAndExit "Preambl Error" $errRt
fi

#check skipfile
if [[ $TTRO_suiteIndex -ne 0 ]]; then
	if [[ ( -e "${TTRO_inputDirSuite}/SKIP" ) && ( -z $TTPRN_skipIgnore ) ]]; then
		printInfo "SKIP file found suite=$TTRO_suite variant='$TTRO_variantSuite'"
		setSkip 'SKIP file found'
		createSuiteIndex "$indexfilename"
		echo "SKIPPED: $TTPRN_skip" >> "$indexfilename"
		getElapsedTime "$suiteStartTime"
		endSuiteIndex "$indexfilename" "$TTTT_elapsedTime"
		echo "$TTPRN_skip" > "${TTRO_workDirSuite}/REASON"
		exit $errSkip
	fi

	#source suite file
	tmp="${TTRO_inputDirSuite}/${TEST_SUITE_FILE}"
	if [[ -e "$tmp" ]]; then
		isVerbose && printVerbose  "Source Suite file $tmp"
		source "$tmp"
		fixPropsVars
		writeProtectExportedFunctions
	else
		printErrorAndExit "No Suite file $tmp" $errScript
	fi
fi

#------------------------------------------------
# diagnostics
isVerbose && printTestframeEnvironment
tmp="${TTRO_workDirSuite}/${TEST_ENVIRONMET_LOG}"
printTestframeEnvironment > "$tmp"
export >> "$tmp"

#check skip
if [[ $TTRO_suiteIndex -ne 0 ]]; then
	#check category
	if ! checkCats; then
		setSkip 'No matching runtime category'
	fi
	if isSkip; then
		printInfo "SKIP variable set; Skip execution suite=$TTRO_suite variant=$TTRO_variantSuite"
		createSuiteIndex "$indexfilename"
		echo "SKIPPED: $TTPRN_skip" >> "$indexfilename"
		getElapsedTime "$suiteStartTime"
		endSuiteIndex "$indexfilename" "$TTTT_elapsedTime"
		echo "$TTPRN_skip" > "${TTRO_workDirSuite}/REASON"
		exit $errSkip
	fi
fi

#--------------------------------------------------
# prepare output lists
for x in CASE_EXECUTE CASE_SKIP CASE_FAILURE CASE_ERROR CASE_SUCCESS SUITE_EXECUTE SUITE_SKIP SUITE_ERROR; do
	tmp="${TTRO_workDirSuite}/${x}"
	if [[ -e $tmp ]]; then
		printError "Result list exists in suite $TTRO_suite list: $tmp"
		rm -rf "$tmp"
	fi
	if [[ $x == SUITE_* ]]; then
		builtin echo "#suite[:variant][::suite[:variant]..]" > "$tmp"
	else
		builtin echo "#suite[:variant][::suite[:variant]..]::case[:variant]" > "$tmp"
	fi
done
tmp="${TTRO_workDirSuite}/RESULT"
if [[ -e $tmp ]]; then
	printError "Result file exists in suite $TTRO_suite list: $tmp"
	rm -rf "$tmp"
fi
touch "$tmp"

#create index.html
createSuiteIndex "$indexfilename"

#----------------------------------------------------------------------------------
#extract test case variants from list and put all cases and variants into the lists
function setTimeoutInArray {
	if isExisting 'timeout'; then
		caseTimeout[$noCaseVariants]="$timeout"
		if [[ ${caseTimeout[$noCaseVariants]} -eq 0 ]]; then
			printError "wrong timeout in case $caseName. timeout='$timeout'"
		fi
	else
		caseTimeout[$noCaseVariants]=0
	fi
}

declare -a caseVariantPathes=()		#the case path of all case variants
declare -a caseVariantIds=()		#the variant id of all cases
declare -a caseVariantWorkdirs=()	#the workdir of each variant
declare -a casePreambErrors=()		#true if case has peambl error
declare -ai caseTimeout=()			#the individual timeout
declare -i noCaseVariants=0			#the overall number of case variants
declare variantCount='' variantList='' preamblError=''
for ((i=0; i<noCases; i++)) do
	casePath="${cases[$i]}"
	caseName="${casePath##*/}"
	unset timeout
	if evalPreambl "${casePath}/${TEST_CASE_FILE}"; then
		preamblError=''
	else
		preamblError='true'; variantCount=''; variantList=''
	fi
	#echo "variantCount=$variantCount variantList=$variantList"
	if [[ -z $variantCount ]]; then
		if [[ -z $variantList ]]; then
			caseVariantPathes[$noCaseVariants]="$casePath"
			caseVariantIds[$noCaseVariants]=""
			caseVariantWorkdirs[$noCaseVariants]="${TTRO_workDirSuite}/${caseName}"
			casePreambErrors[$noCaseVariants]="$preamblError"
			setTimeoutInArray
			noCaseVariants=$((noCaseVariants+1))
		else
			for x in $variantList; do
				caseVariantPathes[$noCaseVariants]="$casePath"
				caseVariantIds[$noCaseVariants]="${x}"
				caseVariantWorkdirs[$noCaseVariants]="${TTRO_workDirSuite}/${caseName}/${x}"
				casePreambErrors[$noCaseVariants]="$preamblError"
				setTimeoutInArray
				noCaseVariants=$((noCaseVariants+1))
			done
			unset x
		fi
	else
		if [[ -z $variantList ]]; then
			for ((j=0; j<variantCount; j++)); do
				caseVariantPathes[$noCaseVariants]="$casePath"
				caseVariantIds[$noCaseVariants]="${j}"
				caseVariantWorkdirs[$noCaseVariants]="${TTRO_workDirSuite}/${caseName}/${j}"
				casePreambErrors[$noCaseVariants]="$preamblError"
				setTimeoutInArray
				noCaseVariants=$((noCaseVariants+1))
			done
			unset j
		else
			printError "In case ${TTRO_suite}:$caseName we have both variant variables variantCount=$variantCount and variantList=$variantList ! Case is skipped"
		fi
	fi
done
unset i casePath caseName
unset timeout variantCount variantList

isVerbose && printVerbose "Execute Suite $TTRO_suite variant='$TTRO_variantSuite' in workdir $TTRO_workDirSuite number of cases=$noCases number of case variants=$noCaseVariants"

#------------------------------------------------
# diagnostics
isVerbose && printTestframeEnvironment
printTestframeEnvironment > "${TTRO_workDirSuite}/${TEST_ENVIRONMET_LOG}"
export >> "${TTRO_workDirSuite}/${TEST_ENVIRONMET_LOG}"

#------------------------------------------------
#execute test suite preparation
TTTT_executionState='preparation'
declare -i executedTestPrepSteps=0
for name_xyza in 'TTRO_prepsSuite' 'PREPS'; do
	if isExisting "$name_xyza"; then
		if isArray "$name_xyza"; then
			if isDebug; then
				v=$(declare -p "$name_xyza")
				printDebug "$v"
			fi
			eval "l_xyza=\${#$name_xyza[@]}"
			for (( i_xyza=0; i_xyza<l_xyza; i_xyza++)); do
				eval "step_xyza=\${$name_xyza[$i_xyza]}"
				if isExistingAndTrue 'TTPR_noPrepsSuite'; then
					printInfo "Suppress Suite Preparation: $step_xyza"
				else
					printInfo "Execute Suite Preparation: $step_xyza"
					executedTestPrepSteps=$((executedTestPrepSteps+1))
					eval "$step_xyza"
				fi
			done
		else
			isDebug && printDebug "$name_xyza=${!name_xyza}"
			for x_xyza in ${!name_xyza}; do
				if isExistingAndTrue 'TTPR_noPrepsSuite'; then
					printInfo "Suppress Suite Preparation: $x_xyza"
				else
					printInfo "Execute Suite Preparation: $x_xyza"
					executedTestPrepSteps=$((executedTestPrepSteps+1))
					eval "${x_xyza}"
				fi
			done
		fi
	fi
done
if isFunction 'testPreparation'; then
	if isExistingAndTrue 'TTPR_noPrepsSuite'; then
		printInfo "Suppress Suite Preparation: testPreparation"
	else
		printInfo "Execute Suite Preparation: testPreparation"
		executedTestPrepSteps=$((executedTestPrepSteps+1))
		testPreparation
	fi
fi
printInfo "$executedTestPrepSteps Test Suite Preparation steps executed"
unset x
#-------------------------------------------------
#test case execution
TTTT_executionState='execution'

# check for duplicate jobspec in running jobs list
function checkDuplicateJobspec {
	local i
	local js
	for ((i=0; i<maxParralelJobs; i++)); do
		if [[ -n ${tpid[$i]} ]]; then #this job is ment to be running
			js="${tjobid[$i]}"
			#echo "Check index $i list entry $js - value to be inserted $1"
			if [[ -n $js ]]; then #and as a jobspec assigned
				if [[ $js -eq $1 ]]; then
					printWarning "Jobspec $1 is already in running jobs list at index i=$i ! Delete the jobspec"
					tjobid[$i]=''
				fi
			fi
		fi
	done
	return 0
}


if [[ $TTRO_noParallelCases -eq 1 ]]; then
	declare -ri maxParralelJobs=1
else
	declare -ri maxParralelJobs=$((TTRO_noParallelCases*2))
fi
declare -i currentParralelJobs=TTRO_noParallelCases

# do not set timer props here to avoid that nested suites have these props set
declare TTTT_casesTimeout="$defaultTimeout"
if isExisting 'TTPR_timeout'; then
	TTTT_casesTimeout="$TTPR_timeout"
fi
declare TTTT_casesAdditionalTime="$defaultAdditionalTime"
if isExisting 'TTPR_additionalTime'; then
	TTTT_casesAdditionalTime="$TTPR_additionalTime"
fi

declare -a tjobid=()	#the job id of process group (jobspec)
declare -a tpid=()		#pid of the case job this is the crucical value of the structure
declare -a tcase=()		#the name of the running case
declare -a tvariant=()	#the variant of the running case
declare -a tcasePath=()	#the input dir of the running case
declare -a startTime=()
declare -a timeout=()
declare -a endTime=()
declare -a killed=()
declare -a tcaseWorkDir=()
declare -a freeSlots=()	# the list of the free slots in txxxx arrays
declare allJobsGone=""
declare highLoad=''	#true if the system is in high load state
declare -i jobIndex=0 #index of next job to start
declare nextJobIndexToStart=''	#the index of the next job to start if any, empty if no more job is available (or interrupt)
declare -i jobsEnded=0 # the number of ended jobs
#result and summary variables
declare -i variantSuccess=0 variantSkiped=0 variantFailures=0 variantErrors=0
declare -i numberJobsRunning=0
declare thisJobRuns
declare sleepCyclesAndNoJobEnds=0
declare TTTT_now=''

# check for timed out jobs and kill them
# TTXX_shell disables timeout check
# expect TTTT_now is actual time
checkJobTimeouts() {
	isDebug && printDebug "check for timed out jobs"
	local i tempjobspec finalTime
	for ((i=0; i<maxParralelJobs; i++)); do
		#if [[ ( -n ${tpid[$i]} ) && ( -n ${tjobid[$i]} ) ]]; then
		if [[ -n ${tpid[$i]} ]]; then
			if [[ -z ${killed[$i]} ]]; then # the job was not yet killed
				if [[ ( ( ${endTime[$i]} -lt $TTTT_now ) && ( -z $TTXX_shell ) ) || ( $interruptReceived -gt 1 ) ]]; then
					if [[ -z ${tjobid[$i]} ]]; then
						tempjobspec="${tpid[$i]}"
						printError "tpid $tempjobspec with no jobspec encountered"
					else
						tempjobspec="%${tjobid[$i]}"
					fi
					printWarning "Timeout Kill i=${i} jobspec=${tempjobspec} with SIGTERM case=${tcase[$i]} variant=${tvariant[$i]} pid=${tpid[$i]}"
					#SIGINT and SIGHUP seems not to work can not install handler for both signals in case.sh
					if kill "${tempjobspec}"; then
						echo "timeout" > "${tcaseWorkDir[$i]}/TIMEOUT"
					else
						printWarning "Can not kill i=${i} jobspec=${tempjobspec} Gone?"
					fi
					killed[$i]="$TTTT_now"
				fi
			else
				finalTime=$((${killed[$i]}+$TTTT_casesAdditionalTime))
				if [[ $TTTT_now -gt $finalTime ]]; then
					if [[ -z ${tjobid[$i]} ]]; then
						tempjobspec="${tpid[$i]}"
						printError "tpid $tempjobspec with no jobspec encountered"
					else
						tempjobspec="%${tjobid[$i]}"
					fi
					printError "Forced Kill i=${i} jobspec=${tempjobspec} case=${tcase[$i]} variant=${tvariant[$i]} pid=${tpid[$i]}"
					if ! kill -9 "${tempjobspec}"; then
						printWarning "Can not force kill i=${i} jobspec=${tempjobspec} pid=${tpid[$i]} Gone?"
					fi
				fi
			fi
		fi
	done
}

# handle job ends
# count jobs
# prepare list of free slots
handleJobEnd() {
	#echo "CHECK JOB END"
	isDebug && printDebug "check for ended jobs"
	numberJobsRunning=0; freeSlots=()
	local oneJobStopFound=''
	local i
	for ((i=0; i<maxParralelJobs; i++)); do
		local pid="${tpid[$i]}"
		local jobid="${tjobid[$i]}"
		if [[ -n $pid ]]; then
			isDebug && printDebug "check wether job is still running i=$i pid=$pid jobspec=%$jobid"
			local thisJobRuns='true'
			if [[ -z $jobid ]]; then
				thisJobRuns=''
				echo "JOB Gone jobid is re-used $jobid"
				isDebug && printDebug "Job is Gone jobid is re-used $jobid"
			else
				#if ps --pid "$pid" &> /dev/null; then
				#if jobsOutput=$(LC_ALL=en_US jobs "%$jobid" 2>/dev/null); then ... this does not work in rhel 6 (bash 4.1.2)
				local jobsOutput
				if jobsOutput=$(export LC_ALL='en_US.UTF-8'; jobs "%$jobid" 2>/dev/null); then
					#echo "***** $jobsOutput"
					local tmp1=$(cut -d ' ' -f1 <<< $jobsOutput)
					local tmp2=$(cut -d ' ' -f2 <<< $jobsOutput)
					if [[ $tmp1 =~ \[(.*)\] ]]; then
						local tmp3="${BASH_REMATCH[1]}"
						if [[ $tmp2 == 'Done' ]]; then
							thisJobRuns=''
							#echo "JOB DONE $tmp3"
							isDebug && printDebug "Job is Done $tmp3"
						elif [[ $tmp2 == 'Running' ]]; then
							#echo "JOB RUNS $tmp3"
							isDebug && printDebug "Job is Running $tmp3"
						else
							printError "Invalid job state $tmp2 jobspec=%$tmp3"
							thisJobRuns=''
						fi
					else
						printError "Wrong output of jobs command $jobsOutput"
					fi
				else
					local psres=$?
					if [[ $psres -eq $errSigint ]]; then
						isDebug && printDebug "SIGINT: during jobs"
					else
						thisJobRuns=''
						echo "JOB Gone $jobid"
						isDebug && printDebug "Job is Gone $jobid"
					fi
				fi
			fi
			if [[ -n $thisJobRuns ]]; then
				numberJobsRunning=$((numberJobsRunning+1))
			else
				oneJobStopFound='true'
				jobsEnded=$((jobsEnded+1))
				freeSlots+=( $i )
				#echo "JOB END"
				local tmpCase="${tcase[$i]}"
				local tmpVariant="${tvariant[$i]}"
				#tmpCaseAndVariant="${tmpCase##*/}"
				local tmpCaseAndVariant="${TTRO_suiteNestingString}::${tmpCase}"
				if [[ -n $tmpVariant ]]; then
					tmpCaseAndVariant="${tmpCaseAndVariant}:${tmpVariant}"
				fi
				local caseElapsedTime='?'
				if [[ -e "${tcaseWorkDir[$i]}/ELAPSED" ]]; then
					caseElapsedTime=$(<"${tcaseWorkDir[$i]}/ELAPSED")
				else
					if [[ -e "${tcaseWorkDir[$i]}/STARTTIME" ]]; then
						local caseStartTime=$(<"${tcaseWorkDir[$i]}/STARTTIME")
						getElapsedTime "$caseStartTime"
						caseElapsedTime="$TTTT_elapsedTime"
					fi
				fi
				echo "$tmpCaseAndVariant : $caseElapsedTime" >> "${TTRO_workDirSuite}/CASE_EXECUTE"
				getSystemLoad100
				#executeList+=("$tmpCaseAndVariant")
				printInfon "END: i=$i pid=$pid jobspec=%$jobid case=${tmpCase} variant='${tmpVariant}' running=$numberJobsRunning systemLoad=$TTTT_systemLoad"
				tpid[$i]=""
				tjobid[$i]=""
				#collect variant result
				local jobsResultFile="${tcaseWorkDir[$i]}/RESULT"
				if [[ -e ${jobsResultFile} ]]; then
					local jobsResult=$(<"${jobsResultFile}")
					case "$jobsResult" in
						SUCCESS )
							echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/CASE_SUCCESS"
							variantSuccess=$((variantSuccess+1))
							addCaseEntry "$indexfilename" "$tmpCase" "$tmpVariant" 'SUCCESS' "${tcasePath[$i]}" "${tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTT_tempSummayName"
						;;
						SKIP )
							{ if read -r; then :; fi; } < "${tcaseWorkDir[$i]}/REASON" #read one line from reason
							echo "$tmpCaseAndVariant: $REPLY" >> "${TTRO_workDirSuite}/CASE_SKIP"
							variantSkiped=$((variantSkiped+1))
							addCaseEntry "$indexfilename" "$tmpCase" "$tmpVariant" 'SKIP' "${tcasePath[$i]}" "${tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTT_tempSummayName"
						;;
						FAILURE )
							{ if read -r; then :; fi; } < "${tcaseWorkDir[$i]}/REASON" #read one line from reason
							echo "$tmpCaseAndVariant: $REPLY" >> "${TTRO_workDirSuite}/CASE_FAILURE"
							variantFailures=$((variantFailures+1))
							addCaseEntry "$indexfilename" "$tmpCase" "$tmpVariant" 'FAILURE' "${tcasePath[$i]}" "${tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTT_tempSummayName"
							[[ ( -n $TTRO_xtraPrint ) && ( "$TTRO_noParallelCases" -ne 1 ) ]] && cat "${tcaseWorkDir[$i]}/${TEST_LOG}"
						;;
						ERROR )
							echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/CASE_ERROR"
							variantErrors=$((variantErrors+1))
							addCaseEntry "$indexfilename" "$tmpCase" "$tmpVariant" 'ERROR' "${tcasePath[$i]}" "${tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTT_tempSummayName"
							[[ ( -n $TTRO_xtraPrint ) && ( "$TTRO_noParallelCases" -ne 1 ) ]] && cat "${tcaseWorkDir[$i]}/${TEST_LOG}"
						;;
						* )
							printError "${tmpCase}:${tmpVariant} : Invalid Case-variant result $jobsResult case workdir ${tcaseWorkDir[$i]}"
							echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/CASE_ERROR"
							variantErrors=$((variantErrors+1))
							addCaseEntry "$indexfilename" "$tmpCase" "$tmpVariant" 'ERROR' "${tcasePath[$i]}" "${tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTT_tempSummayName"
							jobsResult="ERROR"
							[[ ( -n $TTRO_xtraPrint ) && ( "$TTRO_noParallelCases" -ne 1 ) ]] && cat "${tcaseWorkDir[$i]}/${TEST_LOG}"
						;;
					esac
				else
					printError "No RESULT file in case workdir ${tcaseWorkDir[$i]}"
					echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/CASE_ERROR"
					variantErrors=$((variantErrors+1))
					addCaseEntry "$indexfilename" "$tmpCase" "$tmpVariant" 'ERROR' "${tcasePath[$i]}" "${tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTT_tempSummayName"
					jobsResult="ERROR"
					[[ ( -n $TTRO_xtraPrint ) && ( "$TTRO_noParallelCases" -ne 1 ) ]] && cat "${tcaseWorkDir[$i]}/${TEST_LOG}"
				fi
				echo " Result: $jobsResult"
			fi
		else
			freeSlots+=( $i )
		fi
	done
	if [[ -n $oneJobStopFound ]]; then
		sleepCyclesAndNoJobEnds=0
	fi
} # /handleJobEnd

#wait if no slot is free an not allJobsGone
sleepIf() {
	if [[ ( -n $nextJobIndexToStart && ( $numberJobsRunning -ge $currentParralelJobs ) ) || ( -z $nextJobIndexToStart && -z $allJobsGone ) ]]; then
		local waitTime='0.2'
		if [[ $sleepCyclesAndNoJobEnds -ge 10 ]]; then
			waitTime='1'
		else
			sleepCyclesAndNoJobEnds=$((sleepCyclesAndNoJobEnds+1))
		fi
		printError "SLEEP $waitTime sleepCyclesAndNoJobEnds=$sleepCyclesAndNoJobEnds"
		isDebug && printDebug "sleep $waitTime sleepCyclesAndNoJobEnds=$sleepCyclesAndNoJobEnds"
		if sleep "$waitTime"; then
			isDebug && printDebug "sleep returns success"
		else
			local cresult=$?
			if [[ $cresult -eq 130 ]]; then
				printInfo "SIGINT received in sleep in programm $commandname ********************"
			else
				printError "Unhandled result $cresult after sleep"
			fi
		fi
	fi
	return 0
}

# Start one or more new job(s)
# expect TTTT_now is actual time
startNewJobs() {
	local freeSlotIndx=0
	while [[ -n $nextJobIndexToStart && ( $numberJobsRunning -lt $currentParralelJobs ) ]]; do
		if [[ $freeSlotIndx -ge ${#freeSlots[*]} ]]; then printErrorAndExit "No free slot but one job to start freeSlotIndx=$freeSlotIndx free slots=${#freeSlots[*]}" $errRt; fi
		local freeSlot="${freeSlots[$freeSlotIndx]}"; freeSlotIndx=$((freeSlotIndx+1));
		local casePath="${caseVariantPathes[$nextJobIndexToStart]}"
		local caseName="${casePath##*/}"
		local caseVariant="${caseVariantIds[$nextJobIndexToStart]}"
		local cworkdir="${caseVariantWorkdirs[$nextJobIndexToStart]}"
		local cpreamblError="${casePreambErrors[$nextJobIndexToStart]}"
		#make and cleanup case work dir
		if [[ -e $cworkdir ]]; then
			printErrorAndExit "Case workdir exists! Probably duplicate variant. workdir: $cworkdir" $errSuiteError
		fi
		mkdir -p "$cworkdir"
		local cmd="${TTRO_scriptDir}/case.sh"
		getSystemLoad100
		numberJobsRunning=$((numberJobsRunning+1))
		printInfon "START: jobIndex=$nextJobIndexToStart case=$caseName variant=$caseVariant i=$freeSlot running=$((numberJobsRunning)) systemLoad=$TTTT_systemLoad"
		#Start job connect output to stdout in single thread case
		if [[ "$TTRO_noParallelCases" -eq 1 ]]; then
			$cmd "$casePath" "$cworkdir" "$caseVariant" "$cpreamblError" 2>&1 | tee -i "${cworkdir}/${TEST_LOG}" &
			local newPid=$!
		else
			$cmd "$casePath" "$cworkdir" "$caseVariant" "$cpreamblError" &> "${cworkdir}/${TEST_LOG}" &
			local newPid=$!
		fi
		#jobsOutput=$(LC_ALL=en_US jobs %+)  ... this does not work in rhel 6 (bash 4.1.2)
		local jobsOutput=$(export LC_ALL='en_US.UTF-8'; jobs %+)
		echo "$jobsOutput" > "$cworkdir/JOBS"
		echo "Full Job list" >> "$cworkdir/JOBS"
		LC_ALL='en_US.UTF-8' jobs -l >> "$cworkdir/JOBS"
		isDebug && printDebug "jobspec:$jobsOutput"
		local tmp1=$(cut -d ' ' -f1 <<< $jobsOutput)
		local jobState=$(cut -d ' ' -f2 <<< $jobsOutput)
		if [[ $tmp1 =~ \[(.*)\]\+ ]]; then
			local tmp5="${BASH_REMATCH[1]}"
			echo " jobspec=%$tmp5 pid=$newPid state=$jobState"
			checkDuplicateJobspec "$tmp5"
		else
			echo
			tjobid[$freeSlot]=""
			printErrorAndExit "No jobindex extract from jobs output '$jobsOutput'" $errRt
		fi
		tpid[$freeSlot]="$newPid"
		tjobid[$freeSlot]="$tmp5"
		tcase[$freeSlot]="$caseName"
		tvariant[$freeSlot]="$caseVariant"
		tcasePath[$freeSlot]="$casePath"
		killed[$freeSlot]=""
		isDebug && printDebug "Enter tjobid[$freeSlot]=${tjobid[$freeSlot]} state=$jobState tpid[${freeSlot}]=$newPid time=${TTTT_now} state=$jobState"
		startTime[$freeSlot]="$TTTT_now"
		local jobTimeout=${caseTimeout[$jobIndex]}
		if [[ $jobTimeout -lt $TTTT_casesTimeout ]]; then
			jobTimeout="$TTTT_casesTimeout"
		fi
		isVerbose && printVerbose "Job timeout $jobTimeout"
		endTime[$freeSlot]=$((TTTT_now+jobTimeout))
		timeout[$freeSlot]="$jobTimeout"
		tcaseWorkDir[$freeSlot]="$cworkdir"
		jobIndex=$((jobIndex+1))
		if [[ ( $interruptReceived -gt 0 ) || ( $jobIndex -ge $noCaseVariants ) ]]; then
			nextJobIndexToStart=''
		else
			nextJobIndexToStart="$jobIndex"
		fi
	done
} #/startNewJobs

#init the work structure for maxParralelJobs
for ((i=0; i<maxParralelJobs; i++)); do
	tjobid[$i]=""; tpid[$i]=""; tcase[$i]=""; tvariant[$i]=""; tcasePath[$i]=""
	startTime[$i]=""; timeout[$i]=""; startTime[$i]=""; endTime[$i]=""
	killed[$i]=""; tcaseWorkDir[$i]=""
	freeSlots+=( $i )
done

#print special summary
TTTT_tempSummayName="${TTRO_workDirSuite}/part1.tmp"
rm -f "$TTTT_tempSummayName"
touch "$TTTT_tempSummayName"

#the loop until all jobs are gone
if [[ $noCaseVariants -gt 0 ]]; then
	nextJobIndexToStart=0
else
	nextJobIndexToStart=''
fi
while [[ -z $allJobsGone ]]; do
	isDebug && printDebug "Loop precond allJobsGone='${allJobsGone}' jobIndex='${nextJobIndexToStart}'"
	# loop either not the final job and no job slot is available or the final job and not all jobs gone
	while [[ ( -n $nextJobIndexToStart && ( $numberJobsRunning -ge  $currentParralelJobs ) || ( ${#freeSlots[*]} -eq 0 ) ) || ( -z $nextJobIndexToStart && -z $allJobsGone ) ]]; do
		isDebug && printDebug "Loop cond numberJobsRunning='$numberJobsRunning' currentParralelJobs='$currentParralelJobs' allJobsGone='$allJobsGone' nextJobIndexToStart='$nextJobIndexToStart'"
		while ! TTTT_now="$(date +'%-s')"; do :; done #guard external command if sigint is received TODO: is signal received from this job too?
		checkJobTimeouts
		handleJobEnd
		if [[ $interruptReceived -gt 0 ]]; then
			nextJobIndexToStart=''
			isVerbose && printVerbose "Interrupt suite $TTRO_suite interruptReceived=$interruptReceived ****"
		fi
		#during final job run: check that all jobs are gone
		if [[ -z $nextJobIndexToStart && ( $numberJobsRunning -eq 0 ) ]]; then
			isDebug && printDebug "All jobs gone"
			#echo "ALL JOBS GONE"
			allJobsGone="true"
		fi
		sleepIf
		isDebug && printDebug "Loop POST cond numberJobsRunning='$numberJobsRunning' currentParralelJobs='$currentParralelJobs' allJobsGone='$allJobsGone' nextJobIndexToStart='$nextJobIndexToStart'"
	done
	while ! TTTT_now="$(date +'%-s')"; do :; done #guard external command if sigint is received
	startNewJobs
done

#check number of jobs ended and job index
if [[ $jobIndex -ne $jobsEnded ]]; then
	printError "The nuber of jobs started=$jobIndex is not equal to the number of jobs ended=$jobsEnded"
fi

#fin
startSuiteList "$indexfilename"

##execution loop over sub suites and variants
declare -i suiteVariants=0 suiteErrors=0 suiteSkip=0
for sindex_xyza in ${childSuites[$TTRO_suiteIndex]}; do
	suitePath="${suitesPath[$sindex_xyza]}"
	suite="${suitesName[$sindex_xyza]}"
	if [[ $interruptReceived -gt 0 ]]; then
		printInfo "SIGINT: end Suites loop"
		break
	fi
	isVerbose && printVerbose "**** START Nested Suite: $suite ************************************"
	variantCount=""; variantList=""; preamblError=""
	if ! evalPreambl "${suitePath}/${TEST_SUITE_FILE}"; then
		preamblError='true'; variantCount=""; variantList=""
	fi
	if [[ -z $variantCount ]]; then
		if [[ -z $variantList ]]; then
 			exeSuite "$sindex_xyza" "" "$TTRO_suiteNestingLevel" "$TTRO_suiteNestingPath" "$TTRO_suiteNestingString" "$TTRO_workDirSuite" "$preamblError"
		else
			for x_xyza in $variantList; do
				exeSuite "$sindex_xyza" "$x_xyza" "$TTRO_suiteNestingLevel" "$TTRO_suiteNestingPath" "$TTRO_suiteNestingString" "$TTRO_workDirSuite" "$preamblError"
				if [[ $interruptReceived -gt 0 ]]; then
					printInfo "SIGINT: end Suites loop"
					break
				fi
			done
			unset x_xyza
		fi
	else
		if [[ -z $variantList ]]; then
			declare -i j_xyza
			for ((j_xyza=0; j_xyza<variantCount; j_xyza++)); do
				exeSuite "$sindex_xyza" "$j_xyza" "$TTRO_suiteNestingLevel" "$TTRO_suiteNestingPath" "$TTRO_suiteNestingString" "$TTRO_workDirSuite" "$preamblError"
				if [[ $interruptReceived -gt 0 ]]; then
					printInfo "SIGINT: end Suites loop"
					break
				fi
			done
			unset j_xyza
		else
			printError "In suite $suite we have both variant variables variantCount=$variantCount and variantList=$variantList ! Suite is skipped"
		fi
	fi
	isVerbose && printVerbose "**** END Nested Suite: $suite **************************************"
	if [[ $interruptReceived -gt 0 ]]; then
		printInfo "SIGINT: end Suites loop"
		break
	fi
done
unset sindex_xyza

#test suite finalization
TTTT_executionState='finalization'
declare -i executedTestFinSteps=0
if isFunction 'testFinalization'; then
	if isExisting 'FINS' || isExisting 'TTRO_finSuite'; then
		printErrorAndExit "You must not use FINS or TTRO_finSuite variable together with testFinalization function" $errRt
	fi
fi
for name_xyza in 'TTRO_finSuite' 'FINS'; do
	if isExisting "$name_xyza"; then
		if isArray "$name_xyza"; then
			if isDebug; then
				v=$(declare -p "$name_xyza")
				printDebug "$v"
			fi
			eval "l_xyza=\${#$name_xyza[@]}"
			for (( i_xyza=0; i_xyza<l_xyza; i_xyza++)); do
				eval "step=\${$name_xyza[$i_xyza]}"
				if isExistingAndTrue 'TTPR_noFinsSuite'; then
					printInfo "Suppress Suite Finalization: $step"
				else
					printInfo "Execute Suite Finalization: $step"
					executedTestFinSteps=$((executedTestFinSteps+1))
					eval "$step"
				fi
			done
		else
			isDebug && printDebug "$name_xyza=${!name_xyza}"
			for x_xyza in ${!name_xyza}; do
				if isExistingAndTrue 'TTPR_noFinsSuite'; then
					printInfo "Suppress Suite Finalization: $x_xyza"
				else
					printInfo "Execute Suite Finalization: $x_xyza"
					executedTestFinSteps=$((executedTestFinSteps+1))
					eval "${x_xyza}"
				fi
			done
		fi
	fi
done
if isFunction 'testFinalization'; then
	if isExistingAndTrue 'TTPR_noFinsSuite'; then
		printInfo "Suppress Suite Finalization: testFinalization"
	else
		printInfo "Execute Suite Finalization: testFinalization"
		executedTestFinSteps=$((executedTestFinSteps+1))
		testFinalization
	fi
fi
printInfo "$executedTestFinSteps Test Suite Finalisation steps executed"

#-------------------------------------------------------
#put results to results file for information purose only
echo -e "CASE_EXECUTE=$jobIndex\nCASE_FAILURE=$variantFailures\nCASE_ERROR=$variantErrors\nCASE_SKIP=$variantSkiped\nCASE_SUCCESS=$variantSuccess" > "${TTRO_workDirSuite}/RESULT"
echo -e "SUITE_EXECUTE=$suiteVariants\nSUITE_ERROR=$suiteErrors\nSUITE_SKIP=$suiteSkip" >> "${TTRO_workDirSuite}/RESULT"

#-------------------------------------------------------
#Final verbose suite result printout
printInfo "**** Results Suite: $TTRO_suite ***********************************************"
for x in CASE_EXECUTE CASE_SKIP CASE_FAILURE CASE_ERROR CASE_SUCCESS SUITE_EXECUTE SUITE_SKIP SUITE_ERROR; do
	tmp="${TTRO_workDirSuite}/${x}"
	eval "${x}_NO=0"
	isVerbose && printVerbose "**** $x List : ****"
	if [[ -e ${tmp} ]]; then
		{
			while read; do
				if [[ $REPLY != \#* ]]; then
					eval "${x}_NO=\$((${x}_NO+1))"
				fi
				isVerbose && printVerbose "$REPLY "
			done
		} < "$tmp"
	else
		printErrorAndExit "No result file ${tmp} exists" $errRt
	fi
	tmp3="${x}_NO"
	isDebug && printDebug "Overall $x = ${!tmp3}"
done

# html
getElapsedTime "$suiteStartTime"
endSuiteIndex "$indexfilename" "$TTTT_elapsedTime"

declare suiteResult=0
if [[ $interruptReceived -gt 0 ]]; then
	suiteResult=$errSigint
fi

printf "**** Suite: $TTRO_suite Variant: '$TTRO_variantSuite' cases=%i failures=%i errors=%i skipped=%i *****\n" $jobIndex $variantFailures $variantErrors $variantSkiped
printInfo "**** Elapsed time $TTTT_elapsedTime *****"
echo "$TTTT_elapsedTime" > "${TTRO_workDirSuite}/ELAPSED"

#---------------------------------------------------------------------------------
#print special summary
if [[ -n $TTXX_summary ]]; then
	sname="${TTRO_suite}"
	#if [[ -z $sname ]]; then sname='Dummy'; fi
	if [[ -n ${TTRO_variantSuite} ]]; then sname="${sname}_${TTRO_variantSuite}"; fi
	reportfile0="${TTRO_workDirSuite}/${sname}_part0.tmp"
	reportfile="${TTRO_workDirSuite}/${sname}_summary.txt"
	echo "Testsuite: ${sname}" > "$reportfile0"
	echo -e "Tests run: $jobIndex, Failures: $variantFailures, Errors: $variantErrors, Skipped: $variantSkiped, Time elapsed: ${TTTT_elapsedTime}\n" >> "$reportfile0"
	cat "$reportfile0" "$TTTT_tempSummayName" > "$reportfile"
	rm -f "$reportfile0"
fi
rm -f "$TTTT_tempSummayName"

builtin echo -n "$suiteResult" > "${TTRO_workDirSuite}/DONE"

isDebug && printDebug "END: Suite $TTRO_suite variant='$TTRO_variantSuite' suite exit code $suiteResult"

exit $suiteResult
