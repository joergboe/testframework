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
declare -r TTXX_commandname="${0##*/}" #required in coreutils
 declare TTXX_interruptReceived="" #required in coreutils

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
declare -r TTTT_caseStartTime=$(date -u +%s)
#setup case values
declare -rx TTRO_inputDirCase="$1"; shift
declare -rx TTRO_workDirCase="$1"; shift
declare -rx TTRO_variantCase="$1"; shift
declare -r TTTT_preamblError="$1"
#more values to setup
declare -r TTTT_suite="${TTRO_inputDirSuite##*/}"
declare -rx TTRO_case="${TTRO_inputDirCase##*/}"
declare -i TTTT_executedTestSteps=0
declare -i TTTT_executedTestPrepSteps=0
declare -i TTTT_executedTestFinSteps=0
declare TTTT_executionState='initializing'
declare TTTT_caseFinalized=''
declare TTTT_failureOccurred=''
eval "$TTXX_runCategoryPatternArray"
declare -a TTTT_categoryArray=( 'default' )

#test finalization function
function caseFinalization {
	if [[ $TTTT_executionState == 'initializing' ]]; then
		return 0
	fi
	if [[ -z $TTTT_caseFinalized ]]; then
		TTTT_caseFinalized='true'
		local TTXX_name_xyza
		for TTXX_name_xyza in 'TTRO_finsCase' 'FINS'; do
			if isExisting "$TTXX_name_xyza"; then
				if isArray "$TTXX_name_xyza"; then
					if isDebug; then
						local TTXX_v=$(declare -p "$TTXX_name_xyza")
						printDebug "$TTXX_v"
					fi
					local TTXX_l_xyza TTXX_i_xyza
					eval "TTXX_l_xyza=\${#$TTXX_name_xyza[@]}"
					for (( TTXX_i_xyza=0; TTXX_i_xyza<TTXX_l_xyza; TTXX_i_xyza++)); do
						local TTXX_step_xyza
						eval "TTXX_step_xyza=\${$TTXX_name_xyza[$TTXX_i_xyza]}"
						if isExistingAndTrue 'TTPR_noFinsCase'; then
							printInfo "Suppress Case Finalization: $TTXX_step_xyza"
						else
							printInfo "Execute Case Finalization: $TTXX_step_xyza"
							TTTT_executedTestFinSteps=$((TTTT_executedTestFinSteps+1))
							eval "${TTXX_step_xyza}"
						fi
					done
				else
					isDebug && printDebug "$TTXX_name_xyza=${!TTXX_name_xyza}"
					local TTXX_x_xyza
					for TTXX_x_xyza in ${!TTXX_name_xyza}; do
						if isExistingAndTrue 'TTPR_noFinsCase'; then
							printInfo "Suppress Case Finalization: $TTXX_x_xyza"
						else
							printInfo "Execute Case Finalization: $TTXX_x_xyza"
							TTTT_executedTestFinSteps=$((TTTT_executedTestFinSteps+1))
							eval "${TTXX_x_xyza}"
						fi
					done
				fi
			fi
		done
		if isFunction 'testFinalization'; then
			if isExistingAndTrue 'TTPR_noFinsCase'; then
				printInfo "Suppress Case Finalization: testFinalization"
			else
				printInfo "Execute Case Finalization: testFinalization"
				TTTT_executedTestFinSteps=$((TTTT_executedTestFinSteps+1))
				testFinalization
			fi
		fi
		printInfo "$TTTT_executedTestFinSteps Case Test Finalization steps executed"
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
	getElapsedTime "$TTTT_caseStartTime"
	printInfo "**** Elapsed time $TTTT_elapsedTime state=$TTTT_executionState *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit 0
}
function skipExit {
	echo "SKIP" > "${TTRO_workDirCase}/RESULT"
	echo "$TTPRN_skip" > "${TTRO_workDirCase}/REASON"
	printInfo "**** END Case case=${TTRO_case} variant='${TTRO_variantCase}' SKIP **********"
	getElapsedTime "$TTTT_caseStartTime"
	printInfo "**** Elapsed time $TTTT_elapsedTime state=$TTTT_executionState *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit 0
}
function failureExit {
	echo "FAILURE" > "${TTRO_workDirCase}/RESULT"
	echo "$TTTT_failureOccurred" > "${TTRO_workDirCase}/REASON"
	caseFinalization
	printError "**** FAILURE : $TTTT_failureOccurred ****"
	printInfo "**** END Case case=${TTRO_case} variant='${TTRO_variantCase}' FAILURE ********" >&2
	getElapsedTime "$TTTT_caseStartTime"
	printInfo "**** Elapsed time $TTTT_elapsedTime state=$TTTT_executionState *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit 0
}
function errorExit {
	echo "ERROR" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	printInfo "END Case case=${TTRO_case} variant='${TTRO_variantCase}' ERROR ***************" >&2
	getElapsedTime "$TTTT_caseStartTime"
	printInfo "**** Elapsed time $TTTT_elapsedTime state=$TTTT_executionState *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit ${errTestError}
}

#####################################################################################################
#Start of main testcase body
printInfo "**** START Case $TTRO_case variant '$TTRO_variantCase' in workdir $TTRO_workDirCase pid $$ ********************"
echo "$TTTT_caseStartTime" > "$TTRO_workDirCase/STARTTIME"

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
TTXX_tmp="${TTRO_inputDirCase}/${TEST_CASE_FILE}"
if [[ -e $TTXX_tmp ]]; then
	isVerbose && printVerbose  "Source Test Case file $TTXX_tmp"
	source "$TTXX_tmp"
	fixPropsVars
	writeProtectExportedFunctions
else
	printErrorAndExit "No Test Case file $TTXX_tmp" $errScript
fi

#------------------------------------------------
# diagnostics
isVerbose && printTestframeEnvironment
TTXX_tmp="${TTRO_workDirCase}/${TEST_ENVIRONMET_LOG}"
printTestframeEnvironment > "$TTXX_tmp"
export >> "$TTXX_tmp"

#check category
if ! checkCats; then
	setSkip 'No matching runtime category'
fi
if isSkip; then
	printInfo "SKIP variable set; Skip execution reason $TTPRN_skip case=$TTRO_case variant=$TTRO_variantCase"
	skipExit
fi

#test preparation
TTTT_executionState='preparation'
for TTXX_name_xyza in 'TTRO_prepsCase' 'PREPS'; do
	if isExisting "$TTXX_name_xyza"; then
		if isArray "$TTXX_name_xyza"; then
			if isDebug; then
				TTXX_v=$(declare -p "$TTXX_name_xyza")
				printDebug "$TTXX_v"
			fi
			eval "TTXX_l_xyza=\${#$TTXX_name_xyza[@]}"
			for (( TTXX_i_xyza=0; TTXX_i_xyza<TTXX_l_xyza; TTXX_i_xyza++)); do
				eval "TTXX_step_xyza=\${$TTXX_name_xyza[$TTXX_i_xyza]}"
				if isExistingAndTrue 'TTPR_noPrepsCase'; then
					printInfo "Suppress Case Preparation: $TTXX_step_xyza"
				else
					printInfo "Execute Case Preparation: $TTXX_step_xyza"
					TTTT_executedTestPrepSteps=$((TTTT_executedTestPrepSteps+1))
					eval "$TTXX_step_xyza"
				fi
				if [[ -n $TTTT_failureOccurred ]]; then
					printError "Failure condition during case preparation: $TTTT_failureOccurred"
					errexit
				fi
			done
		else
			isDebug && printDebug "$TTXX_name_xyza=${!TTXX_name_xyza}"
			for TTXX_x_xyza in ${!TTXX_name_xyza}; do
				if isExistingAndTrue 'TTPR_noPrepsCase'; then
					printInfo "Suppress Case Preparation: $TTXX_x_xyza"
				else
					printInfo "Execute Case Preparation: $TTXX_x_xyza"
					TTTT_executedTestPrepSteps=$((TTTT_executedTestPrepSteps+1))
					eval "${TTXX_x_xyza}"
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
	if isExistingAndTrue 'TTPR_noPrepsCase'; then
		printInfo "Suppress Case Preparation: testPreparation"
	else
		printInfo "Execute Case Preparation: testPreparation"
		TTTT_executedTestPrepSteps=$((TTTT_executedTestPrepSteps+1))
		testPreparation
		if [[ -n $TTTT_failureOccurred ]]; then
			printError "Failure condition during case preparation: testPreparation"
			errexit
		fi
	fi
fi
printInfo "$TTTT_executedTestPrepSteps Case Test Preparation steps executed"

#test execution
TTTT_executionState='execution'
for TTXX_name_xyza in 'TTRO_stepsCase' 'STEPS'; do
	if isExisting "$TTXX_name_xyza"; then
		if isArray "$TTXX_name_xyza"; then
			if isDebug; then
				TTXX_v=$(declare -p "$TTXX_name_xyza")
				printDebug "$TTXX_v"
			fi
			eval "TTXX_l_xyza=\${#$TTXX_name_xyza[@]}"
			for (( TTXX_i_xyza=0; TTXX_i_xyza<TTXX_l_xyza; TTXX_i_xyza++)); do
				eval "TTXX_step_xyza=\${$TTXX_name_xyza[$TTXX_i_xyza]}"
				printInfo "Execute Case Test Step: $TTXX_step_xyza"
				TTTT_executedTestSteps=$((TTTT_executedTestSteps+1))
				eval "$TTXX_step_xyza"
				if [[ -n $TTTT_failureOccurred ]]; then
					break 2
				fi
			done
		else
			isDebug && printDebug "$TTXX_name_xyza=${!TTXX_name_xyza}"
			for TTXX_x_xyza in ${!TTXX_name_xyza}; do
				printInfo "Execute Case Test Step: $TTXX_x_xyza"
				TTTT_executedTestSteps=$((TTTT_executedTestSteps+1))
				eval "${TTXX_x_xyza}"
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
		TTTT_executedTestSteps=$((TTTT_executedTestSteps+1))
		testStep
	fi
fi
if [[ $TTTT_executedTestSteps -eq 0 ]]; then
	printError "No test Case step defined"
	errorExit
else
	printInfo "$TTTT_executedTestSteps Case test steps executed"
fi

#open shell if required
if [[ -n $TTXX_shell ]]; then
	bash -i
fi

#test finalization
TTTT_executionState='finalization'
if [[ -n $TTTT_failureOccurred ]]; then
	failureExit
else
	successExit
fi

:
