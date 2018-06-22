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
