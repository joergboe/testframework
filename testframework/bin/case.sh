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

# Function errorExit
#	global error exit function - prints the caller stack
function errorExit {
	echo -e "\033[31mERROR: $FUNCNAME ***************"
	local -i i=0;
	while caller $i; do
		i=$((i+1))
	done
	echo -e "************************************************\033[0m"
}
trap errorExit ERR

#includes
source "${TTRO_scriptDir}/defs.sh"
source "${TTRO_scriptDir}/util.sh"

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
declare -rx TTRO_caseVariant="$1"
#more values to setup
declare -r suite="${TTRO_inputDirSuite##*/}"
declare -rx TTRO_case="${TTRO_inputDirCase##*/}"
declare -i executedTestSteps=0
declare -i executedTestPrepSteps=0
declare -i executedTestFinSteps=0
declare errorOccurred=''
declare failureOccurred=''

#test finalization function
function caseFinalization {
	if [[ -z $caseFinalized ]]; then
		caseFinalized='true'
		if isFunction 'fin'; then
			if isExisting 'fin' || isExisting 'TTRO_finCase'; then
				printErrorAndExit "You must not use fin or TTRO_finCase variable together with fin function" $errRt
			fi
		fi
		local name_xyza
		for name_xyza in 'TTRO_finCase' 'fin'; do
			if isExisting "$name_xyza"; then
				if isArray "$name_xyza"; then
					if isDebug; then
						local v=$(declare -p "$name_xyza")
						printDebug "$v"
					fi
					local l_xyza i_xyza
					eval "l_xyza=\${#$name_xyza[@]}"
					for (( i_xyza=0; i_xyza<l_xyza; i_xyza++)); do
						eval "step=\${$name_xyza[$i_xyza]}"
						if isExistingAndTrue 'TTRO_noFinCase'; then
							isVerbose && echo "Suppress Case Finalization: $step"
						else
							isVerbose && echo "Execute Case Finalization: $step"
							executedTestFinSteps=$((executedTestFinSteps+1))
							eval "${step}"
						fi
					done
				else
					isDebug && printDebug "$name_xyza=${!name_xyza}"
					local x_xyza
					for x_xyza in ${!name_xyza}; do
						if isExistingAndTrue 'TTRO_noFinCase'; then
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
		if isFunction 'fin'; then
			if isExistingAndTrue 'TTRO_noFinCase'; then
				isVerbose && echo "Suppress Case Finalization function fin"
			else
				isVerbose && echo "Execute Case Finalization function fin"
				executedTestFinSteps=$((executedTestFinSteps+1))
				fin
			fi
		fi
		isVerbose && echo "$executedTestFinSteps Case Test Finalization steps executed"
		#return 55
	else
		isDebug && printDebug "No execution caseFinalization case $TTRO_case variant '$TTRO_caseVariant'"
	fi
	return 0
}
declare caseFinalized=''

function caseExitFunction {
	isDebug && printDebug "caseExitFunction"
	if [[ -z skipcase ]]; then
		caseFinalization
	fi
}
trap caseExitFunction EXIT
#trap -p
isVerbose && echo "START: execution Suite $TTRO_suite variant '$TTRO_suiteVariant' Case $TTRO_case variant '$TTRO_caseVariant'"

#
# success exit / failure exit and error exit
#
function successExit {
	echo "SUCCESS" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	isVerbose && echo "**** END Case case=${TTRO_case} variant='${TTRO_caseVariant}' SUCCESS *****"
	exit 0
}
function skipExit {
	echo "SKIP" > "${TTRO_workDirCase}/RESULT"
	isVerbose && echo "**** END Case case=${TTRO_case} variant='${TTRO_caseVariant}' SKIP **********"
	exit 0
}
function failureExit {
	echo "FAILURE" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	isVerbose && echo "**** END Case case=${TTRO_case} variant='${TTRO_caseVariant}' FAILURE ********" >&2
	exit 0
}
function errorExit {
	echo "ERROR" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	isVerbose && echo "END Case case=${TTRO_case} variant='${TTRO_caseVariant}' ERROR ***************" >&2
	exit ${errTestError}
}

#Start of main testcase body
isVerbose && echo "**** START Case $TTRO_case variant $TTRO_caseVariant in workdir $TTRO_workDirCase ********************"

#-----------------------------------
#setup properties and vars
tmp="${TTRO_inputDirCase}/${TEST_CASE_FILE}"
isVerbose && echo "Set properties from Case file $tmp"
setProperties "$tmp"
fixPropsVars

#-----------------------------------
# tools
for x in $TT_tools; do
	isVerbose && echo "Source global tools file: $x"
	source "$x"
	fixPropsVars
done

#-------------------------------------------------
#include global, suite and case custom definitions
tmp="${TTRO_inputDirCase}/${TEST_CASE_FILE}"
if [[ -e $tmp ]]; then
	isVerbose && echo  "Source Case test tools file $tmp"
	source "$tmp"
	fixPropsVars
else
	printErrorAndExit "No Case test tools file $tmp" $errScript
fi

#----------------------------------
# enter working dir
cd "$TTRO_workDirCase"

#------------------------------------------------
# diagnostics
isVerbose && printTestframeEnvironment
printTestframeEnvironment > "${TTRO_workDirCase}/${TEST_ENVIRONMET_LOG}"
export >> "${TTRO_workDirCase}/${TEST_ENVIRONMET_LOG}"

#check skip
declare skipcase=""
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
	isVerbose && echo "SKIP variable set; Skip execution case=$TTRO_case variant=$TTRO_caseVariant"
	skipExit
fi

#test preparation
if isFunction 'prep'; then
	if isExisting 'TTRO_prepCase' || isExisting 'prep'; then
		printErrorAndExit "You must not use prep or TTRO_prepCase variable together with prep function" $errRt
	fi
fi
for name_xyza in 'TTRO_prepCase' 'prep'; do
	if isExisting "$name_xyza"; then
		if isArray "$name_xyza"; then
			if isDebug; then
				v=$(declare -p "$name_xyza")
				printDebug "$v"
			fi
			eval "l_xyza=\${#$name_xyza[@]}"
			for (( i_xyza=0; i_xyza<l_xyza; i_xyza++)); do
				eval "step=\${$name_xyza[$i_xyza]}"
				if isExistingAndTrue 'TTRO_noPrepCase'; then
					isVerbose && echo "Suppress Case Preparation: $step"
				else
					isVerbose && echo "Execute Case Preparation: $step"
					executedTestPrepSteps=$((executedTestPrepSteps+1))
					eval "$step"
				fi
			done
		else
			isDebug && printDebug "$name_xyza=${!name_xyza}"
			for x_xyza in ${!name_xyza}; do
				if isExistingAndTrue 'TTRO_noPrepCase'; then
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
if isFunction 'prep'; then
	if isExistingAndTrue 'TTRO_noPrepCase'; then
		isVerbose && echo "Suppress Case Preparation function prep"
	else
		isVerbose && echo "Execute Case Preparation function prep"
		executedTestPrepSteps=$((executedTestPrepSteps+1))
		prep
	fi
fi
isVerbose && echo "$executedTestPrepSteps Case Test Preparation steps executed"

#test execution
if isFunction 'step'; then
	if isExisting 'step' || isExisting 'TTRO_stepCase'; then
		printErrorAndExit "You must not use step or TTRO_stepCase variable together with step function" $errRt
	fi
fi
for name_xyza in 'TTRO_stepCase' 'step'; do
	if isExisting "$name_xyza"; then
		if isArray "$name_xyza"; then
			if isDebug; then
				v=$(declare -p "$name_xyza")
				printDebug "$v"
			fi 
			eval "l_xyza=\${#$name_xyza[@]}"
			for (( i_xyza=0; i_xyza<l_xyza; i_xyza++)); do
				eval "step=\${$name_xyza[$i_xyza]}"
				isVerbose && echo "Execute Case Test Step: $step"
				executedTestSteps=$((executedTestSteps+1))
				eval "$step"
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
if isFunction 'step'; then
	isVerbose && echo "Execute Case Test Step function step"
	executedTestSteps=$((executedTestSteps+1))
	step
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
