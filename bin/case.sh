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
declare -r TTTI_commandname="${0##*/}" #not used here but required in coreutils
declare TTTI_interruptReceived="" #not used here but required in coreutils

# Function errorTrapFunc
#	global error exit function - prints the caller stack
function errorTrapFunc {
	{
		echo -e "\033[31mERROR: $FUNCNAME ***************"
		local -i i=0;
		while caller $i; do
			i=$((i+1))
		done
		echo -e "************************************************\033[0m"
	} >&2
}
trap errorTrapFunc ERR

#includes
source "${TTRO_scriptDir}/defs.sh"
source "${TTRO_scriptDir}/util.sh"
source "${TTRO_scriptDir}/coreutil.sh"
TTTF_fixPropsVars

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
TTXX_searchPath="$TTRO_inputDirCase $TTXX_searchPath"
export TTXX_searchPath

#test finalization function
function caseFinalization {
	#unset the errtrace too to avoid unnecessary error traps
	set +o errexit; set +o nounset; set +o errtrace
	isDebug && printDebug "$FUNCNAME"
	if [[ $TTTT_executionState == 'initializing' ]]; then
		return 0
	fi
	if [[ -z $TTTT_caseFinalized ]]; then
		TTTT_caseFinalized='true'
		
		TTTF_executeSteps 'Case' 'Finalization' 'FINS' 'TTRO_finsCase' 'testFinalization' '' 'TTPR_noFinsCase' 'TTTT_executedTestFinSteps'

		#kill childs
		isDebug && ps -f
		TTTF_killchilds "$$"
	else
		isDebug && printDebug "No execution caseFinalization case $TTRO_case variant '$TTRO_variantCase'"
	fi
	return 0
}

function caseExitFunction {
	set +o errexit; set +o nounset; set +o errtrace
	printInfo "$FUNCNAME"
	if ! TTTF_isSkip; then
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
	printInfo "**** END Case case='${TTRO_case}' variant='${TTRO_variantCase}' SUCCESS ********************"
	getElapsedTime "$TTTT_caseStartTime"
	printInfo "**** Elapsed time : $TTTT_elapsedTime state=$TTTT_executionState *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit 0
}
function skipExit {
	echo "SKIP" > "${TTRO_workDirCase}/RESULT"
	echo "$TTPRN_skip" > "${TTRO_workDirCase}/REASON"
	printInfo "**** END Case case='${TTRO_case}' variant='${TTRO_variantCase}' SKIP ********************"
	getElapsedTime "$TTTT_caseStartTime"
	printInfo "**** Elapsed time : $TTTT_elapsedTime state=$TTTT_executionState *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit 0
}
function failureExit {
	echo "FAILURE" > "${TTRO_workDirCase}/RESULT"
	echo "$TTTT_failureOccurred" > "${TTRO_workDirCase}/REASON"
	caseFinalization
	printError "**** FAILURE : $TTTT_failureOccurred ****"
	printInfo "**** END Case case='${TTRO_case}' variant='${TTRO_variantCase}' FAILURE ********************" >&2
	getElapsedTime "$TTTT_caseStartTime"
	printInfo "**** Elapsed time : $TTTT_elapsedTime state=$TTTT_executionState *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit 0
}
function errorExit {
	echo "ERROR" > "${TTRO_workDirCase}/RESULT"
	caseFinalization
	printInfo "**** END Case case='${TTRO_case}' variant='${TTRO_variantCase}' ERROR ********************" >&2
	getElapsedTime "$TTTT_caseStartTime"
	printInfo "**** Elapsed time : $TTTT_elapsedTime state=$TTTT_executionState *****"
	echo "$TTTT_elapsedTime" > "${TTRO_workDirCase}/ELAPSED"
	exit ${errTestError}
}

#####################################################################################################
#Start of main testcase body
printInfo "**** START Case case='$TTRO_case' variant='$TTRO_variantCase' in workdir $TTRO_workDirCase pid $$ START ********************"
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

#------------------------------------------------
# diagnostics
isVerbose && printTestframeEnvironment
TTTI_tmp="${TTRO_workDirCase}/${TEST_ENVIRONMET_LOG}"
printTestframeEnvironment > "$TTTI_tmp"
set +o posix
export >> "$TTTI_tmp"
declare -F >> "$TTTI_tmp"
set -o posix

#-------------------------------------------------
#source case file
TTTI_tmp="${TTRO_inputDirCase}/${TEST_CASE_FILE}"
if [[ -e $TTTI_tmp ]]; then
	isVerbose && printVerbose  "Source Test Case file $TTTI_tmp"
	source "$TTTI_tmp"
	TTTF_fixPropsVars
	TTTF_writeProtectExportedFunctions
else
	printErrorAndExit "No Test Case file $TTTI_tmp" $errScript
fi

#check category
if ! TTTF_checkCats; then
	setSkip 'No matching runtime category'
fi
if TTTF_isSkip; then
	printInfo "SKIP variable set; Skip execution reason $TTPRN_skip case=$TTRO_case variant=$TTRO_variantCase"
	skipExit
fi

#test preparation
TTTT_executionState='preparation'
TTTF_executeSteps 'Case' 'Preparation' 'PREPS' 'TTRO_prepsCase' 'testPreparation' 'true' 'TTPR_noPrepsCase' 'TTTT_executedTestPrepSteps'
if [[ -n $TTTT_failureOccurred ]]; then
	printWarning "Failure during test preparation encountered: $TTTT_failureOccurred"
fi

#test execution
TTTT_executionState='execution'
TTTF_executeSteps 'Case' 'Test Step' 'STEPS' 'TTRO_stepsCase' 'testStep' 'true' '' 'TTTT_executedTestSteps'
if [[ ( $TTTT_executedTestSteps -eq 0 ) && -z $TTTT_failureOccurred ]]; then
	printError "No test Case step defined"
	errorExit
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
