#####################################################
# Utilities for the core testframework script code
#####################################################

#
# function to execute the variants of suites
# $1 the suite index to execute
# $2 is the variant to execute
# $3 nesting level of suite (parent)
# $4 the chain of suite names delim / (parent)
# $5 the chain of suite string including variants delim :: : (parent value)
# $6 parent sworkdir
# expect suiteVariants suiteErrors
function exeSuite {
	isDebug && printDebug "******* $FUNCNAME $*"
	local suite="${suitesName[$1]}"
	local suitePath="${suitesPath[$1]}"
	local nestingLevel=$(($3+1))
	local suiteNestingPath="$4"
	local suiteNestingString="$5"
	if [[ $1 -ne 0 ]]; then
		if [[ -z $suiteNestingPath ]]; then
			suiteNestingPath+="${suite}"
		else
			suiteNestingPath+="/${suite}"
		fi
		if [[ -z $suiteNestingString ]]; then
			suiteNestingString+="$suite"
		else
			suiteNestingString+="::$suite"
		fi
	fi
	if [[ -n $2 ]]; then
		suiteNestingString+=":$2"
	fi
	if [[ -z ${executeSuite[$1]} ]]; then
		isDebug && printDebug "$FUNCNAME: no execution of suite $suitePath: variant='$2'"
		return 0
	fi
	printInfo "**** START Suite: ${suite} variant='$2' in ${suitePath} *****************"
	#make and cleanup suite work dir
	local sworkdir="$TTRO_workDir"
	if [[ -n $suiteNestingPath ]]; then
		sworkdir="$sworkdir/$suiteNestingPath"
	fi
	if [[ -n $2 ]]; then
		sworkdir="$sworkdir/$2"
	fi
	isDebug && printDebug "suite workdir is $sworkdir"
	if [[ -e $sworkdir ]]; then
		if [[ $1 -ne 0 ]]; then
			rm -rf "$sworkdir"
		fi
	fi
	if [[ $1 -ne 0 ]]; then
		mkdir -p "$sworkdir"
	fi

	# count execute suites but do not count the root suite
	if [[ $nestingLevel -gt 0 ]]; then
		suiteVariants=$((suiteVariants+1))
		builtin echo "$suiteNestingString" >> "${6}/SUITE_EXECUTE"
	fi

	#execute suite variant
	local result=0
	if "${TTRO_scriptDir}/suite.sh" "$1" "$2" "${sworkdir}" "$nestingLevel" "$suiteNestingPath" "$suiteNestingString" 2>&1 | tee -i "${sworkdir}/${TEST_LOG}"; then
		result=0;
	else
		result=$?
		if [[ $result -eq $errSigint ]]; then
			printWarning "Set SIGINT Execution of suite ${suite} variant '$2' ended with result=$result"
			interruptReceived=$((interruptReceived+1))
		else
			if [[ $nestingLevel -gt 0 ]]; then
				printError "Execution of suite ${suite} variant '$2' ended with result=$result"
				suiteErrors=$(( suiteErrors + 1))
				builtin echo "$suiteNestingString" >> "${6}/SUITE_ERROR"
			else
				printErrorAndExit "Execution of root suite failed" $errRt
			fi
		fi
	fi
	
	#read result lists and append results to the own list
	local x
	if [[ $1 -ne 0 ]]; then
		for x in CASE_EXECUTE CASE_SKIP CASE_FAILURE CASE_ERROR CASE_SUCCESS SUITE_EXECUTE SUITE_SKIP SUITE_ERROR; do
			local inputFileName="${sworkdir}/${x}"
			local outputFileName="${6}/${x}"
			eval "local ${x}_Count=0"
			if [[ -e ${inputFileName} ]]; then
				{ while read; do
					if [[ $REPLY != \#* ]]; then
						echo "$REPLY" >> "$outputFileName"
						eval "${x}_Count=$((${x}_Count+1))"
					fi
				done } < "${inputFileName}"
			else
				printError "No result list $inputFileName in suite $sworkdir"
			fi
		done
	fi

	# html
	if [[ $nestingLevel -gt 0 ]]; then
		addSuiteEntry "$indexfilename" "$suiteNestingString" "$result" "$suitePath" "${sworkdir}"\
		$CASE_EXECUTE_Count $CASE_SKIP_Count $CASE_FAILURE_Count $CASE_ERROR_Count $CASE_SUCCESS_Count $SUITE_EXECUTE_Count $SUITE_SKIP_Count $SUITE_ERROR_Count
	fi
	
	printInfo "**** END Suite: ${suite} variant='$2' in ${suitePath} *******************"
	return 0
} #/exeSuite

#
# Read a test case or a test suite file and extracts the variables
# variantCount and variantList and conditional the type; ignore the rest
# $1 is the filename to read
# return 0 in success case
# exits with ${errRt} if an invalid line was read;
# results are returned in global variables variantCount; variantList
function readVariantFile {
	isDebug && printDebug "$FUNCNAME $1"
	if [[ ! -r $1 ]]; then
		printErrorAndExit "${FUNCNAME} : Can not open file=$1 for read" ${errRt}
	fi
	variantCount=""; variantList=""; splitter=""
	declare -i lineno=1
	{
		local varname=
		local value=
		local result=0
		local unq
		while [[ result -eq 0 ]]; do
			if ! read -r; then result=1; fi
			if [[ ( result -eq 0 ) || ( ${#REPLY} -gt 0 ) ]]; then #do not eval the last and empty line
				if splitVarValue "$REPLY"; then
					if [[ -n $varname ]] ; then
						isDebug && printDebug "$FUNCNAME prepare for variant encoding varname=$varname value=$value"
						case $varname in
							variantCount )
								unq=$(dequote "${value}")
								if ! variantCount="${unq}"; then
									printErrorAndExit "${FUNCNAME} : Invalid value in file=$1 line=$lineno '$REPLY'" ${errRt}
								fi
								if ! isPureNumber "$variantCount"; then
									printErrorAndExit "${FUNCNAME} : variantCount is no digit in file=$1 line=$lineno '$REPLY'" ${errRt}
								fi
								isVerbose && printVerbose "variantCount='${variantCount}'"
							;;
							variantList )
								unq=$(dequote "${value}")
								if ! variantList="${unq}"; then
									printErrorAndExit "${FUNCNAME} : Invalid value in file=$1 line=$lineno '$REPLY'" ${errRt}
								fi
								isVerbose && printVerbose "variantList='${variantList}'"
							;;
							timeout )
								unq=$(dequote "${value}")
								if ! timeout="${unq}"; then
									printErrorAndExit "${FUNCNAME} : Invalid value in file=$1 line=$lineno '$REPLY'" ${errRt}
								fi
								if ! isPureNumber "$timeout"; then
									printErrorAndExit "${FUNCNAME} : timeout is no digit in file=$1 line=$lineno '$REPLY'" ${errRt}
								fi
								isVerbose && printVerbose "timeout='${timeout}'"
							;;
							* )
								#other property or variable
								isDebug && printDebug "${FUNCNAME} : Ignore varname='$varname' in file $1 line=$lineno"
							;;
						esac
					else
						printErrorAndExit "${FUNCNAME} : Invalid line or property name in case or suitefile file=$1 line=$lineno '$REPLY'" ${errRt}
					fi
				fi
					#isDebug && printDebug "Ignore line file=$1 line=$lineno '$REPLY'"
				lineno=$((lineno+1))
			fi
		done
	} < "$1"
	return 0
}

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
							TTPN_* )
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
							TTP_* )
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

#
# write protect all exported fuinctions
function writeProtectExportedFunctions {
	local functions=$(declare -Fx)
	local IFS=$'\n'
	local x fname
	for x in $functions; do
		fname="${x##* }"
		readonly -f "$fname"
	done
}

#
# Create the global index.html
# $1 the file to create
function createGlobalIndex {
	cat <<-EOF > "$1"
	<!DOCTYPE html>
	<html>  
	<head>    
		<title>Test Report Collection '$TTRO_collection'</title>
		<meta charset='utf-8'>
	</head>  
	<body>    
		<h1 style="text-align: center;">Test Report Collection '$TTRO_collection'</h1>
		<h2>Test Case execution Summary</h2>      
		<p>
		<hr>
		***** suites executed=$SUITE_EXECUTECount skipped=$SUITE_SKIPCount errors=$SUITE_ERRORCount<br>
		***** cases  executed=$CASE_EXECUTECount skipped=$CASE_SKIPCount failures=$CASE_FAILURECount errors=$CASE_ERRORCount<br>
		***** used workdir: <a href="$TTRO_workDir">$TTRO_workDir</a><br>
		<hr>
		</p>      
		<hr>      
		<h3>The Suite Lists</h3>
		<ul>
		  <li><a href="suite.html">Global Dummy Suite</a></li>
		</ul>
	</body>
	</html>
	EOF
}

