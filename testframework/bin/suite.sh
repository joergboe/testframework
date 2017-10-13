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

# Function handle SIGINT
function handleSigint {
	if [[ $interruptReceived -eq 0 ]]; then
		echo "SIGINT: Test Suite will be stopped. To interrupt running test cases press ^C again"
		interruptReceived=1
	elif [[ $interruptReceived -eq 1 ]]; then
		interruptReceived=$((interruptReceived+1))
		echo "SIGINT: Test cases will be stopped"
	elif [[ $interruptReceived -gt 2 ]]; then
		interruptReceived=$((interruptReceived+1))
		echo "SIGINT: Abort Suite"
		exit $errSigint
	else
		interruptReceived=$((interruptReceived+1))	
	fi
	return 0
}

# Function interruptSignalSuite
function interruptSignalSuite {
	echo "SIGINT received in test suite execution programm $commandname ********************"
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

# usage and parameters
function usage {
	local command=${0##*/}
	cat <<-EOF
	
	usage: ${command} suite suitePath suiteWorkdir suiteVariant [case [ case ...]];
	
	EOF
}
isDebug && printDebug "$0 $*"
if [[ $# -lt 4 ]]; then
	usage
	exit ${errInvocation}
fi
#move all parameters into named variables
declare -rx TTRO_suite="$1"; shift
declare -rx TTRO_inputDirSuite="$1"; shift
declare -rx TTRO_workDirSuite="$1"; shift
declare -rx TTRO_suiteVariant="$1"; shift
declare -a cases=() # case pathes
declare -i noCases=0
while [[ $# -ge 1 ]]; do
	cases[$noCases]="$1"
	noCases=$((noCases+1))
	shift
done
readonly cases noCases
isDebug && printDebug "noCases=$noCases"

#--------------------------------------------------
# enter working dir
cd "$TTRO_workDirSuite"

#-------------------------------------
# include tools
for x in $TT_tools; do
	isVerbose && echo "Source global tools file: $x"
	source "$x"
	fixPropsVars
done

if [[ $TTRO_suite != '--' ]]; then
	tmp="${TTRO_inputDirSuite}/${TEST_SUITE_FILE}"
	if [[ -e "$tmp" ]]; then
		isVerbose && echo  "Source Suite file $tmp"
		source "$tmp"
		fixPropsVars
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

#--------------------------------------------------
# prepare output lists
for x in VARIANT SUCCESS SKIP FAILURE ERROR; do
	tmp="${TTRO_workDirSuite}/${x}_LIST"
	if [[ -e $tmp ]]; then
		printError "Result list exists in suite $TTRO_suite list: $tmp"
		rm -rf "$tmp"
	fi
	builtin echo "#case[:variant]" > "$tmp"
done
tmp="${TTRO_workDirSuite}/RESULT"
if [[ -e $tmp ]]; then
	printError "Result file exists in suite $TTRO_suite list: $tmp"
	rm -rf "$tmp"
fi
touch "$tmp"

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
declare -ai caseTimeout=()			#the individual timeout
declare -i noCaseVariants=0			#the overall number of case variants
declare variantCount variantList
for ((i=0; i<noCases; i++)) do
	casePath="${cases[$i]}"
	caseName="${casePath##*/}"
	unset timeout
	readVariantFile "${casePath}/${TEST_CASE_FILE}" "case"
	#echo "variantCount=$variantCount variantList=$variantList"
	if [[ -z $variantCount ]]; then
		if [[ -z $variantList ]]; then
			caseVariantPathes[$noCaseVariants]="$casePath"
			caseVariantIds[$noCaseVariants]=""
			caseVariantWorkdirs[$noCaseVariants]="${TTRO_workDirSuite}/${caseName}"
			setTimeoutInArray
			noCaseVariants=$((noCaseVariants+1))
		else
			for x in $variantList; do
				caseVariantPathes[$noCaseVariants]="$casePath"
				caseVariantIds[$noCaseVariants]="${x}"
				caseVariantWorkdirs[$noCaseVariants]="${TTRO_workDirSuite}/${caseName}/${x}"
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
				setTimeoutInArray
				noCaseVariants=$((noCaseVariants+1))
			done
			unset j
		else
			printError "ERROR: In case ${TTRO_suite}:$caseName we have both variant variables variantCount=$variantCount and variantList=$variantList ! Case is skipped"
		fi
	fi
done
unset i casePath caseName
unset timeout variantCount variantList

isVerbose && echo "Execute Suite $TTRO_suite variant='$TTRO_suiteVariant' in workdir $TTRO_workDirSuite number of cases=$noCases number of case variants=$noCaseVariants"

#------------------------------------------------
# diagnostics
isVerbose && printTestframeEnvironment
printTestframeEnvironment > "${TTRO_workDirSuite}/${TEST_ENVIRONMET_LOG}"
export >> "${TTRO_workDirSuite}/${TEST_ENVIRONMET_LOG}"

#------------------------------------------------
#execute test suite preparation
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
				if isExistingAndTrue 'TTPN_noPrepsSuite'; then
					isVerbose && echo "Suppress Suite Preparation: $step_xyza"
				else
					isVerbose && echo "Execute Suite Preparation: $step_xyza"
					executedTestPrepSteps=$((executedTestPrepSteps+1))
					eval "$step_xyza"
				fi
			done
		else
			isDebug && printDebug "$name_xyza=${!name_xyza}"
			for x_xyza in ${!name_xyza}; do
				if isExistingAndTrue 'TTPN_noPrepsSuite'; then
					isVerbose && echo "Suppress Suite Preparation: $x_xyza"
				else
					isVerbose && echo "Execute Suite Preparation: $x_xyza"
					executedTestPrepSteps=$((executedTestPrepSteps+1))
					eval "${x_xyza}"
				fi
			done
		fi
	fi
done
if isFunction 'testPreparation'; then
	if isExistingAndTrue 'TTPN_noPrepsSuite'; then
		isVerbose && echo "Suppress Suite Preparation function testPreparation"
	else
		isVerbose && echo "Execute Suite Preparation function testPreparation"
		executedTestPrepSteps=$((executedTestPrepSteps+1))
		testPreparation
	fi
fi
isVerbose && echo "$executedTestPrepSteps Test Suite Preparation steps executed"

#-------------------------------------------------
#test case execution
unset x
if [[ $TTRO_noParallelCases -eq 1 ]]; then
	declare -ri maxParralelJobs=1
else
	declare -ri maxParralelJobs=$((TTRO_noParallelCases*2))
fi
declare -i currentParralelJobs=TTRO_noParallelCases

setVar 'TTP_timeout' "$defaultTimeout"
setVar 'TTP_additionalTime' "$defaultAdditionalTime"
declare -a tjobid=()	#the job id of process group
declare -a tpid=()		#pid of the case job this is the crucical value of the structure
declare -a tcase=()		#the name of the running case
declare -a tvariant=()	#the variant of the running case
declare -a startTime=()
declare -a timeout=()
declare -a endTime=()
declare -a killed=()
declare -a tcaseWorkDir=()
declare availableTpidIndex=""
declare allJobsGone=""
declare -i jobIndex=0 #index of job next to start
#result and summary variables
declare -i variantSuccess=0 variantSkiped=0 variantFailures=0 variantErrors=0

#init the work structure for maxParralelJobs
for ((i=0; i<maxParralelJobs; i++)); do
	tjobid[$i]=""
	tpid[$i]=""
	tcase[$i]=""
	tvariant[$i]=""
	startTime[$i]=""
	timeout[$i]=""
	startTime[$i]=""
	endTime[$i]=""
	killed[$i]=""
	tcaseWorkDir[$i]=""
done

declare casePath caseName caseVariant
#the loop until all jobs are gone
while [[ -z $allJobsGone ]]; do
	if [[ $jobIndex -lt $noCaseVariants ]]; then
		casePath="${caseVariantPathes[$jobIndex]}"
		caseName="${casePath##*/}"	#a new case is to be started
		caseVariant="${caseVariantIds[$jobIndex]}"
		isVerbose && echo "jobIndex=$jobIndex Try to start $caseName variant '$caseVariant'"
	else
		casePath=""
		caseName=""		#no new case to start
		caseVariant=""
		isVerbose && echo "Last job of suite $TTRO_suite reached ****"
	fi
	availableTpidIndex=""
	isDebug && printDebug "Loop precond availableTpidIndex='${availableTpidIndex}' allJobsGone='${allJobsGone}' caseName='${caseName}' variant='${caseVariant}'"
	# loop either not the final job and no job slot is available or the final job and not all jobs gone
	while [[ ( -n $caseName && -z ${availableTpidIndex} ) || ( -z $caseName && -z $allJobsGone ) ]]; do
		isDebug && printDebug "Loop cond availableTpidIndex='${availableTpidIndex}' allJobsGone='${allJobsGone}' caseName='${caseName}' variant='${caseVariant}'"
		if [[ $interruptReceived -gt 0 ]]; then
			casePath=""
			caseName=""		#no new case to start
			caseVariant=""
			isVerbose && echo "Interrupt suite $TTRO_suite interruptReceived=$interruptReceived ****"
		fi
		#during normal run check for one available job space
		if [[ -n $caseName ]]; then
			for ((i=0; i<currentParralelJobs; i++)); do
				isDebug && printDebug "Check free index $i"
				if [[ -z ${tpid[$i]} ]]; then
					isDebug && printDebug "Index $i is free"
					availableTpidIndex=$i
					break
				fi
			done
		fi
		#check for timed out jobs
		isDebug && printDebug "check for timed out jobs"
		while ! now="$(date +'%-s')"; do #guard external command if sigint is received
			:
		done
		for ((i=0; i<maxParralelJobs; i++)); do
			if [[ -n ${tpid[$i]} ]]; then
				if [[ -z ${killed[$i]} ]]; then
					if [[ ( ${endTime[$i]} -lt $now ) || ( $interruptReceived -gt 1 ) ]]; then
						if [[ -z ${tjobid[$i]} ]]; then
							tempjobspec="${tpid[$i]}"
						else
							tempjobspec="%${tjobid[$i]}"
						fi
						echo "INFO: Timeout Kill job i=${i} jobspec=${tempjobspec} with SIGTERM"
						#SIGINT and SIGHUP seems not to work can not install handler for both signals in case.sh
						if ! kill "${tempjobspec}"; then
							printWarning "Can not kill job i=${i} jobspec=${tempjobspec} Gone?"
						fi
						killed[$i]="$now"
					fi
				else
					tmp=$((${killed[$i]}+$TTP_additionalTime))
					if [[ $now -gt $tmp ]]; then
						if [[ -z ${tjobid[$i]} ]]; then
							tempjobspec="${tpid[$i]}"
						else
							tempjobspec="%${tjobid[$i]}"
						fi
						printError "Forced Kill job i=${i} jobspec=${tempjobspec}"
						if ! kill -9 "${tempjobspec}"; then
							printWarning "Can not force kill job i=${i} jobspec=${tempjobspec} Gone?"
						fi
					fi  
				fi
			fi
		done
		#check for ended jobs
		if [[ -z ${availableTpidIndex} ]]; then
			isDebug && printDebug "check for ended jobs"
			for ((i=0; i<maxParralelJobs; i++)); do
				pid="${tpid[$i]}"
				jobid="${tjobid[$i]}"
				if [[ -n $pid ]]; then
					isDebug && printDebug "check wether job is still running i=$i pid=$pid jobid=$jobid"
					if jobs "%$jobid" &> /dev/null; then
					#if ps --pid "$pid" &> /dev/null; then
						isDebug && printDebug "Job is running"
					else
						psres=$?
						if [[ $psres -eq $errSigint ]]; then
							isDebug && printDebug "SIGINT: during jobs"
						else
							tmpCase="${tcase[$i]}"
							tmpVariant="${tvariant[$i]}"
							tmpCaseAndVariant="${tmpCase##*/}"
							if [[ -n $tmpVariant ]]; then
								tmpCaseAndVariant="${tmpCaseAndVariant}:${tmpVariant}"
							fi
							echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/VARIANT_LIST"
							#executeList+=("$tmpCaseAndVariant")
							echo -n "END: Job i=$i pid=$pid jobid=$jobid case=${tmpCase} variant='${tmpVariant}'"
							tpid[$i]=""
							tjobid[$i]=""
							#if there is a new job to start: take only the first free index and only if less than currentParralelJobs
							if [[ -z "${availableTpidIndex}" && "$i" -lt "${currentParralelJobs}" && -n "$caseName" ]]; then
								availableTpidIndex=$i
							fi
							#collect variant result
							tmp="${tcaseWorkDir[$i]}/RESULT"
							if [[ -e ${tmp} ]]; then
								tmp2=$(<"${tmp}")
								case "$tmp2" in
									SUCCESS )
										echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/SUCCESS_LIST"
										variantSuccess=$((variantSuccess+1))
										#successList+=("$tmpCaseAndVariant")
									;;
									SKIP )
										echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/SKIP_LIST"
										variantSkiped=$((variantSkiped+1))
										#skipList+=("$tmpCaseAndVariant")
									;;
									FAILURE )
										echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/FAILURE_LIST"
										variantFailures=$((variantFailures+1))
										#failureList+=("$tmpCaseAndVariant")
									;;
									ERROR )
										echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/ERROR_LIST"
										variantErrors=$((variantErrors+1))
										#errorList+=("$tmpCaseAndVariant")
									;;
									* )
										printError "${tmpCase}:${tmpVariant} : Invalid Case-variant result $tmp2 case workdir ${tcaseWorkDir[$i]}"
										echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/ERROR_LIST"
										variantErrors=$((variantErrors+1))
										#errorList+=("$tmpCaseAndVariant")
										tmp2="ERROR"
									;;
								esac
							else
								printError "No RESULT file in case workdir ${tcaseWorkDir[$i]}"
								echo "$tmpCaseAndVariant" >> "${TTRO_workDirSuite}/ERROR_LIST"
								variantErrors=$((variantErrors+1))
								#errorList+=("$tmpCaseAndVariant")
								tmp2="ERROR"
							fi
							echo " Result: $tmp2"
						fi
					fi
				fi
			done
		fi
		#during final job run: check that all jobs are gone
		if [[ -z $caseName ]]; then
			declare -i j=0
			for ((i=0; i<maxParralelJobs; i++)); do
				isDebug && printDebug "Check for all jobs gone: index $i"
				if [[ -n ${tpid[$i]} ]]; then
					isDebug && printDebug "Check for all jobs gone: index $i is not free pid=${tpid[$i]}"
					break
				fi
				j=$((j+1))
			done
			if [[ $j -eq $maxParralelJobs ]]; then
				isDebug && printDebug "All jobs gone"
				allJobsGone="true"
			fi
		fi
		#wait
		if [[ -z ${availableTpidIndex} && -z $allJobsGone ]]; then
			isDebug && printDebug "sleep 1"
			if sleep 1; then
				isDebug && printDebug "sleep returns success"
			else
				cresult=$?
				if [[ $cresult -eq 130 ]]; then
					echo "SIGINT received in sleep in programm $commandname ********************"
				else
					printError "Unhandled result $cresult after sleep"
				fi
			fi
		fi
		isDebug && printDebug "Loop post cond availableTpidIndex='${availableTpidIndex}' allJobsGone='${allJobsGone}' caseName='${caseName}' variant='${caseVariant}'"
	done
	#start a new job
	if [[ -n $caseName && -n $availableTpidIndex ]]; then
		cworkdir="${caseVariantWorkdirs[$jobIndex]}"
		#make and cleanup case work dir
		if [[ -e $cworkdir ]]; then
			printError "Case workdir exists: $cworkdir"
			rm -rf "$cworkdir"
		else
			mkdir -p "$cworkdir"
		fi
		cmd="${TTRO_scriptDir}/case.sh"
		echo "START: jobIndex=$jobIndex case=$caseName variant=$caseVariant index=$availableTpidIndex"
		#Start job connect output to stdout in single thread case
		if [[ "$TTRO_noParallelCases" -eq 1 ]]; then
			$cmd "$casePath" "$cworkdir" "$caseVariant" 2>&1 | tee -i "${cworkdir}/${TEST_LOG}" &
		else
			$cmd "$casePath" "$cworkdir" "$caseVariant" &> "${cworkdir}/${TEST_LOG}" &
		fi
		tmp=$(jobs %+)
		isDebug && printDebug "jobspec:$tmp"
		tmp1=$(cut -d ' ' -f1 <<< $tmp)
		tmp2=$(cut -d ' ' -f2 <<< $tmp)
		if [[ $tmp1 =~ \[(.*)\]\+ ]]; then
			tjobid[$availableTpidIndex]="${BASH_REMATCH[1]}"
		else
			tjobid[$availableTpidIndex]=""
			printErrorAndExit "No jobindex extract from jobs output '$tmp'" $errRt
		fi
		tpid[$availableTpidIndex]=$!
		tcase[$availableTpidIndex]="$caseName"
		tvariant[$availableTpidIndex]="$caseVariant"
		killed[$availableTpidIndex]=""
		tmp="$(date +'%-s')"
		isDebug && printDebug "Enter tjobid[$availableTpidIndex]=${tjobid[$availableTpidIndex]} state=$tmp2 tpid[${availableTpidIndex}]=$! time=${tmp} state=$tmp2"
		startTime[$availableTpidIndex]="$tmp"
		tmp1=${caseTimeout[$jobIndex]}
		if [[ $tmp1 -eq 0 ]]; then
			tmp1="$TTP_timeout"
		fi
		isVerbose && echo "Job timeout $tmp1"
		endTime[$availableTpidIndex]=$((tmp+tmp1))
		timeout[$availableTpidIndex]="$tmp1"
		tcaseWorkDir[$availableTpidIndex]="$cworkdir"
		jobIndex=$((jobIndex+1))
	fi
done

#test suite finalization
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
				if isExistingAndTrue 'TTPN_noFinsSuite'; then
					isVerbose && echo "Suppress Suite Finalization: $step"
				else
					isVerbose && echo "Execute Suite Finalization: $step"
					executedTestFinSteps=$((executedTestFinSteps+1))
					eval "$step"
				fi
			done
		else
			isDebug && printDebug "$name_xyza=${!name_xyza}"
			for x_xyza in ${!name_xyza}; do
				if isExistingAndTrue 'TTPN_noFinsSuite'; then
					isVerbose && echo "Suppress Suite Finalization: $x_xyza"
				else
					isVerbose && echo "Execute Suite Finalization: $x_xyza"
					executedTestFinSteps=$((executedTestFinSteps+1))
					eval "${x_xyza}"
				fi
			done
		fi
	fi
done
if isFunction 'testFinalization'; then
	if isExistingAndTrue 'TTPN_noFinsSuite'; then
		isVerbose && echo "Suppress Suite Finalization function testFinalization"
	else
		isVerbose && echo "Execute Suite Finalization function testFinalization"
		executedTestFinSteps=$((executedTestFinSteps+1))
		testFinalization
	fi
fi
isVerbose && echo "$executedTestFinSteps Test Suite Finalisation steps executed"

#-------------------------------------------------------
#put results to results file for information purose only 
echo -e "VARIANT=$jobIndex\nSUCCESS=$variantSuccess\nSKIP=$variantSkiped\nFAILURE=$variantFailures\nERROR=$variantErrors" > "${TTRO_workDirSuite}/RESULT"

#-------------------------------------------------------
#Final verbose suite result printout
echo "**** Results Suite: $TTRO_suite ***********************************************"
for x in VARIANT SUCCESS SKIP FAILURE ERROR; do
	tmp="${TTRO_workDirSuite}/${x}_LIST"
	eval "${x}_NO=0"
	isVerbose && echo "**** $x List : ****"
	{
		while read; do
			if [[ $REPLY != \#* ]]; then
				eval "${x}_NO=\$((${x}_NO+1))"
			fi
			isVerbose && echo "$REPLY "
		done
	} < "$tmp"
	tmp3="${x}_NO"
	isDebug && printDebug "$x = ${!tmp3}"
done

#------------------------------------------
#check internal result vars against obtained
if [[ $VARIANT_NO -ne $jobIndex ]]; then
	printError "Variant No not consistent: VARIANT_NO=$VARIANT_NO"
fi
if [[ $SKIP_NO -ne $variantSkiped ]]; then
	printError "Skip No not consistent: SKIP_NO=$SKIP_NO"
fi
if [[ $FAILURE_NO -ne $variantFailures ]]; then
	printError "Failure No not consistent: FAILURE_NO=$FAILURE_NO"
fi
if [[ $ERROR_NO -ne $variantErrors ]]; then
	printError "Error No not consistent: ERROR_NO=$ERROR_NO"
fi

declare suiteResult=0
if [[ $interruptReceived -gt 0 ]]; then
	suiteResult=$errSigint
fi

printf "**** Suite: $TTRO_suite Variant: '$TTRO_suiteVariant' cases=%i skipped=%i failures=%i errors=%i *****\n" $jobIndex $variantSkiped $variantFailures $variantErrors
builtin echo -n "$suiteResult" > "${TTRO_workDirSuite}/DONE"

isDebug && printDebug "END: Suite $TTRO_suite variant='$TTRO_suiteVariant' suite exit code $suiteResult"

exit $suiteResult
