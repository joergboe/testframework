# prepares the properties and readonly properties for the export and sets all variables
# read from the testcase/suite file
# expects that fixPropsVars is called afer
# outputs the variables
# input $1 : must be the filename
function setProperties {
	isDebug && printDebug "$FUNCNAME $1"
	if [[ ! -r $1 ]]; then
		printErrorAndExit "${FUNCNAME} : Can not open file=$1 for read" ${errRt}
	fi
	declare -i lineno=1
	{
		local varname="" value="" splitter=""
		local result=0 internalResult=0
		while [[ result -eq 0 ]]; do
			if ! read -r; then result=1; fi
			if [[ ( result -eq 0 ) || ( ${#REPLY} -gt 0 ) ]]; then #do not eval the last and empty line
				if splitVarValue "$REPLY"; then
					if [[ -n $varname ]] ; then
						isDebug && printDebug "$FUNCNAME prepare for export varname=$varname value=$value splitter=$splitter"
						case $varname in
							TTPRN_* )
								#set property only if it is unset or null
								if ! declare -p ${varname} &> /dev/null || [[ -z ${!varname} ]]; then
									if [[ $splitter == ":=" ]]; then
										if eval export \'${varname}\'='"${value}"'; then internalResult=0; else internalResult=1; fi
									else
										if eval export \'${varname}\'="${value}"; then internalResult=0; else internalResult=1; fi
									fi
									if [[ $internalResult -ne 0 ]]; then
										printErrorAndExit "${FUNCNAME} : Invalid expansion in case- or suit-efile file=$1 line=$lineno varname=${varname} value=${value} '$REPLY'" ${errRt}
									else
										isVerbose && printVerbose "${varname}='${!varname}'"
									fi
								else
									isVerbose && printVerbose "$FUNCNAME ignore value for ${varname} in file=$1 line=$lineno"
								fi
							;;
							TTPR_* )
								#set property only if it is unset
								if ! declare -p "${varname}" &> /dev/null; then
									if [[ $splitter == ":=" ]]; then
										if eval export \'${varname}\'='"${value}"'; then internalResult=0; else internalResult=1; fi
									else
										if eval export \'${varname}\'="${value}"; then internalResult=0; else internalResult=1; fi
									fi
									if [[ $internalResult -ne 0 ]]; then
										printErrorAndExit "${FUNCNAME} : Invalid expansion in case- or suite-file file=$1 line=$lineno varname=${varname} value=${value} '$REPLY' file=$1" ${errRt}
									else
										isVerbose && printVerbose "${varname}='${!varname}'"
									fi
								else
									isVerbose && printVerbose "$FUNCNAME ignore value for ${varname} in file=$1 line=$lineno"
								fi
							;;
							TTRO_* )
								#set a global readonly variable
								if [[ $splitter == ":=" ]]; then
									if eval export \'${varname}\'='"${value}"'; then internalResult=0; else internalResult=1; fi
								else
									if eval export \'${varname}\'="${value}"; then internalResult=0; else internalResult=1; fi
								fi
								if [[ $internalResult -ne 0 ]]; then
									printErrorAndExit "${FUNCNAME} : Invalid expansion in case- or suite-file file=$1 line=$lineno varname=${varname} value=${value} '$REPLY' file=$1" ${errRt}
								else
									isVerbose && printVerbose "${varname}='${!varname}'"
								fi
							;;
							TT_* )
								#set a global variable
								if [[ $splitter == ":=" ]]; then
									if eval export \'${varname}\'='"${value}"'; then internalResult=0; else internalResult=1; fi
								else
									if eval export \'${varname}\'="${value}"; then internalResult=0; else internalResult=1; fi
								fi
								if [[ $internalResult -ne 0 ]]; then
									printErrorAndExit "${FUNCNAME} : Invalid expansion in case- or suite-file file=$1 line=$lineno varname=${varname} value=${value} '$REPLY' file=$1" ${errRt}
								else
									isVerbose && printVerbose "${varname}='${!varname}'"
								fi
							;;
							variantCount|variantList )
								#ignore test variant variables
								isDebug && printDebug "Ignore $varname in file=$1 line=$lineno"
							;;
							* )
								#other variables
								printErrorAndExit "${FUNCNAME} : Invalid property or variable in case- or suite-file file=$1 line=$lineno varname=${varname} value=${value} '$REPLY' file=$1" ${errRt}
							;;
						esac
					else
						printErrorAndExit "${FUNCNAME} : Invalid line or property name in case- or suite-file file=$1 line=$lineno '$REPLY'" ${errRt}
					fi
				else
					isDebug && printDebug "Ignore line file=$1 line=$lineno '$REPLY'"
				fi
				lineno=$((lineno+1))
			fi
		done
	} < "$1"
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
#		splitter
#	returns
#		success(0) if the function succeeds
#		error(1)   otherwise'
function splitVarValue___ {
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

