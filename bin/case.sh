#!/bin/bash

######################################################
# Test case
# Testframework Test Case execution script
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

# Shutdown and interrupt vars and functions
declare interruptReceived=""
declare -r commandname="${0##*/}"

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

#includes
source "${TTRO_scriptDir}/defs.sh"
source "${TTRO_scriptDir}/util.sh"
source "${TTRO_scriptDir}/coreutil.sh"

#usage and parameters
function usage {
	local command=${0##*/}
	cat <<-EOF
	
	#usage: ${command} scriptsPath suitePath casePath workdir variant;
	usage: ${command} casePath workdir variant preamblError;
	
	EOF
}
isDebug && printDebug "$0 $*"
if [[ $# -ne 4 ]]; then
	usage
	exit ${errInvocation}
fi
#start time
declare -r caseStartTime=$(date -u +%s)
#setup case values
declare -rx TTRO_inputDirCase="$1"; shift
declare -rx TTRO_workDirCase="$1"; shift
declare -rx TTRO_variantCase="$1"; shift
declare -r TTTT_preamblError="$1"
#more values to setup
declare -r suite="${TTRO_inputDirSuite##*/}"
declare -rx TTRO_case="${TTRO_inputDirCase##*/}"
declare -i executedTestSteps=0
declare -i executedTestPrepSteps=0
declare -i executedTestFinSteps=0
declare TTTT_state='initializing'
declare TTTT_caseFinalized=''
declare TTTT_failureOccurred=''
eval "$TTXX_runCategoryPatternArray"
declare -a TTTT_categoryArray=( 'default' )

#test finalization function
function caseFinalization {
	if [[ $TTTT_state == 'initializing' ]]; then
		return 0
	fi
	if [[ -z $TTTT_caseFinalized ]]; then
		TTTT_caseFinalized='true'
		local name_xyza
		for name_xyza in 'TTRO_finsCase' 'FINS'; do
			if isExisting "$name_xyza"; then
				if isArray "$name_xyza"; then
					if isDebug; then
						local v=$(declare -p "$name_xyza")
						printDebug "$v"
					fi
					local l_xyza i_xyza
					eval "l_xyza=\${#$name_xyza[@]}"
					for (( i_xyza=0; i_xyza<l_xyza; i_xyza++)); do
						local step_xyza
						eval "step_xyza=\${$name_xyza[$i_xyza]}"
						if isExistingAndTrue 'TTPRN_noFinsCase'; then
							printInfo "Suppress Case Finalization: $step_xyza"
						else
							printInfo "Execute Case Finalization: $step_xyza"
							executedTestFinSteps=$((executedTestFinSteps+1))
							eval "${step_xyza}"
						fi
					done
				else
					isDebug && printDebug "$name_xyza=${!name_xyza}"
					local x_xyza
					for x_xyza in ${!name_xyza}; do
						if isExistingAndTrue 'TTPRN_noFinsCase'; then
							printInfo "Suppress Case Finalization: $x_xyza"
						else
							printInfo "Execute Case Finalization: $x_xyza"
							executedTestFinSteps=$((executedTestFinSteps+1))
							eval "${x_xyza}"
						fi
					done
				fi
			fi
		done
		if isFunction 'testFinalization'; then
			if isExistingAndTrue 'TTPRN_noFinsCase'; then
				printInfo "Suppress Case Finalization: testFinalization"
			else
				printInfo "Execute Case Finalization: testFinalization"
				executedTestFinSteps=$((executedTestFinSteps+1))
				testFinalization
			fi
		fi
		printInfo "$executedTestFinSteps Case Test Finalization steps executed"
	else
		isDebug && printDebug "No execution caseFinalization case $TTRO_case variant '$TTRO_variantCase'"
	fi
	return 0
}

function caseExitFunction {
	isDebug && printDebug "$FUNCNAME"
	if ! isSkip; then
		caseFinalization
	fi
}
trap caseExitFunction EXIT

#
# success exit / failure exit and error exit
# do not use this functions directly
function successExit {
	echo "SUCCESS" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	printInfo "**** END Case case=${TTRO_case} variant='${TTRO_variantCase}' SUCCESS *****"
	getElapsedTime "$caseStartTime"
	printInfo "**** Elapsed time $TTTT_elapsedTime state=$TTTT_state *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit 0
}
function skipExit {
	echo "SKIP" > "${TTRO_workDirCase}/RESULT"
	echo "$TTPRN_skip" > "${TTRO_workDirCase}/REASON"
	printInfo "**** END Case case=${TTRO_case} variant='${TTRO_variantCase}' SKIP **********"
	getElapsedTime "$caseStartTime"
	printInfo "**** Elapsed time $TTTT_elapsedTime state=$TTTT_state *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit 0
}
function failureExit {
	echo "FAILURE" > "${TTRO_workDirCase}/RESULT"
	echo "$TTTT_failureOccurred" > "${TTRO_workDirCase}/REASON"
	caseFinalization
	printError "**** FAILURE : $TTTT_failureOccurred ****"
	printInfo "**** END Case case=${TTRO_case} variant='${TTRO_variantCase}' FAILURE ********" >&2
	getElapsedTime "$caseStartTime"
	printInfo "**** Elapsed time $TTTT_elapsedTime state=$TTTT_state *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit 0
}
function errorExit {
	echo "ERROR" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	printInfo "END Case case=${TTRO_case} variant='${TTRO_variantCase}' ERROR ***************" >&2
	getElapsedTime "$caseStartTime"
	printInfo "**** Elapsed time $TTTT_elapsedTime state=$TTTT_state *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit ${errTestError}
}

#####################################################################################################
#Start of main testcase body
printInfo "**** START Case $TTRO_case variant '$TTRO_variantCase' in workdir $TTRO_workDirCase pid $$ ********************"

#----------------------------------
# enter working dir
cd "$TTRO_workDirCase"

#handle preambl error
if [[ -n $TTTT_preamblError ]]; then
	printError "Preambl Error"
	errorExit
fi

#check skipfile
if [[ ( -e "${TTRO_inputDirCase}/SKIP" ) && ( -z $TTPRN_skipIgnore ) ]]; then
	printInfo "SKIP file found case=$TTRO_case variant='$TTRO_variantCase'"
	setSkip 'SKIP file found'
	skipExit
fi

#-------------------------------------------------
#source case file
tmp="${TTRO_inputDirCase}/${TEST_CASE_FILE}"
if [[ -e $tmp ]]; then
	isVerbose && printVerbose  "Source Test Case file $tmp"
	source "$tmp"
	fixPropsVars
	writeProtectExportedFunctions
else
	printErrorAndExit "No Test Case file $tmp" $errScript
fi

#------------------------------------------------
# diagnostics
isVerbose && printTestframeEnvironment
tmp="${TTRO_workDirCase}/${TEST_ENVIRONMET_LOG}"
printTestframeEnvironment > "$tmp"
export >> "$tmp"

#check category
if ! checkCats; then
	setSkip 'No matching runtime category'
fi
if isSkip; then
	printInfo "SKIP variable set; Skip execution reason $TTPRN_skip case=$TTRO_case variant=$TTRO_variantCase"
	skipExit
fi

#test preparation
TTTT_state='preparation'
for name_xyza in 'TTRO_prepsCase' 'PREPS'; do
	if isExisting "$name_xyza"; then
		if isArray "$name_xyza"; then
			if isDebug; then
				v=$(declare -p "$name_xyza")
				printDebug "$v"
			fi
			eval "l_xyza=\${#$name_xyza[@]}"
			for (( i_xyza=0; i_xyza<l_xyza; i_xyza++)); do
				eval "step_xyza=\${$name_xyza[$i_xyza]}"
				if isExistingAndTrue 'TTPRN_noPrepsCase'; then
					printInfo "Suppress Case Preparation: $step_xyza"
				else
					printInfo "Execute Case Preparation: $step_xyza"
					executedTestPrepSteps=$((executedTestPrepSteps+1))
					eval "$step_xyza"
				fi
				if [[ -n $TTTT_failureOccurred ]]; then
					printError "Failure condition during case preparation: $TTTT_failureOccurred"
					errexit
				fi
			done
		else
			isDebug && printDebug "$name_xyza=${!name_xyza}"
			for x_xyza in ${!name_xyza}; do
				if isExistingAndTrue 'TTPRN_noPrepsCase'; then
					printInfo "Suppress Case Preparation: $x_xyza"
				else
					printInfo "Execute Case Preparation: $x_xyza"
					executedTestPrepSteps=$((executedTestPrepSteps+1))
					eval "${x_xyza}"
				fi
				if [[ -n $TTTT_failureOccurred ]]; then
					printError "Failure condition during case preparation: $TTTT_failureOccurred"
					errexit
				fi
			done
		fi
	fi
done
if isFunction 'testPreparation'; then
	if isExistingAndTrue 'TTPRN_noPrepsCase'; then
		printInfo "Suppress Case Preparation: testPreparation"
	else
		printInfo "Execute Case Preparation: testPreparation"
		executedTestPrepSteps=$((executedTestPrepSteps+1))
		testPreparation
		if [[ -n $TTTT_failureOccurred ]]; then
			printError "Failure condition during case preparation: testPreparation"
			errexit
		fi
	fi
fi
printInfo "$executedTestPrepSteps Case Test Preparation steps executed"

#test execution
TTTT_state='execution'
for name_xyza in 'TTRO_stepsCase' 'STEPS'; do
	if isExisting "$name_xyza"; then
		if isArray "$name_xyza"; then
			if isDebug; then
				v=$(declare -p "$name_xyza")
				printDebug "$v"
			fi 
			eval "l_xyza=\${#$name_xyza[@]}"
			for (( i_xyza=0; i_xyza<l_xyza; i_xyza++)); do
				eval "step_xyza=\${$name_xyza[$i_xyza]}"
				printInfo "Execute Case Test Step: $step_xyza"
				executedTestSteps=$((executedTestSteps+1))
				eval "$step_xyza"
				if [[ -n $TTTT_failureOccurred ]]; then
					break 2
				fi
			done
		else
			isDebug && printDebug "$name_xyza=${!name_xyza}"
			for x_xyza in ${!name_xyza}; do
				printInfo "Execute Case Test Step: $x_xyza"
				executedTestSteps=$((executedTestSteps+1))
				eval "${x_xyza}"
				if [[ -n $TTTT_failureOccurred ]]; then
					break 2
				fi
			done
		fi
	fi
done
if [[ -z $TTTT_failureOccurred ]]; then
	if isFunction 'testStep'; then
		printInfo "Execute Case Test Step: testStep"
		isDebug && declare -F 'testStep'
		executedTestSteps=$((executedTestSteps+1))
		testStep
	fi
fi
if [[ $executedTestSteps -eq 0 ]]; then
	printError "No test Case step defined"
	errorExit
else
	printInfo "$executedTestSteps Case test steps executed"
fi

TTTT_state='finalization'
if [[ -n $TTTT_failureOccurred ]]; then
	failureExit
else
	successExit
fi

:
