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

######################################################
# Functions

# Function interruptSignalColl
function interruptSignalColl {
	echo "SIGINT received in $commandname ********************"
	if [[ -z $interruptReceived ]]; then
		interruptReceived="true"
	else
		echo "Abort test collection"
		exit $errSigint
	fi
	return 0
}
trap interruptSignalColl SIGINT

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
#source "${TTRO_scriptDir}/mainutil.sh"
source "${TTRO_scriptDir}/util.sh"

# usage and parameters
function usage {
	local command=${0##*/}
	cat <<-EOF
	
	usage: ${command} workdir variant takeAllCases
	
	EOF
}

#
# function to execute the variants of suites
# $1 is the variant
# $2 is the suite variant workdir
# $3 execute empty suites
# expect set vars suitePath suite sworkdir directory
function exeSuite {
	#skip suites with no test cases if $3 is false / empty dummy suite is skipped any way
	if [[ ( ${executionList[$suitePath]} == "" ) && ( ( -z $3 ) || ( $suite == '--' ) ) ]]; then
		isDebug && printDebug "$FUNCNAME: skip empty suite $suitePath: variant='$1'"
		return 0
	fi
	if [[ $suite != '--' ]]; then
		suiteVariants=$((suiteVariants+1))
	fi
	echo "**** START Suite: ${suite} variant='$1' in ${suitePath} *****************"
	#make and cleanup suite work dir
	local sworkdir="$2"
	if [[ -e $sworkdir ]]; then
		rm -rf "$sworkdir"
	fi
	mkdir -p "$sworkdir"

	#execute suite variant
	local result=0
	if "${TTRO_scriptDir}/suite.sh" "$suite" "${suitePath}" "${sworkdir}" "$1" ${executionList[$suitePath]} 2>&1 | tee -i "${sworkdir}/${TEST_LOG}"; then
		result=0;
	else
		result=$?
		if [[ $result -eq $errSigint ]]; then
			printWarning "Set SIGINT Execution of suite ${suite} variant $1 ended with result=$result"
			interruptReceived="true"
		else
			printError "Execution of suite ${suite} variant $1 ended with result=$result"
			suiteErrors=$(( suiteErrors + 1))
			builtin echo "$suite:$1" >> "$TTRO_workDir/SUITE_ERROR_LIST"
		fi
	fi
	
	#read result lists
	local x
	local collectionstring
	if [[ -n "$TTRO_variant" ]]; then
		collectionstring="$TTRO_variant"
	else
		collectionstring="$TTRO_collection"
	fi
	for x in VARIANT SUCCESS SKIP FAILURE ERROR; do
		local inputFileName="${sworkdir}/${x}_LIST"
		local outputFileName="${TTRO_workDir}/${x}_LIST"
		if [[ -e ${inputFileName} ]]; then
			{ while read; do
				if [[ $REPLY != \#* ]]; then
					if [[ -n "$1" ]]; then
						echo "${collectionstring}::${suite}:${1}::$REPLY" >> "$outputFileName"
					else
						echo "${collectionstring}::${suite}::$REPLY" >> "$outputFileName"
					fi
				fi
			done } < "${inputFileName}"
		else
			printError "No result list $inputFileName in suite $sworkdir"
		fi
	done

	echo "**** END Suite: ${suite} variant='$1' in ${suitePath} *******************"
	return 0
} #/exeSuite

##########################################################
# Main body

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

echo "**************************** START: Collection variant $TTRO_variant **********************"
#-----------------------------------
#prepare result files if no exists (in case of variant these files must be created)
if [[ -n "$TTRO_variant" ]]; then
	for x in VARIANT SUCCESS SKIP FAILURE ERROR; do
		tmp=${TTRO_workDir}/${x}_LIST
		builtin echo "#variant::suite[:variant]::case[:variant]" > "$tmp"
	done
	tmp=${TTRO_workDir}/RESULT
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
				if isExistingAndTrue 'TTPN_noPreps'; then
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
				if isExistingAndTrue 'TTPN_noPreps'; then
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
	if isExistingAndTrue 'TTPN_noPreps'; then
		isVerbose && echo "Suppress Collection Preparation function testPreparation"
	else
		isVerbose && echo "Execute Collection Preparation function testPreparation"
		executedTestPrepSteps=$((executedTestPrepSteps+1))
		testPreparation
	fi
fi
isVerbose && echo "$executedTestPrepSteps Collection Preparation steps executed"

#--------------------------------------------
#execution loop over suites and variants
declare -i suiteVariants=0 suiteErrors=0
declare -i i j
for ((i=0; i<${#sortedSuites[@]}; i++)); do
	suitePath="${sortedSuites[$i]}"
	if [[ "$suitePath" == "$TTRO_inputDir" ]]; then
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
				if [[ -n $interruptReceived ]]; then
					echo "SIGINT: end Suites loop"
					break
				fi
			done
			unset x
		fi
	else
		if [[ -z $variantList ]]; then
			for ((j=0; j<variantCount; j++)); do
				exeSuite "$j" "${TTRO_workDir}/${suite}/${j}" "$takeAllCases"
				if [[ -n $interruptReceived ]]; then
					echo "SIGINT: end Suites loop"
					break
				fi
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
				if isExistingAndTrue 'TTPN_noFins'; then
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
				if isExistingAndTrue 'TTPN_noFins'; then
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
	if isExistingAndTrue 'TTPN_noFins'; then
		isVerbose && echo "Suppress Collection Finalization function testFinalization"
	else
		isVerbose && echo "Execute Collection Finalization function testFinalization"
		executedTestFinSteps=$((executedTestFinSteps+1))
		testFinalization
	fi
fi
isVerbose && echo "$executedTestFinSteps Collection Finalization steps executed"

builtin echo "$suiteVariants" > "$TTRO_workDir/.suiteVariants"
builtin echo "$suiteErrors" > "$TTRO_workDir/.suiteErrors"

echo "**************************** END: Collection variant $TTRO_variant **********************"

#-------------------------------------------------------
#Final verbose suite result printout
for x in VARIANT SUCCESS SKIP FAILURE ERROR; do
	tmp="${TTRO_workDir}/${x}_LIST"
	eval "${x}_NO=0"
	isVerbose && echo "**** $x List : ****"
	{
		while read; do
			[[ $REPLY == \#* ]] && continue
			eval "${x}_NO=\$((${x}_NO+1))"
			isVerbose && echo "$REPLY "
		done
	} < "$tmp"
	tmp3="${x}_NO"
	isDebug && printDebug "$x = ${!tmp3}"
done

declare collectionResult=0
if [[ -n "$interruptReceived" ]]; then
	collectionResult=$errSigint
fi

#Print suite errors
if [[ $suiteErrors -gt 0 ]]; then
	printError "Errors in $suiteErrors suites:"
	cat "$TTRO_workDir/SUITE_ERROR_LIST"
fi

#Print summary only in case if there are more than one variant
if [[ -n "$TTRO_variant" ]]; then
	#put results to results file for information purose only 
	echo -e "VARIANT=$VARIANT_NO\nSUCCESS=$SUCCESS_NO\nSKIP=$SKIP_NO\nFAILURE=$FAILURE_NO\nERROR=$ERROR_NO" > "${TTRO_workDir}/RESULT"
	
	echo "**** Results Collection variant: $TTRO_variant ***********************************************"
	printf "***** suite variants=%i errors during suite execution=%i\n" $suiteVariants $suiteErrors
	printf "**** Collection Variant: '$TTRO_variant' cases=%i skipped=%i failures=%i errors=%i *****\n" $VARIANT_NO $SKIP_NO $FAILURE_NO $ERROR_NO
	
	builtin echo -n "$collectionResult" > "${TTRO_workDir}/DONE"
fi

isDebug && printDebug "END: Collection variant='$TTRO_variant' suite exit code $collectionResult"

exit $collectionResult

:
