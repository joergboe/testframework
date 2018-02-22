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
	usage: ${command} casePath workdir variant;
	
	EOF
}
isDebug && echo "$0 $*"
if [[ $# -ne 3 ]]; then
	usage
	exit ${errInvocation}
fi

#setup case values
declare -rx TTRO_inputDirCase="$1"; shift
declare -rx TTRO_workDirCase="$1"; shift
declare -rx TTRO_variantCase="$1"
#more values to setup
declare -r suite="${TTRO_inputDirSuite##*/}"
declare -rx TTRO_case="${TTRO_inputDirCase##*/}"
declare -i executedTestSteps=0
declare -i executedTestPrepSteps=0
declare -i executedTestFinSteps=0
declare errorOccurred=''
declare failureOccurred=''
declare skipcase=""

#test finalization function
function caseFinalization {
	if [[ -z $caseFinalized ]]; then
		caseFinalized='true'
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
						if isExistingAndTrue 'TTPN_noFinsCase'; then
							isVerbose && echo "Suppress Case Finalization: $step_xyza"
						else
							isVerbose && echo "Execute Case Finalization: $step_xyza"
							executedTestFinSteps=$((executedTestFinSteps+1))
							eval "${step_xyza}"
						fi
					done
				else
					isDebug && printDebug "$name_xyza=${!name_xyza}"
					local x_xyza
					for x_xyza in ${!name_xyza}; do
						if isExistingAndTrue 'TTPN_noFinsCase'; then
							isVerbose && echo "Suppress Case Finalization: $x_xyza"
						else
							isVerbose && echo "Execute Case Finalization: $x_xyza"
							executedTestFinSteps=$((executedTestFinSteps+1))
							eval "${x_xyza}"
						fi
					done
				fi
			fi
		done
		if isFunction 'testFinalization'; then
			if isExistingAndTrue 'TTPN_noFinsCase'; then
				isVerbose && echo "Suppress Case Finalization function testFinalization"
			else
				isVerbose && echo "Execute Case Finalization function testFinalization"
				executedTestFinSteps=$((executedTestFinSteps+1))
				testFinalization
			fi
		fi
		isVerbose && echo "$executedTestFinSteps Case Test Finalization steps executed"
	else
		isDebug && printDebug "No execution caseFinalization case $TTRO_case variant '$TTRO_variantCase'"
	fi
	return 0
}
declare caseFinalized=''

function caseExitFunction {
	isDebug && printDebug "$FUNCNAME"
	if [[ -z "$skipcase" ]]; then
		caseFinalization
	fi
}
trap caseExitFunction EXIT

#
# success exit / failure exit and error exit
#
function successExit {
	echo "SUCCESS" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	isVerbose && echo "**** END Case case=${TTRO_case} variant='${TTRO_variantCase}' SUCCESS *****"
	exit 0
}
function skipExit {
	echo "SKIP" > "${TTRO_workDirCase}/RESULT"
	isVerbose && echo "**** END Case case=${TTRO_case} variant='${TTRO_variantCase}' SKIP **********"
	exit 0
}
function failureExit {
	echo "FAILURE" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	isVerbose && echo "**** END Case case=${TTRO_case} variant='${TTRO_variantCase}' FAILURE ********" >&2
	exit 0
}
function errorExit {
	echo "ERROR" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	isVerbose && echo "END Case case=${TTRO_case} variant='${TTRO_variantCase}' ERROR ***************" >&2
	exit ${errTestError}
}

#####################################################################################################
#Start of main testcase body
isVerbose && echo "**** START Case $TTRO_case variant $TTRO_variantCase in workdir $TTRO_workDirCase ********************"

#----------------------------------
# enter working dir
cd "$TTRO_workDirCase"

#-------------------------------------------------
#include global, suite and case custom definitions
tmp="${TTRO_inputDirCase}/${TEST_CASE_FILE}"
if [[ -e $tmp ]]; then
	isVerbose && echo  "Source Case test tools file $tmp"
	source "$tmp"
	fixPropsVars
	writeProtectExportedFunctions
else
	printErrorAndExit "No Case test tools file $tmp" $errScript
fi

#------------------------------------------------
# diagnostics
isVerbose && printTestframeEnvironment
tmp="${TTRO_workDirCase}/${TEST_ENVIRONMET_LOG}"
printTestframeEnvironment > "$tmp"
export >> "$tmp"

#check skip
if [[ -e "${TTRO_inputDirCase}/SKIP" ]]; then
	skipcase="true"
fi
if declare -p TTPN_skip &> /dev/null; then
	if [[ -n $TTPN_skip ]]; then
		skipcase="true"
	fi
fi
if declare -p TTPN_skipIgnore &> /dev/null; then
	if [[ -n $TTPN_skipIgnore ]]; then
		skipcase=""
	fi
fi
if [[ -n $skipcase ]]; then
	isVerbose && echo "SKIP variable set; Skip execution case=$TTRO_case variant=$TTRO_variantCase"
	skipExit
fi

#test preparation
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
				if isExistingAndTrue 'TTPN_noPrepsCase'; then
					isVerbose && echo "Suppress Case Preparation: $step_xyza"
				else
					isVerbose && echo "Execute Case Preparation: $step_xyza"
					executedTestPrepSteps=$((executedTestPrepSteps+1))
					eval "$step_xyza"
				fi
			done
		else
			isDebug && printDebug "$name_xyza=${!name_xyza}"
			for x_xyza in ${!name_xyza}; do
				if isExistingAndTrue 'TTPN_noPrepsCase'; then
					isVerbose && echo "Suppress Case Preparation: $x_xyza"
				else
					isVerbose && echo "Execute Case Preparation: $x_xyza"
					executedTestPrepSteps=$((executedTestPrepSteps+1))
					eval "${x_xyza}"
				fi
			done
		fi
	fi
done
if isFunction 'testPreparation'; then
	if isExistingAndTrue 'TTPN_noPrepsCase'; then
		isVerbose && echo "Suppress Case Preparation function testPreparation"
	else
		isVerbose && echo "Execute Case Preparation function testPreparation"
		executedTestPrepSteps=$((executedTestPrepSteps+1))
		testPreparation
	fi
fi
isVerbose && echo "$executedTestPrepSteps Case Test Preparation steps executed"

#test execution
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
				isVerbose && echo "Execute Case Test Step: $step_xyza"
				executedTestSteps=$((executedTestSteps+1))
				eval "$step_xyza"
			done
		else
			isDebug && printDebug "$name_xyza=${!name_xyza}"
			for x_xyza in ${!name_xyza}; do
				isVerbose && echo "Execute Case Test Step: $x_xyza"
				executedTestSteps=$((executedTestSteps+1))
				eval "${x_xyza}"
			done
		fi
	fi
done
if isFunction 'testStep'; then
	isVerbose && echo "Execute Case Test Step function testStep"
	executedTestSteps=$((executedTestSteps+1))
	testStep
fi
if [[ $executedTestSteps -eq 0 ]]; then
	printError "No test Case step defined"
	errorOccurred="true"
else
	isVerbose && echo "$executedTestSteps Case test steps executed"
fi

if [[ -n $errorOccurred ]]; then
	errorExit
elif [[ -n $failureOccurred ]]; then
	failureExit
else
	successExit
fi

:
