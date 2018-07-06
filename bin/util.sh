######################################################
# Utilities for testframework
# (public utilities)
######################################################

TT_evaluationFile='./EVALUATION.log' # the standard log file for evaluation
TTTT_result=-1 # the global result var

TTRO_help_setFailure='
# Function setFailure
#	set the user defined failure condition in a test case script
#	to be used in failed test case steps only
# Parameters:
#	$1 - the user defined failure text
# Returns:
#	success
# Exits:
#	if called from a test suite script
#	if '
function setFailure {
	if isExisting 'TTRO_variantCase'; then # this is a case
		if [[ $TTTT_state != 'execution' ]]; then
			printWarning "$FUNCNAME called no phase $TTTT_state. Use this function only in phase 'execution'"
		fi
		if [[ ( $# -gt 0 ) && ( -n $1 ) ]]; then
			TTTT_failureOccurred="$1"
		else
			TTTT_failureOccurred='unspecified'
		fi
		printError "$FUNCNAME : $TTTT_failureOccurred"
		return 0
	else # this is not a case
		printErrorAndExit "Do not call the function $FUNCNAME in a test suite context" $errRt
	fi
}

TTRO_help_setCategory='
# Function setCategory
#	set the use defined categories of a test case or suite
#	$1 ... the category identifieres of this atrifact'
function setCategory {
	if [[ $TTTT_state != 'initializing' ]]; then
		printErrorAndExit "$FUNCNAME must be called in state 'initializing' state now: $TTTT_state" $errRt
	fi
	TTTT_categoryArray=()
	local i=0
	while [[ $# -ge 1 ]]; do
		TTTT_categoryArray[$i]="$1"
		i=$((i+1))
		shift
	done
}

TTRO_help_skip='
# Function skip
#	set the skip condition TTPRN_skip=true'
function skip {
	if [[ $TTTT_state != 'initializing' ]]; then
		printErrorAndExit "$FUNCNAME must be called in state 'initializing' state now: $TTTT_state" $errRt
	fi
	printInfo "Set SKIP"
	setVar 'TTPRN_skip' 'true'
}

TTRO_help_printErrorAndExit="
# Function printErrorAndExit
# 	prints an error message and exits
#	\$1 the error message to print
#	\$2 the exit code
#	returns: never"
function printErrorAndExit {
	printError "$1"
	echo -e "\033[31m EXIT: $2 ***************"
	local -i i=0;
	while caller $i; do
		i=$((i+1))
	done
	echo -e "************************************************\033[0m"
	exit $2
}

TTRO_help_printError="
# Function printError
#	prints an error message
#	\$1 the error message to print
#	returns:
#		success (0)
#		error	in exceptional cases"
function printError {
	local dd=$(date "+%T %N")
	echo -e "\033[31m$dd ERROR: $1\033[0m" >&2
}

TTRO_help_printWarning="
# Function printWarning
#	prints an warning message
#	\$1 the warning to print
#	returns:
#		success (0)
#		error	in exceptional cases"
function printWarning {
	local dd=$(date "+%T %N")
	echo -e "\033[33m$dd WARNING: $1\033[0m" >&2
}

TTRO_help_printDebug="
# Function printDebug
#	prints debug info
#	\$1 the debug info to print
#	returns:
#		success (0)
#		error	in exceptional cases"
function printDebug {
	local -i i
	local stackInfo=''
	local dd=$(date "+%T %N")
	for ((i=${#FUNCNAME[@]}-1; i>0; i--)); do
		stackInfo="$stackInfo ${FUNCNAME[$i]}"
	done
	echo -e "\033[32m$dd DEBUG: ${commandname}${stackInfo}: ${1}\033[0m"
}

TTRO_help_printDebugn="
# Function printDebugn
#	prints debug info without newline
#	\$1 the debug info to print
#	returns:
#		success (0)
#		error	in exceptional cases"
function printDebugn {
	local -i i
	local stackInfo=''
	local dd=$(date "+%T %N")
	for ((i=${#FUNCNAME[@]}-1; i>0; i--)); do
		stackInfo="$stackInfo ${FUNCNAME[$i]}"
	done
	echo -en "\033[32m$dd DEBUG:${commandname}${stackInfo}: ${1}\033[0m"
}

TTRO_help_printInfo="
# Function printInfo
#	prints info info
#	\$1 the info to print
#	returns:
#		success (0)
#		error	in exceptional cases"
function printInfo {
	local dd=$(date "+%T %N")
	echo -e "$dd INFO: ${1}"
}

TTRO_help_printInfon="
# Function printInfon
#	prints info info without newline
#	\$1 the info to print
#	returns:
#		success (0)
#		error	in exceptional cases"
function printInfon {
	local dd=$(date "+%T %N")
	echo -en "$dd INFO: ${1}"
}

TTRO_help_printVerbose="
# Function printVerbose
#	prints verbose info
#	\$1 the info to print
#	returns:
#		success (0)
#		error	in exceptional cases"
function printVerbose {
	local dd=$(date "+%T %N")
	echo -e "$dd VERBOSE: ${1}"
}

TTRO_help_printVerbosen="
# Function printVerbosen
#	prints verbose info without newline
#	\$1 the info to print
#	returns:
#		success (0)
#		error	in exceptional cases"
function printVerbosen {
	local dd=$(date "+%T %N")
	echo -en "$dd VERBOSE: ${1}"
}

TTRO_help_isDebug="
# Function isDebug
# 	returns:
#		success(0) if debug is enabled
#		error(1)   otherwise "
function isDebug {
	if [[ -n $TTPRN_debug && -z $TTPRN_debugDisable ]]; then
		return 0	# 0 is true in bash
	else
		return 1
	fi
}

TTRO_help_isVerbose="
# Function isVerbose
#	returns
#		success(0) if debug is enabled
#		error(1)   otherwise "
function isVerbose {
	if [[ ( -n $TTPRN_verbose && -z $TTPRN_verboseDisable ) || (-n $TTPRN_debug && -z $TTPRN_debugDisable) ]]; then
		return 0
	else
		return 1
	fi
}

TTRO_help_skip='
# Function skip
#	if this function is called during initialization
#	the case or suite is skipped'
function skip {
	printInfo "Skip this Case/Suite"
	TTTT_skipthis='true'
	return 0
}

TTRO_help_printTestframeEnvironment="
# Function printTestframeEnvironment
# 	print special testrame environment
#	returns:
#		success (0)
#		error	in exceptional cases"
function printTestframeEnvironment {
	echo "**** Testframe Environment ****"
	echo "PWD=$PWD"
	local x
	for x in 'PREPS' 'STEPS' 'FINS'; do
		if declare -p "$x" &> /dev/null; then
			echo "${x}='${!x}'"
		fi
	done
	for x in "${!TT_@}"; do
		echo "${x}='${!x}'"
	done
	for x in "${!TTRO_@}"; do
		if [[ $x != TTRO_help* ]]; then
			echo "${x}='${!x}'"
		fi
	done
	for x in "${!TTPR_@}"; do
		echo "${x}='${!x}'"
	done
	for x in "${!TTPRN_@}"; do
		echo "${x}='${!x}'"
	done
	for x in "${!TTXX_@}"; do
		echo "${x}='${!x}'"
	done
	echo "*******************************"
}

TTRO_help_dequote='
# Removes the sorounding quotes
#	and prints result to stdout
#	to be used withg care unquoted whitespaces are removed
#	$1 the value to dequote
#	returns:
#		success (0)
#		error	in exceptional cases'
function dequote {
	#eval printf %s "$1" 2> /dev/null
	eval printf %s "$1"
}

TTRO_help_isPureNumber='
# Checks whether the input string is a ubsigned number [0-9]+
# $1 the string to check
# returns
#	success(0)  if the input are digits only
#	error(1)    otherwise'
function isPureNumber {
	if [[ $1 =~ [0-9]+ ]]; then
		if [[ "${BASH_REMATCH[0]}" == "$1" ]]; then
			isDebug && printDebug "$FUNCNAME '$1' return 0"
			return 0
		fi
	fi
	isDebug && printDebug "$FUNCNAME '$1' return 1"
	return 1
}

TTRO_help_isNumber='
# Checks whether the input string is a signed or unsigned number ([-+])[0-9]+
# $1 the string to check
# returns
#	success(0)  if the input is a number
#	error(1)    otherwise'
function isNumber {
	if [[ $1 =~ [0-9]+ ]]; then
		if [[ "${BASH_REMATCH[0]}" == "$1" ]]; then
			isDebug && printDebug "$FUNCNAME '$1' return 0"
			return 0
		fi
	elif [[ $1 =~ [-+][0-9]+ ]]; then
		if [[ "${BASH_REMATCH[0]}" == "$1" ]]; then
			isDebug && printDebug "$FUNCNAME '$1' return 0"
			return 0
		fi
	fi
	isDebug && printDebug "$FUNCNAME '$1' return 1"
	return 1
}

TTRO_help_fixPropsVars='
# Function fixPropsVars
#	This function fixes all ro-variables and propertie variables
#	Property and variables setting is a two step action:
#	Unset help variables if no reference is printed
#	make vars STEPS PREPS FINS read-only
#	returns:
#		success (0)
#		error	in exceptional cases'
function fixPropsVars {
	local var=""
	if [[ -z $TTRO_reference ]]; then
		for var in "${!TTRO_help@}"; do
			unset "$var"
		done
	fi
	for var in "${!TT_@}"; do
		isDebug && printDebug "${FUNCNAME} : TT_   $var=${!var}"
		export "${var}"
	done
	for var in "${!TTRO_@}"; do
		isDebug && printDebug "${FUNCNAME} : TTRO_ $var=${!var}"
		readonly "${var}"
		export "${var}"
	done
	for var in "${!TTPR_@}"; do
		isDebug && printDebug "${FUNCNAME} : TTPR_  $var=${!var}"
		readonly "${var}"
		export "${var}"
	done
	for var in "${!TTPRN_@}"; do
		isDebug && printDebug "${FUNCNAME} : TTPRN_ $var=${!var}"
		if [[ -n "${!var}" ]]; then
			readonly "${var}"
		fi
		export "${var}"
	done
	#fix special local vars
	for var in 'STEPS' 'PREPS' 'FINS'; do
		if declare -p "$var" &> /dev/null; then
			declare -r "$var"
		fi
	done
}

TTRO_help_setVar='
# Function setVar
#	Set framework variable or property at runtime
#	The name of the variable must startg with TT_, TTRO_, TTPR_ or TTPRN_
# Parameters:
#	$1 - the name of the variable to set
#	$2 - the value
# Returns
#	success (0) - if the variable could be set or if an property value is ignored
# Exits:
#	if variable is not of type TT_, TTRO_, TTPR_ or TTPRN_
#	or if the variable could not be set (e.g a readonly variable was already set
#	ignored property values do not generate an error'
function setVar {
	if [[ $# -ne 2 ]]; then printErrorAndExit "$FUNCNAME missing params. Number of Params is $#" $errRt; fi
	isDebug && printDebug "$FUNCNAME $1 $2"
	case $1 in
		TTPRN_* )
			#set property only if it is unset or null an make it readonly
			if ! declare -p ${1} &> /dev/null || [[ -z ${!1} ]]; then
				if ! eval export \'${1}\'='"${2}"'; then
					printErrorAndExit "${FUNCNAME} : Invalid expansion in varname=${1} value=${2}" ${errRt}
				else
					isVerbose && printVerbose "${FUNCNAME} : ${1}='${!1}'"
				fi
				readonly ${1}
			else
				isVerbose && printVerbose "$FUNCNAME ignore value for ${1}"
			fi
		;;
		TTPR_* )
			#set property only if it is unset an make it readonly
			if ! declare -p "${1}" &> /dev/null; then
				if ! eval export \'${1}\'='"${2}"'; then
					printErrorAndExit "${FUNCNAME} : Invalid expansion varname=${1} value=${2}" ${errRt}
				else
					isVerbose && printVerbose "${FUNCNAME} : ${1}='${!1}'"
				fi
				readonly ${1}
			else
				isVerbose && printVerbose "$FUNCNAME ignore value for ${1}"
			fi
		;;
		TTRO_* )
			#set a global readonly variable
			if eval export \'${1}\'='"${2}"'; then
				isVerbose && printVerbose "${FUNCNAME} : ${1}='${!1}'"
			else
				printErrorAndExit "${FUNCNAME} : Invalid expansion varname=${1} value=${2}" ${errRt}
			fi
			readonly ${1}
		;;
		TT_* )
			#set a global variable
			if ! eval export \'${1}\'='"${2}"'; then
				printErrorAndExit "${FUNCNAME} : Invalid expansion varname=${1} value=${2}" ${errRt}
			else
				isVerbose && printVerbose "${FUNCNAME} : ${1}='${!1}'"
			fi
		;;
		* )
			#other variables
			printErrorAndExit "${FUNCNAME} : Invalid property or variable varname=${1} value=${2}" ${errRt}
		;;
	esac
	:
}

TTRO_help_isExisting='
# Function isExisting
#	check if variable exists
# Parameters:
#	$1 - variable name to be checked
# Returns:
#		success(0)    if the variable exists
#		error(1)      otherwise
# Exits
#	if called without argument'
function isExisting {
	if declare -p "${1}" &> /dev/null; then
		isDebug && printDebug "$FUNCNAME $1 return 0"
		return 0
	else
		isDebug && printDebug "$FUNCNAME $1 return 1"
		return 1
	fi
}

TTRO_help_isNotExisting='
# Function isNotExisting
#	check if variable not exists
# Parameters:
#	$1 - variable name to be checked
# Returns:
#	success(0) - if the variable not exists
#	error(1)   -   otherwise
# Exits
#	if called without argument'
function isNotExisting {
	if declare -p "${1}" &> /dev/null; then
		isDebug && printDebug "$FUNCNAME $1 return 1"
		return 1
	else
		isDebug && printDebug "$FUNCNAME $1 return 0"
		return 0
	fi
}

TTRO_help_isExistingAndTrue='
# Function isExistingAndTrue
#	check if variable exists and has a non empty value
# Parameters:
#	$1 - var name to be checked
# Returns
#	success(0) - the variable exists and has a non empty value
#	error(1)   - otherwise
# Exits
#	if called without argument'
function isExistingAndTrue {
	if declare -p "${1}" &> /dev/null; then
		if [[ -n ${!1} ]]; then
			isDebug && printDebug "$FUNCNAME $1 return 0"
			return 0
		else
			isDebug && printDebug "$FUNCNAME $1 return 1"
			return 1
		fi
	else
		isDebug && printDebug "$FUNCNAME $1 return 1"
		return 1
	fi
}

TTRO_help_isExistingAndFalse='
# Function isExistingAndFalse
#	check if variable exists and has an empty value
# Parameters:
#	$1 - var name to be checked
# Returns
#	success(0) - exists and has an empty value
#	error(1)   - otherwise
# Exits
#	if called without argument'
function isExistingAndFalse {
	if declare -p "${1}" &> /dev/null; then
		if [[ -z ${!1} ]]; then
			isDebug && printDebug "$FUNCNAME $1 return 0"
			return 0
		else
			isDebug && printDebug "$FUNCNAME $1 return 1"
			return 1
		fi
	else
		isDebug && printDebug "$FUNCNAME $1 return 1"
		return 1
	fi
}

TTRO_help_isTrue='
# Function isTrue
#	check if a variable has a non empty value
# Parameters:
#	$1 - var name to be checked
# Returns
#	success(0) - variable exists and has a non empty value
#	error(1)   - variable exists and has a empty value
# Exits:
#	if variable not exists
#	if called without argument'
function isTrue {
	if declare -p "${1}" &> /dev/null; then
		if [[ -n ${!1} ]]; then
			isDebug && printDebug "$FUNCNAME $1 return 0"
			return 0
		else
			isDebug && printDebug "$FUNCNAME $1 return 1"
			return 1
		fi
	else
		printErrorAndExit "Variable $1 not exists" $errRt
	fi
}

TTRO_help_isFalse='
# Function isFalse
#	check if a variable has an empty value
# Parameters:
#	$1 - var name to be checked
# Returns
#	success(0)  - if the variable exists and has a empty value
#	error(1)    - if the variable exists and has an non empty value
# Exits:
#	if variable not exists
#	if called without argument'
function isFalse {
	if declare -p "${1}" &> /dev/null; then
		if [[ -z ${!1} ]]; then
			isDebug && printDebug "$FUNCNAME $1 return 0"
			return 0
		else
			isDebug && printDebug "$FUNCNAME $1 return 1"
			return 1
		fi
	else
		printErrorAndExit "Variable $1 not exists" $errRt
	fi
}

TTRO_help_isArray='
# Function isArray
#	checks whether an variable exists and is an indexed array
# Parameters:
#	$1 - var name to be checked
# Returns
#	success(0) - if the variable exists and is an indexed array
#	error(1)   -  otherwise
# Exits:
#	if called without argument'
function isArray {
	local v
	if v=$(declare -p "${1}" 2> /dev/null); then
		if [[ $v == declare\ -a* ]]; then
			isDebug && printDebug "$FUNCNAME $1 return 0"
			return 0
		else
			isDebug && printDebug "$FUNCNAME $1 return 1"
			return 1
		fi
	else
		isDebug && printDebug "$FUNCNAME $1 return 1"
		return 1
	fi
}

TTRO_help_isAssociativeArray='
# Function isAssociativeArray
#	checks whether an variable exists and is an associative array
# Parameters:
#	$1 - var name to be checked
# Returns
#	success(0) - if the variable exists and is an indexed array
#	error(1)   - otherwise
# Exits:
#	if called without argument'
function isAssociativeArray {
	local v
	if v=$(declare -p "${1}" 2> /dev/null); then
		if [[ $v == declare\ -A* ]]; then
			isDebug && printDebug "$FUNCNAME $1 return 0"
			return 0
		else
			isDebug && printDebug "$FUNCNAME $1 return 1"
			return 1
		fi
	else
		isDebug && printDebug "$FUNCNAME $1 return 1"
		return 1
	fi
}

TTRO_help_isFunction='
# Function isFunction
#	checks whether an given name is defined as function
# Parameters:
#	$1 - name to be checked
# Returns:
#	success(0)  - if the function exists
#	error(1)    - otherwise
# Exits:
#	if called without argument'
function isFunction {
	if declare -F "$1" &> /dev/null; then
		isDebug && printDebug "$FUNCNAME $1 return 0"
		return 0
	else
		isDebug && printDebug "$FUNCNAME $1 return 1"
		return 1
	fi
}

TTRO_help_arrayHasKey='
# Function arrayHasKey
#	check is an array has key
# Parameters:
#	$1 the array name
#	$2 the key value to search must not contain spaces
# Returns:
#	success(0) - if key exists in array
#	error(1)   -   otherwise
# Exits:
#	exits if called with wrong number of arguments'
function arrayHasKey {
	if [[ $# -ne 2 ]]; then printErrorAndExit "$FUNCNAME must have 2 aruments" $errRt; fi
	isDebug && printDebug "$FUNCNAME $1 $2"
	if ! isArray "$1" && ! isAssociativeArray "$1"; then
		printErrorAndExit "variable $1 is not an array"
	fi
	eval "keys=\"\${!$1[@]}\"" #indirect array access with eval
	local in=1
	local key
	for key in $keys; do
		if [[ $key == $2 ]]; then
			in=0
			break
		fi
	done
	isDebug && printDebug "$FUNCNAME $1 return $in"
	return $in
}

TTRO_help_copyAndTransform='
# Function copyAndTransform
#	Copy and change all files from input directory into workdir
#	Filenames that match one of the transformation pattern are transformed. All other files are copied.
#	In case of transformation the pattern //_<varid>_ is removed if varid equals $3
#	In case of transformation the pattern //!<varid>_ is removed if varid is different than $3
#	If the variant identifier is empty, the pattern list sould be also empty and the function is a pure copy function
#	If $3 is empty and $4 .. do not exist, this function is a pure copy
#	$1 - input dir
#	$2 - output dir
#	$3 - the variant identifier
#	$4 ... pattern for file names to be transformed
#	returns
#		success(0)
#	exits  if called with wrong arguments'
function copyAndTransform {
	printWarning "$FUNCNAME is deprecated use function 'copyAndMorph'"
	if [[ $# -lt 3 ]]; then printErrorAndExit "$FUNCNAME missing params. Number of Params is $#" $errRt; fi
	isDebug && printDebug "$FUNCNAME $*"
	if [[ -z $3 && ( $# -gt 3 ) ]]; then
		printWarning "$FUNCNAME: Empty variant identifier but there are pattern for file transformation"
	fi
	local -a transformPattern=()
	local -i max=$(($#+1))
	local -i j=0
	local -i i
	for ((i=4; i<max; i++)); do
		transformPattern[$j]="${!i}"
		j=$((j+1))
	done
	if isDebug; then
		local display=$(declare -p transformPattern);
		printDebug "$display"
	fi
	local dest=""
	for x in $1/**; do #first create dir structure
		isDebug && printDebug "$FUNCNAME item to process step1: $x"
		if [[ -d $x ]]; then
			dest="${x#$1}"
			dest="$2/$dest"
			echo $dest
			if isVerbose; then 
				mkdir -pv "$dest"
			else
				mkdir -p "$dest"
			fi
		fi
	done
	local match=0
	local x
	for x in $1/**; do
		if [[ ! -d $x ]]; then
			isDebug && printDebug "$FUNCNAME item to process step2: $x"
			for ((i=0; i<${#transformPattern[@]}; i++)); do
				isDebug && printDebug "$FUNCNAME: check transformPattern[$i]=${transformPattern[$i]}"
				match=0
				if [[ $x == ${transformPattern[$i]} ]]; then
					isDebug && printDebug "$FUNCNAME: check transformPattern[$i]=${transformPattern[$i]} Match found"
					match=1
				fi
			done
			dest="${x#$1}"
			dest="$2/$dest"
			if [[ match -eq 1 ]]; then
				isVerbose && printVerbose "transform $x to $dest"
				#if ! sed -e "s/\/\/*_${3}//g" "$x" > "$dest"; then
				#	printErrorAndExit "$FUNCNAME Can not transform input=$x dest=$dest variant=$4" $errRt
				#fi
				{
					local readResult=0
					local outline part1 part2 partx
					while [[ $readResult -eq 0 ]]; do
						if ! read -r; then readResult=1; fi
						part1="${REPLY%%//_$3_*}"
						if [[ $part1 != $REPLY ]]; then
							#isDebug && printDebug "$FUNCNAME: match line='$REPLY'"
							part2="${REPLY#*//_$3_}"
							#isDebug && printDebug "$FUNCNAME: part2='$part2'"
							outline="${part1}${part2}"
						else
							part1="${REPLY%%//\!*_*}"
							if [[ $part1 != $REPLY ]]; then
								#isDebug && printDebug "$FUNCNAME: 2nd match line='$REPLY'"
								partx="${REPLY%%//\!$3_*}"
								if [[ $partx != $REPLY ]]; then
									#isDebug && printDebug "$FUNCNAME: negative match line='$REPLY' '$partx'"
									outline="$REPLY"
								else
									part2="${REPLY#*//\!*_}"
									#isDebug && printDebug "$FUNCNAME: part2='$part2'"
									outline="${part1}${part2}"
								fi
							else
								#isDebug && printDebug "$FUNCNAME: no match line='$REPLY'"
								outline="$REPLY"
							fi
						fi
						if [[ $readResult -eq 0 ]]; then
							echo "$outline" >> "$dest"
						else
							echo -n "$outline" >> "$dest"
						fi
					done
				} < "$x"
			else
				if isVerbose; then
					cp -pv "$x" "$dest"
				else
					cp -p "$x" "$dest"
				fi
			fi
		fi
	done
	return 0
}

TTRO_help_copyAndMorph='
# Function copyAndMorph
#	Copy and change all files from input directory into workdir
#	Filenames that match one of the transformation file name pattern are transformed. All other files are copied.
#	The transformation  of the files is done with function "morphFile"
#	If the variant identifier is empty, the pattern list sould be also empty and the function is a pure copy function
#	If $3 is empty and $4 .. do not exist, this function is a pure copy
#	$1 - input dir
#	$2 - output dir
#	$3 - the variant identifier
#	$4 ... pattern for file names to be transformed
#	returns
#		success(0)
#	exits  if called with wrong arguments'
function copyAndMorph {
	if [[ $# -lt 3 ]]; then printErrorAndExit "$FUNCNAME missing params. Number of Params is $#" $errRt; fi
	isDebug && printDebug "$FUNCNAME $*"
	if [[ -z $3 && ( $# -gt 3 ) ]]; then
		printWarning "$FUNCNAME: Empty variant identifier but there are pattern for file transformation"
	fi
	local -a transformPattern=()
	local -i max=$(($#+1))
	local -i j=0
	local -i i
	for ((i=4; i<max; i++)); do
		transformPattern[$j]="${!i}"
		j=$((j+1))
	done
	if isDebug; then
		local display=$(declare -p transformPattern);
		printDebug "$display"
	fi
	local dest=""
	local x
	for x in $1/**; do #first create dir structure
		if [[ -d $x ]]; then
			isDebug && printDebug "$FUNCNAME item to process step1 create dir structure: $x"
			dest="${x#$1}"
			dest="$2/$dest"
			echo $dest
			if isVerbose; then 
				mkdir -pv "$dest"
			else
				mkdir -p "$dest"
			fi
		fi
	done
	local match=""
	for x in $1/**; do
		if [[ ! -d $x ]]; then
			isDebug && printDebug "$FUNCNAME item to process step2 copy/transform: $x"
			match=''
			for ((i=0; i<${#transformPattern[@]}; i++)); do
				isDebug && printDebug "$FUNCNAME: check transformPattern[$i]=${transformPattern[$i]}"
				if [[ $x == ${transformPattern[$i]} ]]; then
					isDebug && printDebug "$FUNCNAME: check transformPattern[$i]=${transformPattern[$i]} Match found"
					match='true'
					break;
				fi
			done
			dest="${x#$1}"
			dest="$2/$dest"
			if [[ -n $match ]]; then
				isVerbose && printVerbose "transform $x to $dest"
				morphFile "$x" "$dest" "$3"
			else
				if isVerbose; then
					cp -pv "$x" "$dest"
				else
					cp -p "$x" "$dest"
				fi
			fi
		fi
	done
	return 0
}

TTRO_help_morphFile='
# morphes a file
#	Lines like:
#	^[[:space:]]*//<varid1:varid2..> are effective if the argument $3 equal one of the varid1, or varid2..
#	^[[:space:]]*//<!varid1:varid2..> are not effective if the argument $3 equal one of the varid1, or varid2..
#	Effective means that the pattern //<varid1:varid2..> or //<!varid1:varid2..> is removed
#	$1 - input file
#	$2 - output file
#	$3 - the variant identifier
#	returns
#		success(0)
#	exits  if called with wrong arguments'
function morphFile {
	if [[ $# -ne 3 ]]; then printErrorAndExit "$FUNCNAME missing params. Number of Params is $#" $errRt; fi
	if [[ -z $3 ]]; then printErrorAndExit "$FUNCNAME wrong params. Empty variant identifier" $errRt; fi
	isDebug && printDebug "$FUNCNAME $*"
	rm -f "$2"
	{
		local readResult=0
		local negate=''
		local -i linenumber=0
		local outline writeLine ident varidlist code
		while [[ $readResult -eq 0 ]]; do
			linenumber=$((linenumber+1))
			outline=''; writeLine=''; negate=''
			if ! read -r; then readResult=1; fi
			#echo "$REPLY"
			if [[ $REPLY =~ ^([[:space:]]*)//\<([^\>]+)\>(.*) ]]; then
				ident="${BASH_REMATCH[1]}"
				varidlist="${BASH_REMATCH[2]}"
				code="${BASH_REMATCH[3]}"
				if [[ ( -n $varidlist ) && ( ${varidlist:0:1} == '!' ) ]]; then
					varidlist="${varidlist:1}"
					negate='true'
				fi
				if [[ $varidlist =~ ^[0-9a-zA-Z_:]+$ ]]; then
					if isInListSeparator "$3" "$varidlist" ':'; then
						if [[ -z $negate ]]; then
							outline="${ident}${code}"
							writeLine='true'
						fi
					else
						if [[ -n $negate ]]; then
							outline="${ident}${code}"
							writeLine='true'
						fi
					fi
				else
					printErrorAndExit "Invalid variant list in file: $1 linenumber: $linenumber line: $REPLY" $errRt
				fi
			else
				outline="$REPLY"
				writeLine='true'
			fi
			if [[ -n $writeLine ]]; then
				if [[ $readResult -eq 0 ]]; then
					echo "$outline" >> "$2"
				else
					echo -n "$outline" >> "$2"
				fi
			fi
		done
	} < "$1"
	return 0
}

TTRO_help_copyOnly='
# Function copyOnly
#	Copy all files from input directory to workdir'
function copyOnly {
	copyAndMorph "$TTRO_inputDirCase" "$TTRO_workDirCase" "$TTRO_variantCase"
}

TTRO_help_linewisePatternMatch='
# Function linewisePatternMatch
#	Line pattern validator
#	$1 - the input file
#	$2 - if set to "true" all pattern must generate a match
#	$3 .. - the pattern to match
#	returns
#		success(0)   if file exist and one patten matches ($2 -eq true)
#	                 if file exist and one patten matches ($2 -eq true)
#	return false if no complete pattern match was found or the file not exists'
declare -a patternList=()
function linewisePatternMatch {
	if [[ $# -lt 3 ]]; then printErrorAndExit "$FUNCNAME missing params. Number of Params is $#" $errRt; fi
	isDebug && printDebug "$FUNCNAME $*"
	local -i max=$#
	local -i i
	local -i noPattern=0
	patternList=()
	for ((i=3; i<=max; i++)); do
		patternList[$noPattern]="${!i}"
		noPattern=$((noPattern+1))
	done
	if linewisePatternMatchArray "$1" "$2"; then
		return 0
	else
		return $?
	fi
}

TTRO_help_linewisePatternMatchAndIntercept='
# Function linewisePatternMatchAndIntercept
#	Execute the function linewisePatternMatch guarded and return the result code in TTTT_result
#	Line pattern validator
#	$1 - the input file
#	$2 - if set to "true" all pattern must generate a match
#	$3 .. - the pattern to match
#	returns succes
#	and the result code from linewisePatternMatch in TTTT_result'
function linewisePatternMatchAndIntercept {
	if linewisePatternMatch "$@"; then
		TTTT_result=0
	else
		TTTT_result=$?
	fi
	return 0
}

TTRO_help_linewisePatternMatchInterceptAndSuccess='
# Function linewisePatternMatchInterceptAndSuccess
#	Execute the function linewisePatternMatch guarded and return the result code in TTTT_result
#	Expect success (match found), set failure otherwise
#	Line pattern validator
#	$1 - the input file
#	$2 - if set to "true" all pattern must generate a match
#	$3 .. - the pattern to match
#	returns 
#	and the result code from linewisePatternMatch in TTTT_result'
function linewisePatternMatchInterceptAndSuccess {
	if linewisePatternMatch "$@"; then
		TTTT_result=0
	else
		TTTT_result=$?
		setFailure "Failed $FUNCNAME $*"
	fi
	return 0
}

TTRO_help_linewisePatternMatchInterceptAndError='
# Function linewisePatternMatchInterceptAndError
#	Execute the function linewisePatternMatch guarded and return the result code in TTTT_result
#	Expect failure (no match found), set failure otherwise
#	Line pattern validator
#	$1 - the input file
#	$2 - if set to "true" all pattern must generate a match
#	$3 .. - the pattern to match
#	returns 
#	and the result code from linewisePatternMatch in TTTT_result'
function linewisePatternMatchInterceptAndError {
	if linewisePatternMatch "$@"; then
		TTTT_result=0
		setFailure "Failed: match found: $FUNCNAME $*"
	else
		TTTT_result=$?
	fi
	return 0
}

TTRO_help_linewisePatternMatchArray='
# Function linewisePatternMatchArray
#	Line pattern validator with array input variable
#	the pattern to match as array 0..n are expected to be in patternList array variable
#	$1 - the input file
#	$2 - if set to "true" all pattern must generate a match
#	$patternList the indexed array with the pattern to search
#		success(0)   if file exist and one patten matches ($2 -eq true)
#	                 if file exist and one patten matches ($2 -eq true)
#	return false if no complete pattern match was found or the file not exists'
function linewisePatternMatchArray {
	if [[ $# -ne 2 ]]; then printErrorAndExit "$FUNCNAME invalid no of params. Number of Params is $#" $errRt; fi
	isDebug && printDebug "$FUNCNAME $*"
	local -i i
	local -i noPattern=${#patternList[@]}
	local -a patternMatched=()
	for ((i=0; i<$noPattern; i++)); do
		patternMatched[$i]=0
	done
	if isDebug; then
		local display=$(declare -p patternList);
		printDebug "$display"
	fi
	if [[ -f $1 ]]; then
		local -i matches=0
		local -i line=0
		{
			local result=0;
			line=0
			while [[ result -eq 0 ]]; do
				if ! read -r; then result=1; fi
				if [[ ( result -eq 0 ) || ( ${#REPLY} -gt 0 ) ]]; then
					line=$((line+1))
					isDebug && printDebug "$REPLY"
					for ((i=0; i<$noPattern; i++)); do
						if [[ patternMatched[$i] -eq 0 && $REPLY == ${patternList[$i]} ]]; then
							patternMatched[$i]=1
							matches=$((matches+1))
							echo "$FUNCNAME : Pattern='${patternList[$i]}' matches line=$line in file=$1"
							if [[ -z $2 ]]; then
								break 2
							fi
						fi
						if [[ $matches -eq $noPattern ]]; then
							break 2
						fi
					done
				fi
			done
		} < "$1"
		if [[ $2 == 'true' ]]; then
			if [[ $matches -eq $noPattern ]]; then
				echo "$FUNCNAME : $matches matches found in file=$1"
				return 0
			else
				local display=$(declare -p patternList)
				echo "$FUNCNAME : Only $matches of $noPattern pattern maches found in file=$1"
				echo "Pattern=$display"
				return $errTestFail
			fi
		else
			if [[ $matches -gt 0 ]]; then
				echo "$FUNCNAME : $matches matches found in file=$1"
				return 0
			else
				local display=$(declare -p patternList)
				echo "$FUNCNAME : No match found in file=$1"
				echo "Pattern=$display"
				return $errTestFail
			fi
		fi
	else
		echo "$FUNCNAME: can not open file $1"
		return $errTestFail
	fi
}

TTRO_help_echoAndExecute='
# Function echoAndExecute
#	echo and execute a command with variable arguments
#	success is expected and no further evaluation of the output is required
# Parameters:
#	$1    - the command string
#	$2 .. - optional the parameters of the command
# Returns:
#	the result code of the executed command
# Exits:
#	if no command string is given or the command is empty
#	if the function is not guarded with conditional statement and the executed command returns an error code'
function echoAndExecute {
	if [[ $# -lt 1 || -z $1 ]]; then
		printErrorAndExit "${FUNCNAME[0]} called with no or empty command" $errRt
	fi
	local cmd="$1"
	shift
	local disp0="${FUNCNAME[1]} -> ${FUNCNAME[0]}: "
	printInfo "$disp0 $cmd $*"
	"$cmd" "$@"
}

TTRO_help_echoExecuteAndIntercept='
# Function echoExecuteAndIntercept
#	echo and execute the command line
#	the command execution is guarded and the result code is stored
# Parameters:
#	$1    - the command string
#	$2 .. - optional the parameters of the command
# Returns:
#	success
# Exits:
#	if no command string is given or the command is empty
# Side Effects:
#	TTTT_result - the result code of the executed command'
function echoExecuteAndIntercept {
	if [[ $# -lt 1 || -z $1 ]]; then
		printErrorAndExit "${FUNCNAME[0]} called with no or empty command" $errRt
	fi
	local cmd="$1"
	shift
	local disp0="${FUNCNAME[1]} -> ${FUNCNAME[0]}: "
	printInfo "$disp0 $cmd $*"
	if "$cmd" "$@"; then
		TTTT_result=0
	else
		TTTT_result=$?
	fi
	printInfo "$cmd returns $TTTT_result"
	return 0
}

TTRO_help_echoExecuteInterceptAndSuccess='
# Function echoExecuteInterceptAndSuccess
#	echo and execute the command line
#	a successfull command execution is expected
#	the failure condition is set in case of failure
# Parameters:
#	$1    - the command string
#	$2 .. - optional the parameters of the command
# Returns
#	success
# Exits:
#	if no command string is given or the command is empty
# Side Effects:
#	TTTT_result - the result code of the executed command
#	The failure condition is set if the command returns failure'
function echoExecuteInterceptAndSuccess {
	if [[ $# -lt 1 || -z $1 ]]; then
		printErrorAndExit "${FUNCNAME[0]} called with no or empty command" $errRt
	fi
	local cmd="$1"
	shift
	local disp0="${FUNCNAME[1]} -> ${FUNCNAME[0]}: "
	printInfo "$disp0 $cmd $*"
	if "$cmd" "$@"; then
		TTTT_result=0
	else
		TTTT_result=$?
		setFailure "$TTTT_result : returned from $cmd"
	fi
	printInfo "$TTTT_result : returned from $cmd"
	return 0
}

TTRO_help_echoExecuteInterceptAndError='
# Function echoExecuteInterceptAndError
#	echo and execute the command line
#	a failure code is expected in the command return
#	the failure condition is set in case of cmd success
# Parameters:
#	$1    - the command string
#	$2 .. - optionally the parameters of the command
# Returns:
#	success
# Exits:
#	if no command string is given or the command is empty
# Side Effects_
#	TTTT_result - the result code of the executed command
#	The failure condition is set if the command returns success'
function echoExecuteInterceptAndError {
	if [[ $# -lt 1 || -z $1 ]]; then
		printErrorAndExit "${FUNCNAME[0]} called with no or empty command" $errRt
	fi
	local cmd="$1"
	shift
	local disp0="${FUNCNAME[1]} -> ${FUNCNAME[0]}: "
	printInfo "$disp0 $cmd $*"
	if "$cmd" "$@"; then
		TTTT_result=0
		setFailure "$TTTT_result : returned from $cmd"
	else
		TTTT_result=$?
	fi
	printInfo "$TTTT_result : returned from $cmd"
	return 0
}

TTRO_help_echoExecuteAndIntercept2='
# Function echoExecuteAndIntercept2
#	echo and execute the command line
#	additionally the expected returncode is checked
#	if the expected result is not received the failure condition is set 
#	the function returns success(0)
#	the function exits if an input parameter is wrong
# Parameters:
#	$1 success - returncode 0 expected
#	   error   - returncode ne 0 expected
#	   X       - any return value is accepted
#	   number  - the numeric return code is expected
#	$2 - the command string
#	$3 .. - optional the parameters for the command
# Returns:
#	success
# Exits:
#	If the number of parameters is -lt 2 ot the command is empty
# Side Effects:
#'
function echoExecuteAndIntercept2 {
	if [[ $# -lt 2 || -z $2 ]]; then
		printErrorAndExit "${FUNCNAME[0]} called with no or empty command" $errRt
	fi
	if [[ $1 != success && $1 != error && $1 != X ]]; then
		if ! isNumber "$1" ]]; then
			printErrorAndExit "${FUNCNAME[0]} called with wrong parameters: $*" $errRt
		fi
	fi
	local code="$1"
	shift
	local cmd="$1"
	shift
	local myresult=''
	local disp0="${FUNCNAME[1]} -> ${FUNCNAME[0]}: "
	printInfo "$disp0 $cmd $*"
	if "$cmd" "$@"; then
		myresult=0
	else
		myresult=$?
	fi
	case "$code" in
		success)
			if [[ $myresult -eq 0 ]]; then
				isDebug && printDebug "${FUNCNAME} success"
			else
				setFailure "${FUNCNAME[0]} Unexpected failure $myresult in cmd $*"
			fi;;
		error)
			if [[ $myresult -eq 0 ]]; then
				setFailure "${FUNCNAME[0]} Unexpected success in cmd $*"
			else
				isDebug && printDebug "${FUNCNAME} success"
			fi;;
		X)
			isDebug && printDebug "${FUNCNAME} success";;
		*)
			if [[ $myresult -eq $code ]]; then
				isDebug && printDebug "${FUNCNAME} success"
			else
				setFailure "${FUNCNAME[0]} wrong failure code $myresult in cmd $*"
			fi;;
	esac
	return 0
}

TTRO_help_executeAndLog='
# Function executeAndLog
#	echo and execute a command
#	the command execution is guarded and the result code is stored
#	the std- and error-out is logged into a file for further evaluation
# Parameters:
#	$1    - the command string
#	$2 .. - optional the parameters of the command
#	$TT_evaluationFile - the file name of the log file default is ./EVALUATION.log
# Returns:
#	success
# Exits:
#	if no command string is given or the command is empty
# Side Effects:
#	TTTT_result - the result code of the executed command'
function executeAndLog {
	if [[ $# -lt 1 || -z $1 ]]; then
		printErrorAndExit "${FUNCNAME[0]} called with no or empty command" $errRt
	fi
	local cmd="$1"
	shift
	local disp0="${FUNCNAME[1]} -> ${FUNCNAME[0]}: "
	printInfo "$disp0 $cmd $*"
	if "$cmd" "$@" 2>&1 | tee "$TT_evaluationFile"; then
		TTTT_result=0
	else
		TTTT_result=$?
	fi
	printInfo "$TTTT_result : returned from $cmd"
	return 0
}

TTRO_help_executeLogAndSuccess='
# Function executeLogAndSuccess
#	echo and execute a command
#	the command execution is guarded and the result code is stored
#	the std- and error-out is logged into a file for further evaluation
#	a successfull command execution is expected, otherwise the failure condition is set
# Parameters:
#	$1    - the command string
#	$2 .. - optional the parameters of the command
#	$TT_evaluationFile - the file name of the log file default is ./EVALUATION.log
# Returns:
#	success
# Exits:
#	if no command string is given or the command is empty
# Side Effects:
#	TTTT_result - the result code of the executed command
#	The failure condition is set if the command returns failure'
function executeLogAndSuccess {
	if [[ $# -lt 1 || -z $1 ]]; then
		printErrorAndExit "${FUNCNAME[0]} called with no or empty command" $errRt
	fi
	local cmd="$1"
	shift
	local disp0="${FUNCNAME[1]} -> ${FUNCNAME[0]}: "
	printInfo "$disp0 $cmd $*"
	if "$cmd" "$@" 2>&1 | tee "$TT_evaluationFile"; then
		TTTT_result=0
	else
		TTTT_result=$?
		setFailure "$TTTT_result : returned from $cmd"
	fi
	printInfo "$TTTT_result : returned from $cmd"
	return 0
}

TTRO_help_executeLogAndError='
# Function executeLogAndError
#	echo and execute a command
#	the command execution is guarded and the result code is stored
#	the std- and error-out is logged into a file for further evaluation
#	an error command execution is expected, otherwise the failure condition is set
# Parameters:
#	$1    - the command string
#	$2 .. - optional the parameters of the command
#	$TT_evaluationFile - the file name of the log file default is ./EVALUATION.log
# Returns:
#	success
# Exits:
#	if no command string is given or the command is empty
# Side Effects:
#	TTTT_result - the result code of the executed command
#	The failure condition is set if the command returns success'
function executeLogAndError {
	if [[ $# -lt 1 || -z $1 ]]; then
		printErrorAndExit "${FUNCNAME[0]} called with no or empty command" $errRt
	fi
	local cmd="$1"
	shift
	local disp0="${FUNCNAME[1]} -> ${FUNCNAME[0]}: "
	printInfo "$disp0 $cmd $*"
	if "$cmd" "$@" 2>&1 | tee "$TT_evaluationFile"; then
		TTTT_result=0
		setFailure "$TTTT_result : returned from $cmd"
	else
		TTTT_result=$?
	fi
	printInfo "$TTTT_result : returned from $cmd"
	return 0
}

TTRO_help_renameInSubdirs='
# Function renameInSubdirs
#	Renames a special file name in all base directory and in all sub directories
#	$1 the base directory
#	$2 the source filename
#	$3 the destination filename'
function renameInSubdirs {
	if [[ $# -ne 3 ]]; then printErrorAndExit "$FUNCNAME invalid no of params. Number of Params is $#" $errRt; fi
	isDebug && printDebug "$FUNCNAME $*"
	local x mdir destf
	for x in $1/**/$2; do
		mdir="${x%/*}"
		destf="${mdir}/$3"
		mv -v "$x" "$destf"
	done
	return 0
}

TTRO_help_isInList='
# check whether a token is in a space separated list of tokens
#	$1 the token to search. It must not contain whitespaces
#	$2 the space separated list
#	returns true if the token was in the list; false otherwise
#	exits if called with wrong parameters'
function isInList {
	if [[ $# -ne 2 ]]; then printErrorAndExit "$FUNCNAME invalid no of params. Number of Params is $#" $errRt; fi
	isDebug && printDebug "$FUNCNAME $*"
	if [[ $1 == *[[:space:]]* ]]; then
		printErrorAndExit "The token \$1 must not be empty and must not have spaces \$1='$1'" $errRt
	else
		local x
		local isFound=''
		for x in $2; do
			if [[ $x == $1 ]]; then
				isFound="true"
				break
			fi
		done
		if [[ -n $isFound ]]; then
			isDebug && printDebug "$FUNCNAME return 0"
			return 0
		else
			isDebug && printDebug "$FUNCNAME return 1"
			return 1
		fi
	fi
}

TTRO_help_isInListSeparator='
# check whether a token is in a list of tokens with a special separator
#	$1 the token to search. It must not contain any of the separator tokens
#	$2 the list
#	$3 the separators
#	returns true if the token was in the list; false otherwise
#	exits if called with wrong parameters'
function isInListSeparator {
	if [[ $# -ne 3 ]]; then printErrorAndExit "$FUNCNAME invalid no of params. Number of Params is $#" $errRt; fi
	isDebug && printDebug "$FUNCNAME $*"
	if [[ $1 == *[$3]* ]]; then
		printErrorAndExit "The token \$1 must not be empty and must not have separator characters \$1='$1'" $errRt
	else
		local x
		local isFound=''
		local IFS="$3"
		for x in $2; do
			if [[ $x == $1 ]]; then
				isFound="true"
				break
			fi
		done
		if [[ -n $isFound ]]; then
			isDebug && printDebug "$FUNCNAME return 0"
			return 0
		else
			isDebug && printDebug "$FUNCNAME return 1"
			return 1
		fi
	fi
}

TTRO_help_import='
# Function import
#	Treats the input as filename and adds it to TT_tools if not already there
#	sources the file if it was not in TT_tools
#	return the result code of the source command'
function import {
	isDebug && printDebug "$FUNCNAME $*"
	local tmp=$(readlink -m "$1")
	if isInList "$tmp" "$TTXX_tools"; then
		printWarning "file $tmp is already registerd in TTXX_tools=$TTXX_tools"
		return 0
	else
		TTXX_tools="$TTXX_tools $tmp"
		export TTXX_tools
		source "$tmp"
	fi
}

TTRO_help_waitForFileToAppear='
# Function waitForFileToAppear
#	Wait until a file appears
# Parameters:
#	$1 - the file name to check
#	$2 - optional the check interval default is 3 sec.
# Returns:
#	success if the file was found
# Exits:
# if the function was called with invalid parameters'
function waitForFileToAppear {
	if [[ ( $# -lt 1 ) || ( $# -gt 2 ) ]]; then printErrorAndExit "$FUNCNAME invalid no of params. Number of Params is $#" $errRt; fi
	local timeoutValue=3
	if [[ $# -eq 2 ]]; then
		timeoutValue="$2"
	fi
	while ! [[ -e $1 ]]; do
		printInfo "Wait for file to appear $1"
		sleep "$timeoutValue"
	done
	printInfo "File to appear $1 exists"
	return 0
}

TTRO_help_getLineCount='
# Function getLineCount
#	Get the number of lines in a file
# Parameters:
#	$1 the file name
# Returns:
#	the status of the ececuted commands
# Exits:
# if the function was called with invalid parameters
# Side Effects:
#	TTTT_lineCount - the number of lines in the file'
function getLineCount {
	if [[ $# -ne 1 ]]; then printErrorAndExit "$FUNCNAME invalid no of params. Number of Params is $#" $errRt; fi
	TTTT_lineCount=$(wc -l "$1" | cut -f 1 -d ' ')
}


TTRO_help_promptYesNo='
# Function promptYesNo
#	Write prompt and wait for user input y/n
#	optional $1 the text for the prompt
#	honors TTRO_noPrompt
#	returns
#		success(0) if y/Y was enterd
#		error(1) if n/N was entered
#	exits id ^C was pressed'
function promptYesNo {
	if [[ -n $TTRO_noPrompt ]]; then return 0; fi
	local pr="Continue or not? y/n "
	if [[ $# -gt 0 ]]; then
		pr="$1"
	fi
	local inputWasY=''
	while read -p "$pr"; do
		if [[ $REPLY == y* || $REPLY == Y* || $REPLY == c* || $REPLY == C* ]]; then
			inputWasY='true'
			break
		elif [[ $REPLY == e* || $REPLY == E* || $REPLY == n* || $REPLY == N* ]]; then
			inputWasY=''
			break
		fi
	done
	if [[ -n $inputWasY ]]; then
		return 0
	else
		return 1
	fi
}

TTRO_help_getSystemLoad='
# Function get the current system load
#	returns the load value in TTTT_systemLoad'
function getSystemLoad {
	local v1=$(</proc/loadavg)
	TTTT_systemLoad="${v1%% *}"
}

TTRO_help_getSystemLoad100='
# Function get the current system load as integer
#	system load x 100
#	returns the load value in TTTT_systemLoad100'
function getSystemLoad100 {
	getSystemLoad
	local integer=${TTTT_systemLoad%%.*}
	[[ -z $integer ]] && printErrorAndExit "No valid TTTT_systemLoad : $TTTT_systemLoad" $errRt
	local fraction=0
	if [[ $TTTT_systemLoad != $integer ]]; then
		fraction=${TTTT_systemLoad#*.}
		if [[ -z $fraction ]]; then
			fraction=0
		elif [[ ${#fraction} -eq 1 ]]; then
			fraction="${fraction}0"
		elif [[ ${#fraction} -gt 2 ]]; then
			fraction="${fraction:0:2}"
		fi
		fraction=$((10#$fraction))
	fi
	integer=$((integer*100))
	TTTT_systemLoad100=$((integer+fraction))
}

TTRO_help_trim='
# Function trim removes leading trailing whitespace characters
#	$1	the input string
#	returns the result string in TTTT_trim'
function trim {
	if [[ $# -ne 1 ]]; then printErrorAndExit "$FUNCNAME invalid no of params. Number of Params is $#" $errRt; fi
	local locvar="$1"
	locvar="${locvar#${locvar%%[![:space:]]*}}"
	TTTT_trim="${locvar%${locvar##*[![:space:]]}}"
	return 0
}

TTRO_help_timeFromSeconds='
# Function timeFromSeconds
#	returns a formated string hh:mm:ss from seconds
#	parameters
#		$1   input in seconds
#	return	
#		TTTT_timeFromSeconds the formated string
#		success'
function timeFromSeconds {
	if [[ $# -ne 1 ]]; then printErrorAndExit "$FUNCNAME invalid no of params. Number of Params is $#" $errRt; fi
	local seconds="$1"
	local sec=$((seconds%60))
	if [[ ${#sec} -eq 1 ]]; then sec="0$sec"; fi
	local hour=$((seconds/60))
	local minutes=$((hour%60))
	if [[ ${#minutes} -eq 1 ]]; then minutes="0$minutes"; fi
	hour=$((hour/60))
	if [[ ${#hour} -eq 1 ]]; then hour="0$hour"; fi
	TTTT_timeFromSeconds="${hour}:${minutes}:${sec}"
	return 0
}

TTRO_help_getElapsedTime='
# Function get the elapsed time string in TTTT_elapsedTime
#	parameters
#		$1 the start time in seconds
#	return
#		TTTT_elapsedTime'
function getElapsedTime {
	if [[ $# -ne 1 ]]; then printErrorAndExit "$FUNCNAME wrong no of arguments $#" $errRt; fi
	local now=$(date -u +%s)
	local diff=$((now-$1))
	timeFromSeconds "$diff"
	TTTT_elapsedTime="$TTTT_timeFromSeconds"
	return 0
}

#Guard for the last statement - make returncode always 0
:
