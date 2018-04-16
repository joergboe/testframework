######################################################
# Utilities for testframework
# (public utilities)
######################################################

TTRO_help_setFailure='
# Function setFailure
#	set a use defined failure condition
#	to be used in failed test cases
#	$1 the failure text'
function setFailure {
	if [[ $# -gt 0 ]]; then
		if [[ -n $1 ]]; then
			failureOccurred="$1"
		else
			failureOccurred='true'
		fi
	else
		failureOccurred='true'
	fi
	return 0
}

TTRO_help_skip='
# Function skip
#	set the skip condition TTPRN_skip=true'
function skip {
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
	echo -e "\033[31mERROR: $1\033[0m" >&2
	#local -i depth=${#FUNCNAME[@]}
	#local -i i
	#echo $depth
	#for ((i=depth-2; i>=0; i--)); do
#		echo xcxcxcxcxcx
	#	caller $i
	#done
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
	skipthis='true'
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

TTRO_help_splitVarValue='
# Function splitVarValue
#	Split an line #*#varname=value into the components
#	and           #*#varname:=value
#
#	Ignore all other lines
#	ignore empty lines and lines with only spaces
#	varname must not be empty and must not contain any blank characters
#	$1 the input line (only one line without nl)
#	return variables:
#		varname
#		value
#       splitter
#	returns
#		success(0) if the function succeeds
#		error(1)   otherwise'
function splitVarValue {
	isDebug && printDebug "$FUNCNAME \$1='$1'"
	if [[ $1 == \#--* ]]; then
		local tmp=${1#*#--}
		if [[ -n $tmp && (${tmp//[[:blank:]]/} != "" ) ]]; then
			local value1=${tmp#*:=}
			local name1=${tmp%%:=*}
			#echo "name1=$name1 value1=$value1"
			if [[ "$value1" != "$tmp" && "$name1" != "$tmp" ]]; then #there was something removed -> there was a =
				splitter=':='
			else
				value1=${tmp#*=}
				name1=${tmp%%=*}
				#echo "name1=$name1 value1=$value1"
				if [[ "$value1" != "$tmp" && "$name1" != "$tmp" ]]; then #there was something removed -> there was a :=
					splitter='='
				else
					printError "$FUNCNAME: No '=' in special comment line '$1' Ignored"
					return 1
				fi
			fi
			#if [[ $tmp =~ (.*)=(.*) ]]; then problem if more tah one = in line
			#	local name1=${BASH_REMATCH[1]}
			#	local value1=${BASH_REMATCH[2]}
			if [[ -n $name1 && ! ( $name1 =~ [[:blank:]] ) ]] ; then
				varname="$name1"
				value="$value1"
				return 0
			else
				printError "$FUNCNAME: Varname contains blanks in special comment line '$1' Ignored"
				return 1
			fi
		else
			return 1
		fi
	else
		return 1
	fi
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
#	$1 - the name of the variable to set
#	$2 - the value
#	returns success (0):
#		if the variable could be set or if an property value is ignored
#	exits:
#		if variable is not of type TT_, TTRO_, TTPR_ or TTPRN_
#		or if the variable could not be set (e.g a readonly variable was already set
#		ignored property values do not generate an error'
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
#	$1 var name to be checked
#	returns
#		success(0)    if the variable exists
#		error(1)      otherwise'
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
#	$1 var name to be checked
#	returns
#		success(0)    if the variable not exists
#		error(1)      otherwise'
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
#	$1 var name to be checked
#	returns
#		success(0)    exists and has a non empty value
#		error(1)      otherwise'
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
#	$1 var name to be checked
#	returns
#		success(0)    exists and has an empty value
#		error(1)      otherwise'
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
#	$1 var name to be checked
#	returns
#		success(0)    variable exists and has a non empty value
#		error(1)      variable exists and has a empty value
#	exits if variable not exists'
function isTrue {
	if [[ -n ${!1} ]]; then
		isDebug && printDebug "$FUNCNAME $1 return 0"
		return 0
	else
		isDebug && printDebug "$FUNCNAME $1 return 1"
		return 1
	fi
}

TTRO_help_isFalse='
# Function isFalse
#	check if a variable has an empty value
#	$1 var name to be checked
#	returns
#		success(0)    if the variable exists and has a empty value
#		error(1)      if the variable exists and has an non empty value
#	exits if variable not exists'
function isFalse {
	if [[ -z ${!1} ]]; then
		isDebug && printDebug "$FUNCNAME $1 return 0"
		return 0
	else
		isDebug && printDebug "$FUNCNAME $1 return 1"
		return 1
	fi
}

TTRO_help_isArray='
# Function isArray
#	checks whether an variable exists and is an indexed array
#	$1 var name to be checked
#	returns
#		success(0)   if the variable exists and is an indexed array
#		error(1)     otherwise'
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

TTRO_help_isFunction='
# Function isFunction
#	checks whether an given name is defined as function
#	$1 name to be checked
#		success(0)   if the function exists
#		error(1)     otherwise'
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
#	check is an associative array has key
#	$1 the array name
#	$2 the key value to search
#	returns
#		success(0)    if key exists in array
#		error(1)      otherwise
#	exits if called with wrong arguments'
function arrayHasKey {
	if [[ $# -ne 2 ]]; then printErrorAndExit "$FUNCNAME must have 2 aruments" $errRt; fi
	isDebug && printDebug "$FUNCNAME $1 $2"
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
#	Copy and change all files from input dirextory into workdir
#	Filenames that match one of the transformation pattern are transformed. All other files are copied.
#	In case of transformation the pattern //_<varid> is removed if varid equals $3
#	In case of transformation the pattern //!<varid> is removed if varid is different than $3
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
		isDebug && printDebug "$FUNCNAME item to process step2: $x"
		if [[ ! -d $x ]]; then
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
							#isDebug && printDebug "$FUNCNAME: part1='$part1'"
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
									#isDebug && printDebug "$FUNCNAME: part1='$part1'"
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

TTRO_help_copyOnly='
# Function copyOnly
#	Copy all files from input directory to workdir'
function copyOnly {
	copyAndTransform "$TTRO_inputDirCase" "$TTRO_workDirCase" "$TTRO_variantCase"
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
#	$1 the command string
#	$2 .. the parameters of the command
#	returns the result code of the executed command
#	exits if no command string is given or command is empty'
function echoAndExecute {
	if [[ $# -lt 1 || -z $1 ]]; then
		printErrorAndExit "${FUNCNAME[0]} called with no or empty command" $errRt
	fi
	local cmd="$1"
	shift
	local disp0="${FUNCNAME[0]} called from ${FUNCNAME[1]}: "
	printInfo "$disp0 $cmd $*"
	"$cmd" "$@"
}

TTRO_help_echoExecuteAndIntercept='
# Function echoExecuteAndIntercept
#	echo and execute the command line
#	additionally the returncode is checked
#	if the expected result is not received the failure condition is set 
#	the function returns success(0)
#	the function exits if an input parameter is wrong
#	$1 success - returncode 0 expected
#	   error   - returncode ne 0 expected
#	   number  - the numeric return code is expected
#	$2 the command string
#	$3 the parameters as one string - during execution expansion and word splitting is applied'
function echoExecuteAndIntercept {
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
	local disp0="${FUNCNAME[0]} called from ${FUNCNAME[1]}: "
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

TTRO_help_import='
# Function registerTool
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

#Guard for the last statement - make returncode always 0
:
