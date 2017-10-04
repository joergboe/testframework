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
		listFound=''
		arrayFound=''
		functionFound=''
		numberOfArtifacts=0
		if isExisting 'TTRO_caseFin'; then
			listFound='true'
			numberOfArtifacts=$((numberOfArtifacts + 1))
		fi
		if isExisting 'TTRO_caseFinArr'; then
			arrayFound='true'
			numberOfArtifacts=$((numberOfArtifacts + 1))
		fi
		if declare -F caseFin &> /dev/null; then
			functionFound='true'
			numberOfArtifacts=$((numberOfArtifacts + 1))
		fi
		if [[ $numberOfArtifacts -gt 1 ]]; then
			printErrorAndExit "More than one test finalization artifact found use only one of TTRO_caseFin TTRO_caseFinArr or caseFin function" $errexit
		fi
		
		isDebug && printDebug "execute caseFinalization case $TTRO_case variant '$TTRO_caseVariant'"
		
		if [[ -n $listFound ]]; then
			isDebug && printDebug "TTRO_caseFin=$TTRO_caseFin"
			local x
			for x in $TTRO_caseFin; do
				isVerbose && echo "Execute Case Finalization: $x"
				executedTestFinSteps=$((executedTestFinSteps+1))
				eval "${x}"
			done
		fi
		if [[ -n $arrayFound ]]; then
			if isDebug; then
				local v=$(declare -p TTRO_caseFinArr)
				printDebug "$v"
			fi
			local i
			for (( i=0; i<${#TTRO_caseFinArr[$@]}; i++)); do
				isVerbose && echo "Execute Case Finalization: ${TTRO_caseFinArr[$i]}"
				executedTestFinSteps=$((executedTestFinSteps+1))
				eval "${TTRO_caseFinArr[$i]}"
			done
		fi
		if [[ -n $functionFound ]]; then
			isVerbose && echo "Execute Case Finalization function caseFin"
			executedTestFinSteps=$((executedTestFinSteps+1))
			caseFin
		fi

		caseFinalized='true'
		isVerbose && echo "$executedTestFinSteps Case Test Finalization steps executed"
	else
		isDebug && printDebug "No execution caseFinalization case $TTRO_case variant '$TTRO_caseVariant'"
	fi
	return 0
}
declare caseFinalized=''

function caseExitFunction {
	#isDebug && printDebug "caseExitFunction"
	#:
	caseFinalization
}
trap caseExitFunction EXIT

isVerbose && echo "START: execution Suite $TTRO_suite variant '$TTRO_suiteVariant' Case $TTRO_case variant '$TTRO_caseVariant'"

#
# success exit / failure exit and error exit
#
function succex {
	isVerbose && echo "**** END Case case=${TTRO_case} variant='${TTRO_caseVariant}' SUCCESS *****"
	echo "SUCCESS" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	exit 0
}
function skipex {
	isVerbose && echo "**** END Case case=${TTRO_case} variant='${TTRO_caseVariant}' SKIP **********"
	echo "SKIP" > "${TTRO_workDirCase}/RESULT"
	exit 0
}
function failex {
	isVerbose && echo "**** END Case case=${TTRO_case} variant='${TTRO_caseVariant}' FAILURE ********" >&2
	echo "FAILURE" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	exit 0
}
function errex {
	isVerbose && echo "END Case case=${TTRO_case} variant='${TTRO_caseVariant}' ERROR ***************" >&2
	echo "ERROR" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	exit ${errTestError}
}

isVerbose && echo "**** START Case $TTRO_case variant $TTRO_caseVariant in workdir $TTRO_workDirCase ********************"

#-----------------------------------
#setup properties and vars
setProperties "${TTRO_inputDirCase}/${TEST_CASE_FILE}"
fixPropsVars

#-------------------------------------------------
#include global, suite and case custom definitions
tmp="$TTRO_inputDir/$TEST_COLLECTION_FILE"
if [[ -r $tmp ]]; then
	isVerbose && echo "Include global test tools $tmp"
	source "$tmp"
else
	printErrorAndExit "Can nor read test collection file ${tmp}" $errScript
fi
#for x in $TTRO_tools; do
#	isVerbose && echo "Source global tools file: $x"
#	source "$x"
#done
if [[ $TTRO_suite != '--' ]]; then
	tmp="${TTRO_inputDirSuite}/${TEST_SUITE_FILE}"
	if [[ -e $tmp ]]; then
		isVerbose && echo  "Source Suite test tools file $tmp"
		source "$tmp"
	else
		printErrorAndExit "No Suite test tools file $tmp" $errScript
	fi
fi
tmp="${TTRO_inputDirCase}/${TEST_CASE_FILE}"
if [[ -e $tmp ]]; then
	isVerbose && echo  "Source Case test tools file $tmp"
	source "$tmp"
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
	skipex
fi

#test preparation
declare listFound=''
declare arrayFound=''
declare functionFound=''
declare -i numberOfArtifacts=0
if isExisting 'TTRO_casePrep'; then
	listFound='true'
	numberOfArtifacts=$((numberOfArtifacts + 1))
fi
if isExisting 'TTRO_casePrepArr'; then
	arrayFound='true'
	numberOfArtifacts=$((numberOfArtifacts + 1))
fi
if declare -F casePrep &> /dev/null; then
	functionFound='true'
	numberOfArtifacts=$((numberOfArtifacts + 1))
fi
if [[ $numberOfArtifacts -gt 1 ]]; then
	printErrorAndExit "More than one test preparation artifact found use only one of TTRO_casePrep TTRO_casePrepArr or casePrep function" $errexit
fi
if [[ -n $listFound ]]; then
	isDebug && printDebug "TTRO_casePrep=$TTRO_casePrep"
	for x in $TTRO_casePrep; do
		isVerbose && echo "Execute Case Preparation: $x"
		executedTestPrepSteps=$((executedTestPrepSteps+1))
		eval "${x}"
	done
fi
if [[ -n $arrayFound ]]; then
	if isDebug; then
		v=$(declare -p TTRO_casePrepArr)
		printDebug "$v"
	fi
	for (( i=0; i<${#TTRO_casePrepArr[$@]}; i++)); do
		isVerbose && echo "Execute Case Preparation: ${TTRO_casePrepArr[$i]}"
		executedTestPrepSteps=$((executedTestPrepSteps+1))
		eval "${TTRO_casePrepArr[$i]}"
	done
fi
if [[ -n $functionFound ]]; then
	isVerbose && echo "Execute Case Preparation function casePrep"
	executedTestPrepSteps=$((executedTestPrepSteps+1))
	casePrep
fi
isVerbose && echo "$executedTestPrepSteps Case Test Preparation steps executed"

#test execution
listFound=''
arrayFound=''
functionFound=''
numberOfArtifacts=0
if isExisting 'TTRO_caseStep'; then
	listFound='true'
	numberOfArtifacts=$((numberOfArtifacts + 1))
fi
if isExisting 'TTRO_caseStepArr'; then
	arrayFound='true'
	numberOfArtifacts=$((numberOfArtifacts + 1))
fi
if declare -F caseStep &> /dev/null; then
	functionFound='true'
	numberOfArtifacts=$((numberOfArtifacts + 1))
fi
if [[ $numberOfArtifacts -gt 1 ]]; then
	printErrorAndExit "More than one test step artifact found use only one of TTRO_caseStep TTRO_caseStepArr or caseStep function" $errexit
fi
if [[ -n $listFound ]]; then
	isDebug && printDebug "TTRO_caseStep=$TTRO_caseStep"
	for x in $TTRO_caseStep; do
		isVerbose && echo "Execute Case Test Step: $x"
		executedTestSteps=$((executedTestSteps+1))
		eval "${x}"
	done
fi
if [[ -n $arrayFound ]]; then
	if isDebug; then
		v=$(declare -p TTRO_caseStepArr)
		printDebug "$v"
	fi
	for (( i=0; i<${#TTRO_caseStepArr[$@]}; i++)); do
		isVerbose && echo "Execute Case Step: ${TTRO_caseStepArr[$i]}"
		executedTestSteps=$((executedTestSteps+1))
		eval "${TTRO_caseStepArr[$i]}"
	done
fi
if [[ -n $functionFound ]]; then
	isVerbose && echo "Execute Case Step function caseStep"
	executedTestSteps=$((executedTestSteps+1))
	caseStep
fi
if [[ $executedTestSteps -eq 0 ]]; then
	printError "No test Case step defined"
	errorOccurred="true"
else
	isVerbose && echo "$TTRO_case:$TTRO_caseVariant - $executedTestSteps Case test steps executed"
fi

if [[ -n $errorOccurred ]]; then
	errex
elif [[ -n $failureOccurred ]]; then
	failex
else
	succex
fi

:
