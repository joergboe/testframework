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
		if isExisting 'TTRO_caseFin'; then
			printWarning "Deprecated usage of TTRO_caseFin. Use simply variable testFin='step1 step2 ..'"
			if isExisting 'testFin'; then
				printErrorAndExit "You must not use TTRO_caseFin together with testFin" $errRt
			else
				declare -r testFin="$TTRO_caseFin"
			fi
		fi
		if isExisting 'testFin'; then
			if isFunction 'testFin'; then
				printErrorAndExit "You must not use testFin variable together with testFin function" $errRt
			else
				if isArray 'testFin'; then
					if isDebug; then
						local v=$(declare -p testFin)
						printDebug "$v"
					fi
					local i
					for (( i=0; i<${#testFin[@]}; i++)); do
						isVerbose && echo "Execute Case Finalization: ${testFin[$i]}"
						executedTestFinSteps=$((executedTestFinSteps+1))
						eval "${testFin[$i]}"
					done
				else
					isDebug && printDebug "testFin=$testFin"
					local x
					for x in $testFin; do
						isVerbose && echo "Execute Case Finalization: $x"
						executedTestFinSteps=$((executedTestFinSteps+1))
						eval "${x}"
					done
				fi
			fi
		else
			if isFunction 'testFin'; then
				isVerbose && echo "Execute Case Finalization function testFin"
				executedTestFinSteps=$((executedTestFinSteps+1))
				testFin
			fi
		fi
		isVerbose && echo "$executedTestFinSteps Case Test Finalization steps executed"
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
for x in $TTRO_tools; do
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
if isExisting 'TTRO_casePrep'; then
	printWarning "Deprecated usage of TTRO_casePrep. Use simply variable testPrep='step1 step2 ..'"
	if isExisting 'testPrep'; then
		printErrorAndExit "You must not use TTRO_casePrep together with testPrep" $errRt
	else
		declare -r testPrep="$TTRO_casePrep"
	fi
fi
if isExisting 'testPrep'; then
	if isFunction 'testPrep'; then
		printErrorAndExit "You must not use testPrep variable together with testPrep function" $errRt
	else
		if isArray 'testPrep'; then
			if isDebug; then
				v=$(declare -p testPrep)
				printDebug "$v"
			fi
			for (( i=0; i<${#testPrep[@]}; i++)); do
				isVerbose && echo "Execute Case Preparation: ${testPrep[$i]}"
				executedTestPrepSteps=$((executedTestPrepSteps+1))
				eval "${testPrep[$i]}"
			done
		else
			isDebug && printDebug "testPrep=$testPrep"
			for x in $testPrep; do
				isVerbose && echo "Execute Case Preparation: $x"
				executedTestPrepSteps=$((executedTestPrepSteps+1))
				eval "${x}"
			done
		fi
	fi
else
	if isFunction 'testPrep'; then
		isVerbose && echo "Execute Case Preparation function testPrep"
		executedTestPrepSteps=$((executedTestPrepSteps+1))
		testPrep
	fi
fi
isVerbose && echo "$executedTestPrepSteps Case Test Preparation steps executed"

#test execution
if isExisting 'TTRO_caseStep'; then
	printWarning "Deprecated usage of TTRO_caseStep. Use simply variable testStep='step1 step2 ..'"
	if isExisting 'testStep'; then
		printErrorAndExit "You must not use TTRO_caseStep together with testStep" $errRt
	else
		declare -r testStep="$TTRO_caseStep"
	fi
fi
if isExisting 'testStep'; then
	if isFunction 'testStep'; then
		printErrorAndExit "You must not use testStep variable together with testStep function" $errRt
	else
		if isArray 'testStep'; then
			if isDebug; then
				v=$(declare -p testStep)
				printDebug "$v"
			fi
			for (( i=0; i<${#testStep[@]}; i++)); do
				isVerbose && echo "Execute Case Test Step: ${testStep[$i]}"
				executedTestSteps=$((executedTestSteps+1))
				eval "${testStep[$i]}"
			done
		else
			isDebug && printDebug "testStep=$testStep"
			for x in $testStep; do
				isVerbose && echo "Execute Case Test Step: $x"
				executedTestSteps=$((executedTestSteps+1))
				eval "${x}"
			done
		fi
	fi
else
	if isFunction 'testStep'; then
		isVerbose && echo "Execute Case Test Step function testStep"
		executedTestSteps=$((executedTestSteps+1))
		testStep
	fi
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
