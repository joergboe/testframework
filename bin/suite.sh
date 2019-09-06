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
#set -o monitor #enables job monitor -> synchron (endless) commands started from cases are terminated with this option
#but is has consequences for read commands issued from suite -> return 149 means it receives SIGTTIN
shopt -s globstar nullglob

#-----------------------------------------------------
# Shutdown and interrut vars and functions
declare -i TTTI_interruptReceived=0
declare -r TTTI_commandname="${0##*/}"
declare -r TTTI_sigspec='TERM'
#start time
declare -r TTTT_suiteStartTime=$(date -u +%s)
#state
declare TTTT_executionState='initializing'

# Function handle SIGINT
handleSigint() {
	TTTI_interruptReceived=$((TTTI_interruptReceived+1))
	if [[ $TTTI_interruptReceived -eq 1 ]]; then
		printWarning "SIGINT #1: Test Suite will be stopped. To interrupt running test cases press ^C again"
	elif [[ $TTTI_interruptReceived -eq 2 ]]; then
		printWarning "SIGINT #2: Test cases will be stopped"
	elif [[ $TTTI_interruptReceived -eq 3 ]]; then
		local myname='unknown'
		if isExisting 'TTRO_workDirSuite'; then
			myname="$TTRO_workDirSuite"
		fi
		printWarning "SIGINT: Abort Suite: $myname"
		exit $errSigint
	else
		printErrorAndExit "SIGINT: received - wrong TTTI_interruptReceived=$TTTI_interruptReceived" $errRt
	fi
	return 0
}
trap handleSigint SIGINT

# Function errorTrapFunc
#	global error exit function - prints the caller stack
errorTrapFunc() {
	echo -e "\033[31mERROR: $FUNCNAME ***************"
	local -i i=0;
	while caller $i; do
		i=$((i+1))
	done
	echo -e "************************************************\033[0m"
}
trap errorTrapFunc ERR

#check if one of the global vars is used in user code
checkGlobalVarsUsed() {
	if isExisting 'variantCount' || isExisting 'variantList' || isExisting 'timeout' || isExisting 'exclusive'; then
		printErrorAndExit "On of variables variantCount, variantList, timeout or exclusive is used in suite user code suite $TTRO_suite" $errSuiteError
	fi
}

#-------------------------------------
#include general files
source "${TTRO_scriptDir}/defs.sh"
source "${TTRO_scriptDir}/util.sh"
source "${TTRO_scriptDir}/coreutil.sh"

# usage and parameters
usage() {
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
declare -rx TTRO_suite="${TTTI_suitesName[$TTRO_suiteIndex]}"
declare -rx TTRO_inputDirSuite="${TTTI_suitesPath[$TTRO_suiteIndex]}"
declare -a TTTT_categoryArray=()
#append suite input dir to the top of the search pathes
if [[ $TTRO_suiteIndex -ne 0 ]]; then
	TTXX_searchPath="$TTRO_inputDirSuite $TTXX_searchPath"
	export TTXX_searchPath
fi
TTTF_fixPropsVars

# enter working dir
cd "$TTRO_workDirSuite"

#prepare index.html name and create index.html
TTTI_indexfilename="${TTRO_workDirSuite}/suite.html"
TTTF_createSuiteIndex "$TTTI_indexfilename"

#handle preambl error
if [[ -n $TTTT_preamblError ]]; then
	echo "ERROR Preambl Error" >> "$TTTI_indexfilename"
	getElapsedTime "$TTTT_suiteStartTime"
	TTTF_endSuiteIndex "$TTTI_indexfilename" "$TTTT_elapsedTime"
	printErrorAndExit "Preambl Error" $errRt
fi

#check skipfile
if [[ $TTRO_suiteIndex -ne 0 ]]; then
	if [[ ( -e "${TTRO_inputDirSuite}/SKIP" ) && ( -z $TTPRN_skipIgnore ) ]]; then
		printInfo "SKIP file found suite=$TTRO_suite variant='$TTRO_variantSuite'"
		setSkip 'SKIP file found'
		echo "SKIPPED: $TTPRN_skip" >> "$TTTI_indexfilename"
		getElapsedTime "$TTTT_suiteStartTime"
		TTTF_endSuiteIndex "$TTTI_indexfilename" "$TTTT_elapsedTime"
		echo "$TTPRN_skip" > "${TTRO_workDirSuite}/REASON"
		exit $errSkip
	fi
fi

#------------------------------------------------
# diagnostics
isVerbose && printTestframeEnvironment
TTTI_tmp="${TTRO_workDirSuite}/${TEST_ENVIRONMET_LOG}"
printTestframeEnvironment > "$TTTI_tmp"
set +o posix
export >> "$TTTI_tmp"
declare -F >> "$TTTI_tmp"
set -o posix

#source suite file
if [[ $TTRO_suiteIndex -ne 0 ]]; then
	TTTI_tmp="${TTRO_inputDirSuite}/${TEST_SUITE_FILE}"
	if [[ -e "$TTTI_tmp" ]]; then
		isVerbose && printVerbose  "Source Suite file $TTTI_tmp"
		source "$TTTI_tmp"
		TTTF_fixPropsVars
		TTTF_writeProtectExportedFunctions
	else
		printErrorAndExit "No Suite file $TTTI_tmp" $errScript
	fi
fi
checkGlobalVarsUsed

#check skip
if [[ $TTRO_suiteIndex -ne 0 ]]; then
	#check category
	if ! TTTF_checkCats; then
		setSkip 'No matching runtime category'
	fi
	if TTTF_isSkip; then
		printInfo "SKIP variable set; Skip execution suite=$TTRO_suite variant=$TTRO_variantSuite"
		echo "SKIPPED: $TTPRN_skip" >> "$TTTI_indexfilename"
		getElapsedTime "$TTTT_suiteStartTime"
		TTTF_endSuiteIndex "$TTTI_indexfilename" "$TTTT_elapsedTime"
		echo "$TTPRN_skip" > "${TTRO_workDirSuite}/REASON"
		exit $errSkip
	fi
fi

#--------------------------------------------------
# prepare output lists
for TTTI_x in CASE_EXECUTE CASE_SKIP CASE_FAILURE CASE_ERROR CASE_SUCCESS SUITE_EXECUTE SUITE_SKIP SUITE_ERROR; do
	TTTI_tmp="${TTRO_workDirSuite}/${TTTI_x}"
	if [[ -e $TTTI_tmp ]]; then
		printError "Result list exists in suite $TTRO_suite list: $TTTI_tmp"
		rm -rf "$TTTI_tmp"
	fi
	if [[ $TTTI_x == SUITE_* ]]; then
		builtin echo "#suite[:variant][::suite[:variant]..]" > "$TTTI_tmp"
	else
		builtin echo "#suite[:variant][::suite[:variant]..]::case[:variant]" > "$TTTI_tmp"
	fi
done
TTTI_tmp="${TTRO_workDirSuite}/RESULT"
if [[ -e $TTTI_tmp ]]; then
	printError "Result file exists in suite $TTRO_suite list: $TTTI_tmp"
	rm -rf "$TTTI_tmp"
fi
touch "$TTTI_tmp"

#----------------------------------------------------------------------------------
#make the linear list of cases pathes and cases names
declare -a TTTI_cases=() # case pathes
declare -a TTTI_casesNames=() # the short path
declare -i TTTI_noCases=0
declare TTTI_x
for TTTI_x in ${TTTI_childCases[$TTRO_suiteIndex]}; do
	if [[ -n ${TTTI_executeCase[$TTTI_x]} ]]; then
		TTTI_cases+=( "${TTTI_casesPath[$TTTI_x]}" )
		TTTI_casesNames+=( "${TTTI_casesName[$TTTI_x]}" )
		TTTI_noCases=$((TTTI_noCases+1))
	fi
done

readonly TTTI_cases TTTI_casesNames TTTI_noCases
isDebug && printDebug "noCases=$TTTI_noCases"

#extract test case variants from list and put all cases and variants into the lists
function setTimeoutInArray {
	if [[ -n $timeout ]]; then
		TTTI_caseTimeout[$TTTI_noCaseVariants]="$timeout"
		if [[ ${TTTI_caseTimeout[$TTTI_noCaseVariants]} -eq 0 ]]; then
			printError "wrong timeout in case $TTTI_caseName. timeout='$timeout'"
		fi
	else
		TTTI_caseTimeout[$TTTI_noCaseVariants]=0
	fi
}

declare -a TTTI_caseVariantPathes=()		#the case path of all case variants
declare -a TTTI_caseVariantIds=()		#the variant id of all cases
declare -a TTTI_caseVariantWorkdirs=()	#the workdir of each variant
declare -a TTTI_casePreambErrors=()		#true if case has peambl error
declare -a TTTI_caseExclusiveExecution=()		#if true the case requires exclusive execution
declare -ai TTTI_caseTimeout=()			#the individual timeout
declare -i TTTI_noCaseVariants=0			#the overall number of case variants
declare variantCount='' variantList='' timeout='' exclusive='' TTTI_preamblError=''
for ((TTTI_i=0; TTTI_i<TTTI_noCases; TTTI_i++)) do
	TTTI_casePath="${TTTI_cases[$TTTI_i]}"
	TTTI_caseName="${TTTI_casePath##*/}"
	variantCount=''; variantList=''; timeout=''; exclusive=''; TTTI_preamblError=''
	if ! TTTF_evalPreambl "${TTTI_casePath}/${TEST_CASE_FILE}"; then
		TTTI_preamblError='true'; variantCount=''; variantList=''; timeout=''; exclusive=''
	fi
	if [[ ( -n $variantCount ) && ( -n $variantList ) ]]; then
		printError "In case ${TTRO_suite}:$TTTI_caseName we have both variant variables variantCount=$variantCount and variantList=$variantList ! Case preamblError"
		TTTI_preamblError='true'; variantCount=''; variantList=''; timeout=''; exclusive=''
	fi
	#echo "variantCount=$variantCount variantList=$variantList"
	if [[ -z $variantCount ]]; then
		if [[ -z $variantList ]]; then
			TTTI_caseVariantPathes[$TTTI_noCaseVariants]="$TTTI_casePath"
			TTTI_caseVariantIds[$TTTI_noCaseVariants]=""
			TTTI_caseVariantWorkdirs[$TTTI_noCaseVariants]="${TTRO_workDirSuite}/${TTTI_caseName}"
			TTTI_casePreambErrors[$TTTI_noCaseVariants]="$TTTI_preamblError"
			setTimeoutInArray
			TTTI_caseExclusiveExecution[$TTTI_noCaseVariants]="$exclusive"
			TTTI_noCaseVariants=$((TTTI_noCaseVariants+1))
		else
			for TTTI_x in $variantList; do
				TTTI_caseVariantPathes[$TTTI_noCaseVariants]="$TTTI_casePath"
				TTTI_caseVariantIds[$TTTI_noCaseVariants]="${TTTI_x}"
				TTTI_caseVariantWorkdirs[$TTTI_noCaseVariants]="${TTRO_workDirSuite}/${TTTI_caseName}/${TTTI_x}"
				TTTI_casePreambErrors[$TTTI_noCaseVariants]="$TTTI_preamblError"
				setTimeoutInArray
				TTTI_caseExclusiveExecution[$TTTI_noCaseVariants]="$exclusive"
				TTTI_noCaseVariants=$((TTTI_noCaseVariants+1))
			done
		fi
	else
		if [[ -z $variantList ]]; then
			for ((TTTI_j=0; TTTI_j<variantCount; TTTI_j++)); do
				TTTI_caseVariantPathes[$TTTI_noCaseVariants]="$TTTI_casePath"
				TTTI_caseVariantIds[$TTTI_noCaseVariants]="${TTTI_j}"
				TTTI_caseVariantWorkdirs[$TTTI_noCaseVariants]="${TTRO_workDirSuite}/${TTTI_caseName}/${TTTI_j}"
				TTTI_casePreambErrors[$TTTI_noCaseVariants]="$TTTI_preamblError"
				setTimeoutInArray
				TTTI_caseExclusiveExecution[$TTTI_noCaseVariants]="$exclusive"
				TTTI_noCaseVariants=$((TTTI_noCaseVariants+1))
			done
			unset TTTI_j
		fi
	fi
done
unset TTTI_i TTTI_casePath TTTI_caseName
unset timeout variantCount variantList exclusive

isVerbose && printVerbose "Execute Suite $TTRO_suite variant='$TTRO_variantSuite' in workdir $TTRO_workDirSuite number of cases=$TTTI_noCases number of case variants=$TTTI_noCaseVariants"

#------------------------------------------------
#execute test suite preparation
TTTT_executionState='preparation'
declare -i TTTI_executedTestPrepSteps=0
for TTTI_name_xyza in 'TTRO_prepsSuite' 'PREPS'; do
	if isExisting "$TTTI_name_xyza"; then
		if isArray "$TTTI_name_xyza"; then
			if isDebug; then
				TTTI_v=$(declare -p "$TTTI_name_xyza")
				printDebug "$TTTI_v"
			fi
			eval "TTTI_l_xyza=\${#$TTTI_name_xyza[@]}"
			for (( TTTI_i_xyza=0; TTTI_i_xyza<TTTI_l_xyza; TTTI_i_xyza++)); do
				eval "TTTI_step_xyza=\${$TTTI_name_xyza[$TTTI_i_xyza]}"
				if isExistingAndTrue 'TTPR_noPrepsSuite'; then
					printInfo "Suppress Suite Preparation: $TTTI_step_xyza"
				else
					printInfo "Execute Suite Preparation: $TTTI_step_xyza"
					TTTI_executedTestPrepSteps=$((TTTI_executedTestPrepSteps+1))
					eval "$TTTI_step_xyza"
				fi
			done
		else
			isDebug && printDebug "$TTTI_name_xyza=${!TTTI_name_xyza}"
			for TTTI_x_xyza in ${!TTTI_name_xyza}; do
				if isExistingAndTrue 'TTPR_noPrepsSuite'; then
					printInfo "Suppress Suite Preparation: $TTTI_x_xyza"
				else
					printInfo "Execute Suite Preparation: $TTTI_x_xyza"
					TTTI_executedTestPrepSteps=$((TTTI_executedTestPrepSteps+1))
					eval "${TTTI_x_xyza}"
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
		TTTI_executedTestPrepSteps=$((TTTI_executedTestPrepSteps+1))
		testPreparation
	fi
fi
printInfo "$TTTI_executedTestPrepSteps Test Suite Preparation steps executed"
TTTF_fixPropsVars

#-------------------------------------------------
#test case execution
TTTT_executionState='execution'

# check for duplicate jobspec in running jobs list
# set jobspec to delete if duplicate was started
function checkDuplicateJobspec {
	local i
	local js
	for ((i=0; i<TTTI_maxParralelJobs; i++)); do
		if [[ -n ${TTTI_tpid[$i]} ]]; then #this job is ment to be running
			js="${TTTI_tjobspec[$i]}"
			#echo "Check index $i list entry $js - value to be inserted $1"
			if [[ -n $js ]]; then #and as a jobspec assigned
				if [[ $js -eq $1 ]]; then
					printError "Jobspec $1 is already in running jobs list at index i=$i ! Delete the jobspec"
					TTTI_tjobspec[$i]='delete'
				fi
			fi
		fi
	done
	return 0
}


if [[ $TTRO_noParallelCases -eq 1 ]]; then
	declare -ri TTTI_maxParralelJobs=1
else
	declare -ri TTTI_maxParralelJobs=$((TTRO_noParallelCases*2))
fi
declare -i TTTI_currentParralelJobs=TTRO_noParallelCases
declare -i TTTI_currentParralelJobsEffective

# do not set timer props here to avoid that nested suites have these props set
declare TTTT_casesTimeout="$defaultTimeout"
if isExisting 'TTPR_timeout'; then
	TTTT_casesTimeout="$TTPR_timeout"
fi
declare TTTT_casesAdditionalTime="$defaultAdditionalTime"
if isExisting 'TTPR_additionalTime'; then
	TTTT_casesAdditionalTime="$TTPR_additionalTime"
fi

declare -a TTTI_tjobspec=()		#the job id of process group (jobspec)
declare -a TTTI_tpid=()			#pid of the case job this is the crucical value of the structure
declare -a TTTI_tcase=()		#the name of the running case
declare -a TTTI_tvariant=()		#the variant of the running case
declare -a TTTI_tcasePath=()	#the input dir of the running case
declare -a TTTI_tstartTime=()
declare -a TTTI_ttimeout=()
declare -a TTTI_tendTime=()
declare -a TTTI_tkilled=()
declare -a TTTI_tcaseWorkDir=()
declare -a TTTI_freeSlots=()	# the list of the free slots (indexes) in above arrays
#init the work structure for maxParralelJobs
for ((TTTI_i=0; TTTI_i<TTTI_maxParralelJobs; TTTI_i++)); do
	TTTI_tjobspec[$TTTI_i]=""; TTTI_tpid[$TTTI_i]=""; TTTI_tcase[$TTTI_i]=""; TTTI_tvariant[$TTTI_i]=""; TTTI_tcasePath[$TTTI_i]=""
	TTTI_tstartTime[$TTTI_i]=""; TTTI_ttimeout[$TTTI_i]=""; TTTI_tstartTime[$TTTI_i]=""; TTTI_tendTime[$TTTI_i]=""
	TTTI_tkilled[$TTTI_i]=""; TTTI_tcaseWorkDir[$TTTI_i]=""
	TTTI_freeSlots+=( $TTTI_i )
done
declare TTTI_allJobsGone=""
declare TTTI_texclusiveExecution=''
declare TTTI_highLoad=''	#true if the system is in high load state
declare -i TTTI_jobIndex=0 #index of next job to start
declare TTTI_nextJobIndexToStart=''	#the index of the next job to start if any, empty if no more job is available (or interrupt)
declare -i TTTI_jobsEnded=0 # the number of ended jobs
#result and summary variables
declare -i TTTI_variantSuccess=0 TTTI_variantSkiped=0 TTTI_variantFailures=0 TTTI_variantErrors=0
declare -i TTTI_numberJobsRunning=0
declare TTTI_sleepCyclesAndNoJobEnds=0
declare TTTI_now=''

# check for timed out jobs and kill them
# TTXX_shell disables timeout check
# expect TTTI_now is actual time
checkJobTimeouts() {
	isDebug && printDebug "check for timed out jobs"
	local i tempjobspec finalTime
	for ((i=0; i<TTTI_maxParralelJobs; i++)); do
		#if [[ ( -n ${TTTI_tpid[$i]} ) && ( -n ${TTTI_tjobspec[$i]} ) ]]; then
		if [[ -n ${TTTI_tpid[$i]} ]]; then
			if [[ -z ${TTTI_tkilled[$i]} ]]; then # the job was not yet killed
				if [[ ( ( ${TTTI_tendTime[$i]} -lt $TTTI_now ) && ( -z $TTXX_shell ) ) || ( $TTTI_interruptReceived -gt 1 ) ]]; then
					if [[ -z ${TTTI_tjobspec[$i]} ]]; then
						tempjobspec="${TTTI_tpid[$i]}"
						printError "tpid $tempjobspec with no jobspec encountered"
					else
						#I now use always uses always the jobspec if available otherwise jobs stucks if a synchro or async job was started from case 
						#if [[ "$TTRO_noParallelCases" -eq 1 ]]; then
						#	tempjobspec="${TTTI_tpid[$i]}"
						#else
							tempjobspec="%${TTTI_tjobspec[$i]}"
						#fi
					fi
					printWarning "Timeout Kill jobspec=${tempjobspec} with SIG${TTTI_sigspec} i=${i} pid=${TTTI_tpid[$i]} case=${TTTI_tcase[$i]} variant=${TTTI_tvariant[$i]}"
					#SIGINT and SIGHUP do not work; can not install handler for both signals in case.sh
					if kill -s $TTTI_sigspec "${tempjobspec}"; then
						echo "timeout" > "${TTTI_tcaseWorkDir[$i]}/TIMEOUT"
					else
						printWarning "Can not kill i=${i} jobspec=${tempjobspec} Gone?"
					fi
					TTTI_tkilled[$i]="$TTTI_now"
				fi
			else
				finalTime=$((${TTTI_tkilled[$i]}+$TTTT_casesAdditionalTime))
				if [[ $TTTI_now -gt $finalTime ]]; then
					#Forced kill uses always the jobspec if available
					if [[ -z ${TTTI_tjobspec[$i]} ]]; then
						tempjobspec="${TTTI_tpid[$i]}"
						printError "tpid $tempjobspec with no jobspec encountered"
					else
						tempjobspec="%${TTTI_tjobspec[$i]}"
					fi
					printError "Forced kill -s KILL i=${i} jobspec=${tempjobspec} case=${TTTI_tcase[$i]} variant=${TTTI_tvariant[$i]} pid=${TTTI_tpid[$i]}"
					if ! kill -9 "${tempjobspec}"; then
						printWarning "Can not force kill -s SIGKILL i=${i} jobspec=${tempjobspec} pid=${TTTI_tpid[$i]} Gone?"
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
	TTTI_freeSlots=()
	local oneJobStopFound=''
	local i
	for ((i=0; i<TTTI_maxParralelJobs; i++)); do
		local pid="${TTTI_tpid[$i]}"
		local jobspec="${TTTI_tjobspec[$i]}"
		if [[ -n $pid ]]; then
			isDebug && printDebug "check wether job is still running i=$i pid=$pid jobspec=%$jobspec"
			local thisJobRuns='true'
			local jobState=''
			if [[ ( "$jobspec" == "error" ) || ( "$jobspec" == "delete" ) ]]; then
				printWarning "Check (expired) job running i=$i jobspec=$jobspec pid=$pid"
				if ps --pid "$pid"; then
					printErrorAndExit "Check (expired) job running i=$i jobspec=$jobspec pid=$pid true"
				fi
				thisJobRuns=''
				jobState="$jobspec"
				printInfo "Job (expired) is gone i=$i jobspec=$jobspec pid=$pid"
			else
				#if ps --pid "$pid" &> /dev/null; then
				#if jobsOutput=$(LC_ALL=en_US jobs "%$jobspec" 2>/dev/null); then ... this does not work in rhel 6 (bash 4.1.2)
				local jobsOutput=''
				local psres="$errSigint"
				while [[ $psres -eq $errSigint ]]; do
					psres=0
					jobsOutput=$(export LC_ALL='en_US.UTF-8'; jobs "%$jobspec" 2>/dev/null) || psres="$?"
				done
				if [[ ( $psres -eq 0 ) && ( -n $jobsOutput ) ]]; then
					local part1="${jobsOutput%%[[:space:]]*}"
					local rest1="${jobsOutput#*[[:space:]]}"
					local TTTT_trim
					trim "$rest1"
					local tmp2="${TTTT_trim%%[[:space:]]*}"
					[[ $part1 =~ \[(.*)\] ]] || printErrorAndExit "Wrong output of jobs command $jobsOutput"
					local tmp3="${BASH_REMATCH[1]}"
					[[ $tmp3 == $jobspec ]] || printErrorAndExit "jobspec from command jobs $tmp3 is not eq jobspec $jobspec"
					if [[ $tmp2 == Done* ]]; then
						thisJobRuns=''
						jobState="$tmp2"
						isDebug && printDebug "Job is Done $tmp3"
					elif [[ $tmp2 == 'Running' ]]; then
						isDebug && printDebug "Job is Running $tmp3"
					else
						printError "Invalid job state $tmp2 jobspec=%$tmp3"
						thisJobRuns=''
						jobState="$tmp2"
					fi
				else
					thisJobRuns=''
					if [[ $psres -eq 0 ]]; then
						jobState="''"
					else
						jobState="exit $psres"
					fi
					isDebug && printDebug "Job is Gone $jobspec"
				fi
			fi
			if [[ -z $thisJobRuns ]]; then
				TTTI_numberJobsRunning=$((TTTI_numberJobsRunning-1))
				oneJobStopFound='true'
				TTTI_jobsEnded=$((TTTI_jobsEnded+1))
				TTTI_freeSlots+=( $i )
				#echo "JOB END"
				local tmpCase="${TTTI_tcase[$i]}"
				local tmpVariant="${TTTI_tvariant[$i]}"
				local tmpCaseAndVariant="${TTRO_suiteNestingString}::${tmpCase}"
				if [[ -n $tmpVariant ]]; then
					tmpCaseAndVariant="${tmpCaseAndVariant}:${tmpVariant}"
				fi
				local caseElapsedTime='?'
				if [[ -e "${TTTI_tcaseWorkDir[$i]}/ELAPSED" ]]; then
					caseElapsedTime=$(<"${TTTI_tcaseWorkDir[$i]}/ELAPSED")
				else
					if [[ -e "${TTTI_tcaseWorkDir[$i]}/STARTTIME" ]]; then
						local caseStartTime=$(<"${TTTI_tcaseWorkDir[$i]}/STARTTIME")
						getElapsedTime "$caseStartTime"
						caseElapsedTime="$TTTT_elapsedTime"
					fi
				fi
				echo "$tmpCaseAndVariant : $caseElapsedTime" >> "${TTRO_workDirSuite}/CASE_EXECUTE"
				printInfon "END:   case=${tmpCase} variant='${tmpVariant}'           i=$i running=$TTTI_numberJobsRunning systemLoad=$TTTT_systemLoad maxJobs=$TTTI_currentParralelJobsEffective jobspec=%$jobspec pid=$pid state=$jobState"
				TTTI_tpid[$i]=""
				TTTI_tjobspec[$i]=""
				TTTI_texclusiveExecution=''
				#collect variant result
				local jobsResultFile="${TTTI_tcaseWorkDir[$i]}/RESULT"
				if [[ -e ${jobsResultFile} ]]; then
					local jobsResult=$(<"${jobsResultFile}")
					case "$jobsResult" in
						SUCCESS )
							echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/CASE_SUCCESS"
							TTTI_variantSuccess=$((TTTI_variantSuccess+1))
							TTTF_addCaseEntry "$TTTI_indexfilename" "$tmpCase" "$tmpVariant" 'SUCCESS' "${TTTI_tcasePath[$i]}" "${TTTI_tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTI_tempSummayName"
						;;
						SKIP )
							{ if read -r; then :; fi; } < "${TTTI_tcaseWorkDir[$i]}/REASON" #read one line from reason
							echo "$tmpCaseAndVariant: $REPLY" >> "${TTRO_workDirSuite}/CASE_SKIP"
							TTTI_variantSkiped=$((TTTI_variantSkiped+1))
							TTTF_addCaseEntry "$TTTI_indexfilename" "$tmpCase" "$tmpVariant" 'SKIP' "${TTTI_tcasePath[$i]}" "${TTTI_tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTI_tempSummayName"
						;;
						FAILURE )
							{ if read -r; then :; fi; } < "${TTTI_tcaseWorkDir[$i]}/REASON" #read one line from reason
							echo "$tmpCaseAndVariant: $REPLY" >> "${TTRO_workDirSuite}/CASE_FAILURE"
							TTTI_variantFailures=$((TTTI_variantFailures+1))
							TTTF_addCaseEntry "$TTTI_indexfilename" "$tmpCase" "$tmpVariant" 'FAILURE' "${TTTI_tcasePath[$i]}" "${TTTI_tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTI_tempSummayName"
							[[ ( -n $TTRO_xtraPrint ) && ( "$TTRO_noParallelCases" -ne 1 ) ]] && cat "${TTTI_tcaseWorkDir[$i]}/${TEST_LOG}"
						;;
						ERROR )
							echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/CASE_ERROR"
							TTTI_variantErrors=$((TTTI_variantErrors+1))
							TTTF_addCaseEntry "$TTTI_indexfilename" "$tmpCase" "$tmpVariant" 'ERROR' "${TTTI_tcasePath[$i]}" "${TTTI_tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTI_tempSummayName"
							[[ ( -n $TTRO_xtraPrint ) && ( "$TTRO_noParallelCases" -ne 1 ) ]] && cat "${TTTI_tcaseWorkDir[$i]}/${TEST_LOG}"
						;;
						* )
							printError "${tmpCase}:${tmpVariant} : Invalid Case-variant result $jobsResult case workdir ${TTTI_tcaseWorkDir[$i]}"
							echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/CASE_ERROR"
							TTTI_variantErrors=$((TTTI_variantErrors+1))
							TTTF_addCaseEntry "$TTTI_indexfilename" "$tmpCase" "$tmpVariant" 'ERROR' "${TTTI_tcasePath[$i]}" "${TTTI_tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTI_tempSummayName"
							jobsResult="ERROR"
							[[ ( -n $TTRO_xtraPrint ) && ( "$TTRO_noParallelCases" -ne 1 ) ]] && cat "${TTTI_tcaseWorkDir[$i]}/${TEST_LOG}"
						;;
					esac
				else
					printError "No RESULT file in case workdir ${TTTI_tcaseWorkDir[$i]}"
					echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/CASE_ERROR"
					TTTI_variantErrors=$((TTTI_variantErrors+1))
					TTTF_addCaseEntry "$TTTI_indexfilename" "$tmpCase" "$tmpVariant" 'ERROR' "${TTTI_tcasePath[$i]}" "${TTTI_tcaseWorkDir[$i]}" "$caseElapsedTime" "$TTTI_tempSummayName"
					jobsResult="ERROR"
					[[ ( -n $TTRO_xtraPrint ) && ( "$TTRO_noParallelCases" -ne 1 ) ]] && cat "${TTTI_tcaseWorkDir[$i]}/${TEST_LOG}"
				fi
				echo " Result: $jobsResult"
			fi
		else
			TTTI_freeSlots+=( $i )
		fi
	done
	if [[ -n $oneJobStopFound ]]; then
		TTTI_sleepCyclesAndNoJobEnds=0
	fi
} # /handleJobEnd

#wait if no slot is free an not allJobsGone
sleepIf() {
	if [[ ( -n $TTTI_nextJobIndexToStart && ( $TTTI_numberJobsRunning -ge $TTTI_currentParralelJobsEffective ) ) || ( -z $TTTI_nextJobIndexToStart && -z $TTTI_allJobsGone ) ]]; then
		local waitTime='0.2'
		if [[ $TTTI_sleepCyclesAndNoJobEnds -ge 10 ]]; then
			TTTI_sleepCyclesAndNoJobEnds=$((TTTI_sleepCyclesAndNoJobEnds+1))
			waitTime='1'
		else
			TTTI_sleepCyclesAndNoJobEnds=$((TTTI_sleepCyclesAndNoJobEnds+1))
		fi
		if [[ $TTTI_sleepCyclesAndNoJobEnds -eq 1 ]]; then
			printInfo "SLEEP $waitTime"
		else
			echo -e -n "SLEEP $waitTime sleepCyclesAndNoJobEnds=$TTTI_sleepCyclesAndNoJobEnds      \r" #add some spaces at end to clean the prevois numbers
		fi
		isDebug && printDebug "sleep $waitTime sleepCyclesAndNoJobEnds=$TTTI_sleepCyclesAndNoJobEnds"
		if sleep "$waitTime"; then
			isDebug && printDebug "sleep returns success"
		else
			local cresult=$?
			if [[ $cresult -eq 130 ]]; then
				printInfo "SIGINT received in sleep in programm $TTTI_commandname ********************"
			else
				printError "Unhandled result $cresult after sleep"
			fi
		fi
	fi
	return 0
}

# Start one or more new job(s)
# expect TTTI_now is actual time
startNewJobs() {
	local freeSlotIndx=0
	if checkExclusiveRequest; then TTTI_currentParralelJobsEffective=1; else TTTI_currentParralelJobsEffective="$TTTI_currentParralelJobs"; fi
	while [[ -n $TTTI_nextJobIndexToStart && ( $TTTI_numberJobsRunning -lt $TTTI_currentParralelJobsEffective ) ]]; do
		if [[ $freeSlotIndx -ge ${#TTTI_freeSlots[*]} ]]; then printErrorAndExit "No free slot but one job to start freeSlotIndx=$freeSlotIndx free slots=${#TTTI_freeSlots[*]}" $errRt; fi
		local freeSlot="${TTTI_freeSlots[$freeSlotIndx]}"; freeSlotIndx=$((freeSlotIndx+1));
		local casePath="${TTTI_caseVariantPathes[$TTTI_nextJobIndexToStart]}"
		local caseName="${casePath##*/}"
		local caseVariant="${TTTI_caseVariantIds[$TTTI_nextJobIndexToStart]}"
		local cworkdir="${TTTI_caseVariantWorkdirs[$TTTI_nextJobIndexToStart]}"
		local cpreamblError="${TTTI_casePreambErrors[$TTTI_nextJobIndexToStart]}"
		local caseExclusiveExecution="${TTTI_caseExclusiveExecution[$TTTI_nextJobIndexToStart]}"
		#make and cleanup case work dir
		if [[ -e $cworkdir ]]; then
			printErrorAndExit "Case workdir exists! Probably duplicate variant. workdir: $cworkdir" $errSuiteError
		fi
		mkdir -p "$cworkdir"
		local cmd="${TTRO_scriptDir}/case.sh"
		TTTI_numberJobsRunning=$((TTTI_numberJobsRunning+1))
		printInfon "START: case=$caseName variant='$caseVariant' jobIndex=$TTTI_nextJobIndexToStart i=$freeSlot running=$TTTI_numberJobsRunning systemLoad=$TTTT_systemLoad maxJobs=$TTTI_currentParralelJobsEffective"
		#Start job connect output to stdout in single thread case
		local commandString
		if [[ "$TTRO_noParallelCases" -eq 1 ]]; then
			commandString="$cmd $casePath $cworkdir $caseVariant $cpreamblError 2>&1 | tee -i ${cworkdir}/${TEST_LOG}"
			$cmd "$casePath" "$cworkdir" "$caseVariant" "$cpreamblError" 2>&1 | tee -i "${cworkdir}/${TEST_LOG}" &
			local newPid=$!
		else
			commandString="$cmd $casePath $cworkdir $caseVariant $cpreamblError &> ${cworkdir}/${TEST_LOG}"
			$cmd "$casePath" "$cworkdir" "$caseVariant" "$cpreamblError" &> "${cworkdir}/${TEST_LOG}" &
			local newPid=$!
		fi
		#jobsOutput=$(LC_ALL=en_US jobs %+)  ... this does not work in rhel 6 (bash 4.1.2)
		local jobsOutput=''
		local newPidLead=''
		local jobState=''
		local thisJobspec=''
		local psres="$errSigint"
		while [[ $psres -eq $errSigint ]]; do #repeat command if interrupted
			psres=0;
			jobsOutput=$(export LC_ALL='en_US.UTF-8'; jobs -l %+) || psres=$?
		done
		if [[ ( $psres -eq 0 ) && ( -n "$jobsOutput" ) ]]; then
			echo "$jobsOutput" > "$cworkdir/JOBS"
			echo "Full Job list" >> "$cworkdir/JOBS"
			LC_ALL='en_US.UTF-8' jobs -l >> "$cworkdir/JOBS"
			isDebug && printDebug "jobspec:$jobsOutput"
			local part1="${jobsOutput%%[[:space:]]*}"
			local rest1="${jobsOutput#*[[:space:]]}"
			local TTTT_trim
			trim "$rest1"
			newPidLead="${TTTT_trim%%[[:space:]]*}"
			rest1="${TTTT_trim#*[[:space:]]}"
			trim "$rest1"
			jobState="${TTTT_trim%%[[:space:]]*}"
			if [[ $part1 =~ \[(.*)\]\+ ]]; then
				thisJobspec="${BASH_REMATCH[1]}"
				echo " jobspec=%$thisJobspec leadPid=$newPidLead state=$jobState"
				checkDuplicateJobspec "$thisJobspec"
			else
				echo
				printErrorAndExit "No jobindex extract from jobs output '$jobsOutput'" $errRt
			fi
		else
			newPidLead="$newPid"
			thisJobspec='error'
		fi
		TTTI_tpid[$freeSlot]="$newPidLead"
		TTTI_tjobspec[$freeSlot]="$thisJobspec"
		TTTI_tcase[$freeSlot]="$caseName"
		TTTI_tvariant[$freeSlot]="$caseVariant"
		TTTI_tcasePath[$freeSlot]="$casePath"
		TTTI_tcaseWorkDir[$freeSlot]="$cworkdir"
		TTTI_tkilled[$freeSlot]=""
		isDebug && printDebug "Enter free slot=$freeSlot tjobspec[$freeSlot]=${thisJobspec} tpid[${freeSlot}]=$newPidLead time=${TTTI_now} state=$jobState"
		TTTI_tstartTime[$freeSlot]="$TTTI_now"
		local jobTimeout=${TTTI_caseTimeout[$TTTI_jobIndex]}
		if [[ $jobTimeout -lt $TTTT_casesTimeout ]]; then
			jobTimeout="$TTTT_casesTimeout"
		fi
		isVerbose && printVerbose "Job timeout $jobTimeout"
		TTTI_tendTime[$freeSlot]=$((TTTI_now+jobTimeout))
		TTTI_ttimeout[$freeSlot]="$jobTimeout"
		TTTI_texclusiveExecution="$caseExclusiveExecution"
		TTTI_jobIndex=$((TTTI_jobIndex+1))
		if [[ ( $TTTI_interruptReceived -gt 0 ) || ( $TTTI_jobIndex -ge $TTTI_noCaseVariants ) ]]; then
			TTTI_nextJobIndexToStart=''
		else
			TTTI_nextJobIndexToStart="$TTTI_jobIndex"
		fi
		if checkExclusiveRequest; then TTTI_currentParralelJobsEffective=1; else TTTI_currentParralelJobsEffective="$TTTI_currentParralelJobs"; fi
	done
} #/startNewJobs

# set up the currentParralelJobs
# depending on system load
#  requires $TTTT_systemLoad
checkSystemLoad() {
	:
}

# check whether exclusive execution is active
# return true if so
checkExclusiveRequest() {
	if [[ -n $TTTI_nextJobIndexToStart ]]; then
		if [[ -n ${TTTI_caseExclusiveExecution[$TTTI_nextJobIndexToStart]} ]]; then
			isDebug && printDebug "next job to start $TTTI_nextJobIndexToStart requires exclusive execution"
			return 0
		fi
	fi
	if [[ -n ${TTTI_texclusiveExecution} ]]; then
		isDebug && printDebug "curren running job requires exclusive execution"
		return 0
	fi
	return 1
}

#print special summary
TTTI_tempSummayName="${TTRO_workDirSuite}/part1.tmp"
rm -f "$TTTI_tempSummayName"
touch "$TTTI_tempSummayName"

#the loop until all jobs are gone
if [[ $TTTI_noCaseVariants -gt 0 ]]; then
	TTTI_nextJobIndexToStart=0
else
	TTTI_nextJobIndexToStart=''
fi
TTTI_currentParralelJobsEffective="$TTTI_currentParralelJobs"
while [[ -z $TTTI_allJobsGone ]]; do
	isDebug && printDebug "Loop precond allJobsGone='${TTTI_allJobsGone}' jobIndex='${TTTI_nextJobIndexToStart}'"
	# loop either not the final job and no job slot is available or the final job and not all jobs gone
	if checkExclusiveRequest; then TTTI_currentParralelJobsEffective=1; else TTTI_currentParralelJobsEffective="$TTTI_currentParralelJobs"; fi
	while [[ ( -n $TTTI_nextJobIndexToStart && ( $TTTI_numberJobsRunning -ge $TTTI_currentParralelJobsEffective ) || ( ${#TTTI_freeSlots[*]} -eq 0 ) ) || ( -z $TTTI_nextJobIndexToStart && -z $TTTI_allJobsGone ) ]]; do
		isDebug && printDebug "Loop cond numberJobsRunning='$TTTI_numberJobsRunning' currentParralelJobs='$TTTI_currentParralelJobs' allJobsGone='$TTTI_allJobsGone' nextJobIndexToStart='$TTTI_nextJobIndexToStart' currentParralelJobsEffective=$TTTI_currentParralelJobsEffective"
		while ! TTTI_now="$(date +'%-s')"; do :; done #guard external command if sigint is received
		checkJobTimeouts
		getSystemLoad100
		checkSystemLoad
		handleJobEnd
		if [[ $TTTI_interruptReceived -gt 0 ]]; then
			TTTI_nextJobIndexToStart=''
			isVerbose && printVerbose "Interrupt suite $TTRO_suite interruptReceived=$TTTI_interruptReceived ****"
		fi
		#during final job run: check that all jobs are gone
		if [[ -z $TTTI_nextJobIndexToStart && ( $TTTI_numberJobsRunning -eq 0 ) ]]; then
			isDebug && printDebug "All jobs gone"
			#echo "ALL JOBS GONE"
			TTTI_allJobsGone="true"
		fi
		if checkExclusiveRequest; then TTTI_currentParralelJobsEffective=1; else TTTI_currentParralelJobsEffective="$TTTI_currentParralelJobs"; fi
		sleepIf
		isDebug && printDebug "Loop POST cond numberJobsRunning='$TTTI_numberJobsRunning' currentParralelJobs='$TTTI_currentParralelJobs' allJobsGone='$TTTI_allJobsGone' nextJobIndexToStart='$TTTI_nextJobIndexToStart' currentParralelJobsEffective=$TTTI_currentParralelJobsEffective"
	done
	while ! TTTI_now="$(date +'%-s')"; do :; done #guard external command if sigint is received
	getSystemLoad100
	startNewJobs
done

#check number of jobs ended and job index
if [[ $TTTI_jobIndex -ne $TTTI_jobsEnded ]]; then
	printError "The nuber of jobs started=$TTTI_jobIndex is not equal to the number of jobs ended=$TTTI_jobsEnded"
fi

#fin
TTTF_startSuiteList "$TTTI_indexfilename"

checkGlobalVarsUsed

##execution loop over sub suites and variants
declare -i TTTI_suiteVariants=0 TTTI_suiteErrors=0 TTTI_suiteSkip=0
for TTTI_sindex_xyza in ${TTTI_childSuites[$TTRO_suiteIndex]}; do
	TTTI_suitePath="${TTTI_suitesPath[$TTTI_sindex_xyza]}"
	TTTI_suite="${TTTI_suitesName[$TTTI_sindex_xyza]}"
	if [[ $TTTI_interruptReceived -gt 0 ]]; then
		printInfo "SIGINT: end Suites loop"
		break
	fi
	isVerbose && printVerbose "**** START Nested Suite: $TTTI_suite ************************************"
	variantCount=""; variantList=""; timeout=''; TTTI_preamblError=""; exclusive=''
	if ! TTTF_evalPreambl "${TTTI_suitePath}/${TEST_SUITE_FILE}"; then
		TTTI_preamblError='true'; variantCount=""; variantList=""; timeout=''; exclusive=''
	fi
	if [[ ( -n $variantCount ) && ( -n $variantList ) ]]; then
		printError "In suite $TTTI_suite we have both variant variables variantCount=$variantCount and variantList=$variantList ! Suite preamblError"
		TTTI_preamblError='true'; variantCount=""; variantList=""; timeout=''; exclusive=''
	fi
	if [[ -n $timeout || -n $exclusive ]]; then
		printError "In suite $TTTI_suite timeout or exclusive is not expected in Suite preambl! Suite preamblError"
		TTTI_preamblError='true'; variantCount=""; variantList=""; timeout=''; exclusive=''
	fi
	if [[ -z $variantCount ]]; then
		if [[ -z $variantList ]]; then
 			TTTF_exeSuite "$TTTI_sindex_xyza" "" "$TTRO_suiteNestingLevel" "$TTRO_suiteNestingPath" "$TTRO_suiteNestingString" "$TTRO_workDirSuite" "$TTTI_preamblError" "$TTTI_indexfilename"
		else
			for TTTI_x_xyza in $variantList; do
				TTTF_exeSuite "$TTTI_sindex_xyza" "$TTTI_x_xyza" "$TTRO_suiteNestingLevel" "$TTRO_suiteNestingPath" "$TTRO_suiteNestingString" "$TTRO_workDirSuite" "$TTTI_preamblError" "$TTTI_indexfilename"
				if [[ $TTTI_interruptReceived -gt 0 ]]; then
					printInfo "SIGINT: end Suites loop"
					break
				fi
			done
			unset TTTI_x_xyza
		fi
	else
		if [[ -z $variantList ]]; then
			declare -i TTTI_j_xyza
			for ((TTTI_j_xyza=0; TTTI_j_xyza<variantCount; TTTI_j_xyza++)); do
				TTTF_exeSuite "$TTTI_sindex_xyza" "$TTTI_j_xyza" "$TTRO_suiteNestingLevel" "$TTRO_suiteNestingPath" "$TTRO_suiteNestingString" "$TTRO_workDirSuite" "$TTTI_preamblError" "$TTTI_indexfilename"
				if [[ $TTTI_interruptReceived -gt 0 ]]; then
					printInfo "SIGINT: end Suites loop"
					break
				fi
			done
			unset TTTI_j_xyza
		fi
	fi
	isVerbose && printVerbose "**** END Nested Suite: $TTTI_suite **************************************"
	if [[ $TTTI_interruptReceived -gt 0 ]]; then
		printInfo "SIGINT: end Suites loop"
		break
	fi
done
unset TTTI_sindex_xyza
unset timeout variantCount variantList

#test suite finalization
TTTT_executionState='finalization'
declare -i TTTI_executedTestFinSteps=0
if isFunction 'testFinalization'; then
	if isExisting 'FINS' || isExisting 'TTRO_finSuite'; then
		printErrorAndExit "You must not use FINS or TTRO_finSuite variable together with testFinalization function" $errRt
	fi
fi
for TTTI_name_xyza in 'TTRO_finSuite' 'FINS'; do
	if isExisting "$TTTI_name_xyza"; then
		if isArray "$TTTI_name_xyza"; then
			if isDebug; then
				TTTI_v=$(declare -p "$TTTI_name_xyza")
				printDebug "$TTTI_v"
			fi
			eval "TTTI_l_xyza=\${#$TTTI_name_xyza[@]}"
			for (( TTTI_i_xyza=0; TTTI_i_xyza<TTTI_l_xyza; TTTI_i_xyza++)); do
				eval "TTTI_step_xyza=\${$TTTI_name_xyza[$TTTI_i_xyza]}"
				if isExistingAndTrue 'TTPR_noFinsSuite'; then
					printInfo "Suppress Suite Finalization: $TTTI_step_xyza"
				else
					printInfo "Execute Suite Finalization: $TTTI_step_xyza"
					TTTI_executedTestFinSteps=$((TTTI_executedTestFinSteps+1))
					eval "$TTTI_step_xyza"
				fi
			done
		else
			isDebug && printDebug "$TTTI_name_xyza=${!TTTI_name_xyza}"
			for TTTI_x_xyza in ${!TTTI_name_xyza}; do
				if isExistingAndTrue 'TTPR_noFinsSuite'; then
					printInfo "Suppress Suite Finalization: $TTTI_x_xyza"
				else
					printInfo "Execute Suite Finalization: $TTTI_x_xyza"
					TTTI_executedTestFinSteps=$((TTTI_executedTestFinSteps+1))
					eval "${TTTI_x_xyza}"
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
		TTTI_executedTestFinSteps=$((TTTI_executedTestFinSteps+1))
		testFinalization
	fi
fi
printInfo "$TTTI_executedTestFinSteps Test Suite Finalisation steps executed"

#-------------------------------------------------------
#put results to results file for information purose only
echo -e "CASE_EXECUTE=$TTTI_jobIndex\nCASE_FAILURE=$TTTI_variantFailures\nCASE_ERROR=$TTTI_variantErrors\nCASE_SKIP=$TTTI_variantSkiped\nCASE_SUCCESS=$TTTI_variantSuccess" > "${TTRO_workDirSuite}/RESULT"
echo -e "SUITE_EXECUTE=$TTTI_suiteVariants\nSUITE_ERROR=$TTTI_suiteErrors\nSUITE_SKIP=$TTTI_suiteSkip" >> "${TTRO_workDirSuite}/RESULT"

#-------------------------------------------------------
#Final verbose suite result printout
echo "**** Results Suite: suite='$TTRO_suite' variant='$TTRO_variantSuite' ****"
for TTTI_x in CASE_EXECUTE CASE_SKIP CASE_FAILURE CASE_ERROR CASE_SUCCESS SUITE_EXECUTE SUITE_SKIP SUITE_ERROR; do
	TTTI_tmp="${TTRO_workDirSuite}/${TTTI_x}"
	eval "${TTTI_x}_NO=0"
	isVerbose && printVerbose "**** $TTTI_x List : ****"
	if [[ -e ${TTTI_tmp} ]]; then
		{
			while read; do
				if [[ $REPLY != \#* ]]; then
					eval "${TTTI_x}_NO=\$((${TTTI_x}_NO+1))"
				fi
				isVerbose && printVerbose "$REPLY "
			done
		} < "$TTTI_tmp"
	else
		printErrorAndExit "No result file ${TTTI_tmp} exists" $errRt
	fi
	TTTI_tmp3="${TTTI_x}_NO"
	isDebug && printDebug "Overall $TTTI_x = ${!TTTI_tmp3}"
done

# html
getElapsedTime "$TTTT_suiteStartTime"
TTTF_endSuiteIndex "$TTTI_indexfilename" "$TTTT_elapsedTime"

declare TTTI_suiteResult=0
if [[ $TTTI_interruptReceived -gt 0 ]]; then
	TTTI_suiteResult=$errSigint
fi

echo "**** cases=$TTTI_jobIndex failures=$TTTI_variantFailures errors=$TTTI_variantErrors skipped=$TTTI_variantSkiped *****"
echo "**** Elapsed time : $TTTT_elapsedTime *****"
echo "$TTTT_elapsedTime" > "${TTRO_workDirSuite}/ELAPSED"

#---------------------------------------------------------------------------------
#print special summary
if [[ -n $TTXX_summary ]]; then
	TTTI_sname="${TTRO_suite}"
	#if [[ -z $TTTI_sname ]]; then TTTI_sname='Dummy'; fi
	if [[ -n ${TTRO_variantSuite} ]]; then TTTI_sname="${TTTI_sname}_${TTRO_variantSuite}"; fi
	TTTI_reportfile0="${TTRO_workDirSuite}/${TTTI_sname}_part0.tmp"
	TTTI_reportfile="${TTRO_workDirSuite}/${TTTI_sname}_summary.txt"
	echo "Testsuite: ${TTTI_sname}" > "$TTTI_reportfile0"
	echo -e "Tests run: $TTTI_jobIndex, Failures: $TTTI_variantFailures, Errors: $TTTI_variantErrors, Skipped: $TTTI_variantSkiped, Time elapsed: ${TTTT_elapsedTime}\n" >> "$TTTI_reportfile0"
	cat "$TTTI_reportfile0" "$TTTI_tempSummayName" > "$TTTI_reportfile"
	rm -f "$TTTI_reportfile0"
fi
rm -f "$TTTI_tempSummayName"

builtin echo -n "$TTTI_suiteResult" > "${TTRO_workDirSuite}/DONE"

isDebug && printDebug "END: Suite '$TTRO_suite' variant='$TTRO_variantSuite' suite exit code $TTTI_suiteResult"

exit $TTTI_suiteResult