#
# Create the suite index file
# $1 the index file name
function createSuiteIndex {
	cat <<-EOF > "$1"
	<!DOCTYPE html>
	<html>  
	<head>    
		<title>Test Report Collection '$TTRO_collection'</title>
		<meta charset='utf-8'>
	</head>  
	<body>    
		<h1 style="text-align: center;">Test Suite '$TTRO_suiteNestingString'</h1>
		<p>
		Suite input dir   <a href="$TTRO_inputDirSuite">$TTRO_inputDirSuite</a><br>
		Suite working dir <a href="$TTRO_workDirSuite">$TTRO_workDirSuite</a><br>
		<h2>Test Case execution:</h2>
		<p>
		<ul>
	EOF
}

#
# Add Case entry to suite index
# $1 File name
# $2 Case name
# $3 Case variant
# $4 Case result
# $5 Case input dir
# $6 Case work dir
function addCaseEntry {
	case $4 in
		SUCCESS ) 
			echo "<li>$2:$3 workdir <a href=\"$6\">$6</a> $4</li>" >> "$1";;
		ERROR )
			echo "<li style=\"color: red\">$2:$3 workdir <a href=\"$6\">$6</a> $4</li>" >> "$1";;
		FAILURE )
			echo "<li style=\"color: yellow\">$2:$3 workdir <a href=\"$6\">$6</a> $4</li>" >> "$1";;
		SKIP )
			echo "<li style=\"color: blue\">$2:$3 workdir <a href=\"$6\">$6</a> $4</li>" >> "$1";;
		*) 
			printErrorAndExit "Wrong result string $4" $errRt
	esac
}

#
# Start suite index and end case list
# $1 File name
function startSuiteList {
	cat <<-EOF >> "$1"
		</ul>
		<h2>Test Suite execution:</h2>
		<p>
		<ul>
	EOF
}

#
# Add Suite entry to suite index
# $1 File name
# $2 Suite nesting string
# $3 Suite result
# $4 Suite input dir
# $5 Suite work dir
# $6 Cases executed
# $7 Cases skipped
# $8 Cases failed
# $9 Cases error
# $10 Suites executed
# $11 Suites skipped
# S12 Suites error
function addSuiteEntry {
	case $3 in
		0 )
			echo -n "<li><a href=\"$5/suite.html\">$2</a> result code: $3  work dir: <a href=\"$5\">$5</a>" >> "$1";;
		$errSkip )
			echo -n "<li style=\"color: blue\"><a href=\"$5/suite.html\">$2</a> result code: $3  work dir: <a href=\"$5\">$5</a>" >> "$1";;
		$errSigint )
			echo -n "<li style=\"color: yellow\"><a href=\"$5/suite.html\">$2</a> result code: $3  work dir: <a href=\"$5\">$5</a>" >> "$1";;
		* )
			echo -n "<li style=\"color: red\"><a href=\"$5/suite.html\">$2</a> result code: $3  work dir: <a href=\"$5\">$5</a>" >> "$1"
	esac
	echo "      <b>Cases</b> executed=$6 skipped=$7 failures=$8 errors=$9 <b>Suites</b> executed=${10} skipped=${11} errors=${12}</li>" >> "$1"
}

#
# end suite index html
# $1 file name
function endSuiteIndex {
	cat <<-EOF >> "$1"
		</ul>
		</body>
	</html>
	EOF
}

:
