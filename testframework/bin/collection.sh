#!/bin/bash

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
declare interruptReceived=''
declare -r commandname="${0##*/}"

# Function interruptSignalColl
function interruptSignalColl {
	echo "SIGINT received in $commandname ********************"
	if [[ -z $interruptReceived ]]; then
		interruptReceived="true"
	else
		echo "Abort test"
		exit $errSigint
	fi
	return 0
}
trap interruptSignalMain SIGINT

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

#-----------------------------------------------------
#include the definitions
source "${TTRO_scriptDir}/defs.sh"
source "${TTRO_scriptDir}/mainutil.sh"
source "${TTRO_scriptDir}/util.sh"

# usage and parameters
function usage {
	local command=${0##*/}
	cat <<-EOF
	
	usage: ${command} workdir variant takeAllCases
	
	EOF
}
isDebug && printDebug "$0 $*"
if [[ $# -ne 3 ]]; then
	usage
	exit ${errInvocation}
fi

#move all parameters into named variables
declare -rx TTRO_workDir="$1"; shift
declare -rx TTRO_variant="$1"; shift
declare -r takeAllCases="$1"
eval "$TTRO_sortedSuites"
eval "$TTRO_executionList"
readonly ortedSuites executionList

#-----------------------------------
#prepare result files if no exists (in case of variant these files must be created)
for x in VARIANT SUCCESS SKIP FAILURE ERROR; do
	tmp=${TTRO_workDir}/${x}_LIST
	if [[ ! -e $tmp ]]; then
		touch "$tmp"
	fi
done

tmp=${TTRO_workDir}/RESULT
if [[ ! -e $tmp ]]; then
	touch "$tmp"
fi

#-------------------------------------
# include tools
for x in $TT_tools; do
	isVerbose && echo "Source global tools file: $x"
	source "$x"
	fixPropsVars
done

tmp="$TTRO_inputDir/$TEST_COLLECTION_FILE"
isVerbose && echo "Source global Collection file $tmp"
source "$tmp"
fixPropsVars # fix global properties and vars

#------------------------------------------------
# diagnostics
isVerbose && printTestframeEnvironment
tmp="${TTRO_workDir}/${TEST_ENVIRONMET_LOG}"
printTestframeEnvironment > "$tmp"
export >> "$tmp"

#-------------------------------------------------
# execute global test preparation
declare -i executedTestPrepSteps=0
#use special vars names in loop varaiables
for name_xyza in 'TTRO_preps' 'PREPS'; do
	if isExisting "$name_xyza"; then
		if isArray "$name_xyza"; then
			if isDebug; then
				v=$(eval declare -p "$name_xyza")
				printDebug "$v"
			fi
			eval "l_xyza=\${#$name_xyza[@]}"
			for (( i_xyza=0; i_xyza<l_xyza; i_xyza++)); do
				eval "step_xyza=\${$name_xyza[$i_xyza]}"
				if isExistingAndTrue 'TTRO_noPreps'; then
					isVerbose && echo "Suppress Collection Preparation: $step_xyza"
				else
					isVerbose && echo "Execute Collection Preparation: $step_xyza"
					executedTestPrepSteps=$((executedTestPrepSteps+1))
					eval "$step_xyza"
				fi
			done
		else
			isDebug && printDebug "$name_xyza=${!name_xyza}"
			for x_xyza in ${!name_xyza}; do
				if isExistingAndTrue 'TTRO_noPreps'; then
					isVerbose && echo "Suppress Collection Preparation: $x_xyza"
				else
					isVerbose && echo "Execute Collection Preparation: $x_xyza"
					executedTestPrepSteps=$((executedTestPrepSteps+1))
					eval "${x_xyza}"
				fi
			done
		fi
	fi
done
if isFunction 'testPreparation'; then
	if isExistingAndTrue 'TTRO_noPreps'; then
		isVerbose && echo "Suppress Collection Preparation function testPreparation"
	else
		isVerbose && echo "Execute Collection Preparation function testPreparation"
		executedTestPrepSteps=$((executedTestPrepSteps+1))
		testPreparationin ${suitePath}
	fi
fi
isVerbose && echo "$executedTestPrepSteps Collection Preparation steps executed"

#--------------------------------------------
#execution loop over suites and variants
declare -i suiteVariants=0
declare -i i j
for ((i=0; i<${#sortedSuites[@]}; i++)); do
	suitePath="${sortedSuites[$i]}"
	if [[ $suitePath == $TTRO_inputDir ]]; then
		suite='--'
	else
		suite="${suitePath##*/}"
	fi
	if [[ -n $interruptReceived ]]; then
		echo "SIGINT: end Suites loop"
		break
	fi
	isVerbose && echo "**** START Suite: $suite ************************************"
	variantCount=""; variantList=""; splitter=""
	if [[ $suite != '--' ]]; then
		readVariantFile "${suitePath}/${TEST_SUITE_FILE}" "suite"
	fi
	if [[ -z $variantCount ]]; then
		if [[ -z $variantList ]]; then
 			exeSuite "" "${TTRO_workDir}/${suite}" "$takeAllCases"
		else
			for x in $variantList; do
				exeSuite "$x" "${TTRO_workDir}/${suite}/${x}" "$takeAllCases"
			done
			unset x
		fi
	else
		if [[ -z $variantList ]]; then
			for ((j=0; j<variantCount; j++)); do
				exeSuite "$j" "${TTRO_workDir}/${suite}/${j}" "$takeAllCases"
			done
			unset j
		else
			printError "In suite $suite we have both variant variables variantCount=$variantCount and variantList=$variantList ! Suite is skipped"
		fi
	fi
	isVerbose && echo "**** END Suite: $suite **************************************"
	if [[ -n $interruptReceived ]]; then
		echo "SIGINT: end Suites loop"
		break
	fi
done
unset i

#-------------------------------------------------
# execute global test finalization
declare -i executedTestFinSteps=0
for name_xyza in 'TTRO_fins' 'FINS'; do
	if isExisting "$name_xyza"; then
		if isArray "$name_xyza"; then
			if isDebug; then
				v=$(declare -p "$name_xyza")
				printDebug "$v"
			fi
			eval "l_xyza=\${#$name_xyza[@]}"
			for (( i_xyza=0; i_xyza<l_xyza; i_xyza++)); do
				eval "step_xyza=\${$name_xyza[$i_xyza]}"
				if isExistingAndTrue 'TTRO_noFins'; then
					isVerbose && echo "Suppress Collection Finalization: $step_xyza"
				else
					isVerbose && echo "Execute Collection Finalization: $step_xyza"
					executedTestFinSteps=$((executedTestFinSteps+1))
					eval "$step_xyza"
				fi
			done
		else
			isDebug && printDebug "$name_xyza=${!name_xyza}"
			for x_xyza in ${!name_xyza}; do
				if isExistingAndTrue 'TTRO_noFins'; then
					isVerbose && echo "Suppress Collection Finalization: $x_xyza"
				else
					isVerbose && echo "Execute Collection Finalization: $x_xyza"
					executedTestFinSteps=$((executedTestFinSteps+1))
					eval "${x_xyza}"
				fi
			done
		fi
	fi
done
if isFunction 'testFinalization'; then
	if isExistingAndTrue 'TTRO_noFins'; then
		isVerbose && echo "Suppress Collection Finalization function testFinalization"
	else
		isVerbose && echo "Execute Collection Finalization function testFinalization"
		executedTestFinSteps=$((executedTestFinSteps+1))
		testFinalization
	fi
fi
isVerbose && echo "$executedTestFinSteps Collection Finalization steps executed"

isDebug && printDebug "END: Collection variant='$TTRO_variant'"

:
