#####################################################
# Utilities for the core testframework script code
#####################################################

#
# isSkip
# returns true if the script is to skip
function isSkip {
	if [[ ( -n $TTPRN_skip ) && ( -z $TTPRN_skipIgnore ) ]]; then
		return 0
	else
		return 1
	fi
}
readonly -f isSkip

#
# function to execute the variants of suites
# $1 the suite index to execute
# $2 is the variant to execute
# $3 nesting level of suite (parent)
# $4 the chain of suite names delim / (parent)
# $5 the chain of suite string including variants delim :: : (parent value)
# $6 parent sworkdir
# $7 preambl error
# expect suiteVariants suiteErrors suiteSkip
function exeSuite {
	isDebug && printDebug "******* $FUNCNAME $* number args $#"
	local suite="${suitesName[$1]}"
	local suitePath="${suitesPath[$1]}"
	local nestingLevel=$(($3+1))
	local suiteNestingPath="$4"
	local suiteNestingString="$5"
	local preamblError="$7"
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
	if "${TTRO_scriptDir}/suite.sh" "$1" "$2" "${sworkdir}" "$nestingLevel" "$suiteNestingPath" "$suiteNestingString" "$preamblError" 2>&1 | tee -i "${sworkdir}/${TEST_LOG}"; then
		result=0;
	else
		result=$?
		if [[ $result -eq $errSigint ]]; then
			printWarning "Set SIGINT Execution of suite ${suite} variant '$2' ended with result=$result"
			interruptReceived=$((interruptReceived+1))
		elif [[ $result -eq $errSkip ]]; then
			printInfo "Suite skipped suite ${suite} variant '$2'"
			suiteSkip=$(( suiteSkip+1 ))
			{ if read -r; then :; fi; } < "${sworkdir}/REASON" #read one line from reason
			builtin echo "$suiteNestingString: $REPLY" >> "${6}/SUITE_SKIP"
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
				if [[ $result -ne $errSkip ]]; then
					printError "No result list $inputFileName in suite $sworkdir"
				fi
			fi
		done
	fi

	# html
	if [[ $nestingLevel -gt 0 ]]; then
		addSuiteEntry "$indexfilename" "$suiteNestingString" "$result" "$suitePath" "${sworkdir}"\
		$CASE_EXECUTE_Count $CASE_SKIP_Count $CASE_FAILURE_Count $CASE_ERROR_Count $SUITE_EXECUTE_Count $SUITE_SKIP_Count $SUITE_ERROR_Count
	fi
	
	printInfo "**** END Suite: ${suite} variant='$2' in ${suitePath} *******************"
	return 0
} #/exeSuite
readonly -f exeSuite

#
# Function fixPropsVars
#	This function fixes all ro-variables and propertie variables
#	Property and variables setting is a two step action:
#	Unset help variables if no reference is printed
#	make vars STEPS PREPS FINS read-only
#	returns:
#		success (0)
#		error	in exceptional cases
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
readonly -f fixPropsVars

#
# Read a test case or a test suite file and evaluate the preambl
# variantCount and variantList and conditional the type; ignore the rest
# $1 is the filename to read
# return 0 in success case
# return 1 if an invalid preambl was read;
# results are returned in global variables variantCount; variantList
function evalPreambl {
	isDebug && printDebug "$FUNCNAME $1"
	if [[ ! -r $1 ]]; then
		printErrorAndExit "${FUNCNAME} : Can not open file=$1 for read" ${errRt}
	fi
	variantCount=""; variantList=""
	declare -i lineno=1
	{
		local varname=
		local value=
		local result=0
		local x
		local preamblLine=''
		local len
		while [[ result -eq 0 ]]; do
			if ! read -r; then result=1; fi
			if [[ ( result -eq 0 ) || ( ${#REPLY} -gt 0 ) ]]; then #do not eval the last and empty line
				if [[ $REPLY =~ ^[[:space:]]*\#--[[:space:]]*(.*) ]]; then
					#echo true "'${BASH_REMATCH[0]}'" "'${BASH_REMATCH[1]}'"
					preamblLine="${preamblLine}${BASH_REMATCH[1]}"
					len=$((${#preamblLine}-1))
					if [[ ${preamblLine:$len} == '\' ]]; then
						preamblLine="${preamblLine:0:$len}"
					else
						if SplitPreamblAssign "$preamblLine"; then
							if [[ -n $varname ]] ; then
								isDebug && printDebug "$FUNCNAME prepare for variant encoding varname=$varname value=$value"
								case $varname in
									variantCount )
										if ! eval "variantCount=${value}"; then
											printError "${FUNCNAME} : Invalid value in file=$1 line=$lineno '$preamblLine'"
											return 1
										fi
										if ! isPureNumber "$variantCount"; then
											printError "${FUNCNAME} : variantCount is no digit in file=$1 line=$lineno '$preamblLine'"
											return 1
										fi
										isVerbose && printVerbose "variantCount='${variantCount}'"
									;;
									variantList )
										if ! eval "variantList=${value}"; then
											printError "${FUNCNAME} : Invalid value in file=$1 line=$lineno '$preamblLine'"
											return 1
										fi
										isVerbose && printVerbose "variantList='${variantList}'"
										for x in $variantList; do
											if ! [[ $x =~ ^[a-zA-Z0-9_-]*$ ]]; then
												printError "Invalid variant $x in list in file=$1 line=$lineno '$preamblLine'"
												return 1
											fi
										done
									;;
									timeout )
										if ! eval "timeout=${value}"; then
											printError "${FUNCNAME} : Invalid value in file=$1 line=$lineno '$preamblLine'"
											return 1
										fi
										if ! isPureNumber "$timeout"; then
											printError "${FUNCNAME} : timeout is no digit in file=$1 line=$lineno 'preamblLine'"
											return 1
										fi
										isVerbose && printVerbose "timeout='${timeout}'"
									;;
									* )
										#other property or variable
										printError "${FUNCNAME} : Invalid preambl varname='$varname' in file $1 line=$lineno '$preamblLine'"
										return 1
									;;
								esac
							else
								printError "${FUNCNAME} : Invalid preampl line case or suitefile file=$1 line=$lineno '$preamblLine'"
								return 1
							fi
						else
							return 1
						fi
						preamblLine=''
					fi
				else
					if [[ -n $preamblLine ]]; then
						printError "Invalid line after preambl continuation file=$1 line=$lineno '$preamblLine'"
						return 1
					fi
				fi
				#isDebug && printDebug "Ignore line file=$1 line=$lineno '$REPLY'"
				lineno=$((lineno+1))
			fi
		done
	} < "$1"
	return 0
}
readonly -f evalPreambl

#
# SplitPreamblAssign
# Split the variable name and value part of an assignement in a preambl line
# The assignemtnet must something matching [[:word:]]=
# Ingnore all other lines
#	$1 the input line (only one line without nl)
#	return variables:
#		varname
#		value
#	returns
#		success(0) if the line was sucessfully split
#					the varname is empty if there is no valid assignement in the preambl line
#		error(1)   if there was no prambl line'
function SplitPreamblAssign {
	[[ $# -eq 1 ]] || printErrorAndExit "Wrong number of arguments $# in $FUNCNAME" $errRt
	isDebug && printDebug "$FUNCNAME \$1='$1'"
	if [[ $1 =~ ^([a-zA-Z0-9_]+)=(.*) ]]; then
		varname="${BASH_REMATCH[1]}"
		value="${BASH_REMATCH[2]}"
		isDebug && printDebug "$FUNCNAME varname='$varname' value='$value'"
		return 0
	else
		varname=""
		value=""
		printError "no valid preambl line here '$1'"
		return 1
	fi
}
readonly -f SplitPreamblAssign

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
readonly -f writeProtectExportedFunctions

#
# Check if test run category matches any of the atrifact categories
# TTTT_categoryArray           - the array of artifact cats
# TTTT_runCategoryPatternArray - the array of category pattern of this test run
# return true if one run category pattern matches any of the artifact cats
#        or if catecory or eval TTTT_runCategoryPatternArray is empty
#        false otherwise
function checkCats {
	if isNotExisting 'TTTT_categoryArray'; then
		printErrorAndExit "variable TTTT_categoryArray must exist" $errRt
	fi
	if ! isArray 'TTTT_categoryArray'; then
		printErrorAndExit "variable TTTT_categoryArray must be an indexed array" $errRt
	fi
	if isDebug; then
		local dispstring=$(declare -p 'TTTT_categoryArray')
		local dispstring2=$(declare -p 'TTTT_runCategoryPatternArray')
		printDebug "$dispstring $dispstring2"
	fi
	local lenCat="${#TTTT_categoryArray[*]}"
	local lenRunPat="${#TTTT_runCategoryPatternArray[*]}"
	if [[ ( $lenCat -eq 0 ) || ( $lenRunPat -eq 0 ) ]]; then
		isVerbose && printVerbose "No artifact category set or nor run category pattern set: return true"
		return 0
	fi
	local i=0
	local j=0
	while (( i < lenCat )); do
		j=0
		while (( j < lenRunPat )); do
			isDebug && printDebug "i=$i j=$j cats: ${TTTT_categoryArray[$i]} == ${TTTT_runCategoryPatternArray[$j]}"
			if [[ ${TTTT_categoryArray[$i]} == ${TTTT_runCategoryPatternArray[$j]} ]]; then
				printInfo "Run category pattern set match found: ${TTTT_categoryArray[$i]} == ${TTTT_runCategoryPatternArray[$j]}"
				return 0
			fi
			j=$((j+1))
		done
		i=$((i+1))
	done
	printInfo "No run category pattern match found: $FUNCNAME returns false"
	return 1
}
readonly -f checkCats

#
# Create the global index.html
# $1 the file to create
# $2 elapsed time
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
		***** categories of this run: ${cats}<br>
		***** used workdir: <a href="$TTRO_workDir">$TTRO_workDir</a><br>
		<hr>
		</p>      
		<hr>      
		<h3>The Suite Lists</h3>
		<ul>
		  <li><a href="suite.html">Global Dummy Suite</a></li>
		</ul>
		Elapsed time : $2
	</body>
	</html>
	EOF
}
readonly -f createGlobalIndex

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
readonly -f createSuiteIndex

#
# Add Case entry to suite index
# $1 File name
# $2 Case name
# $3 Case variant
# $4 Case result
# $5 Case input dir
# $6 Case work dir
function addCaseEntry {
	local reason=''
	if [[ -e "$6/REASON" ]]; then
		reason=$(<"$6/REASON")
	fi
	case $4 in
		SUCCESS ) 
			echo "<li>$2:$3 $4 <br>workdir <a href=\"$6\">$6</a></li>" >> "$1";;
		ERROR )
			echo "<li style=\"color: red\">$2:$3 $4 <br>workdir <a href=\"$6\">$6</a></li>" >> "$1";;
		FAILURE )
			echo "<li style=\"color: red\">$2:$3 $4 : $reason <br>workdir <a href=\"$6\">$6</a></li>" >> "$1";;
		SKIP )
			echo "<li style=\"color: blue\">$2:$3  $4 : $reason <br>workdir <a href=\"$6\">$6</a></li>" >> "$1";;
		*) 
			printErrorAndExit "Wrong result string $4" $errRt
	esac
}
readonly -f addCaseEntry

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
readonly -f startSuiteList

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
	if [[ $# -ne 12 ]]; then printErrorAndExit "wrong no of arguments $#" $errRt; fi
	case $3 in
		0 )
		if [[ ( $8 -gt 0 ) || ( $9 -gt 0 ) || ( $12 -gt 0 ) ]]; then
			echo -n "<li style=\"color: red\"><a href=\"$5/suite.html\">$2</a> result code: $3" >> "$1"
		else
			echo -n "<li><a href=\"$5/suite.html\">$2</a> result code: $3" >> "$1"
		fi;;
		$errSkip )
			{ if read -r; then :; fi; } < "$5/REASON" #read one line from reason
			echo -n "<li style=\"color: blue\"><a href=\"$5/suite.html\">$2</a> result code: $3 : $REPLY work dir: <a href=\"$5\">$5</a>" >> "$1";;
		$errSigint )
			echo -n "<li style=\"color: red\"><a href=\"$5/suite.html\">$2</a> result code: $3  work dir: <a href=\"$5\">$5</a>" >> "$1";;
		* )
			echo -n "<li style=\"color: red\"><a href=\"$5/suite.html\">$2</a> result code: $3  work dir: <a href=\"$5\">$5</a>" >> "$1"
	esac
	if [[ $3 != $errSkip ]]; then
		echo "      <br><b>Cases</b> executed=$6 skipped=$7 failures=$8 errors=$9 <b>Suites</b> executed=${10} skipped=${11} errors=${12}</li>" >> "$1"
	else
		echo "      <br> ... </li>" >> "$1"
	fi
}
readonly -f addSuiteEntry

#
# end suite index html
# $1 file name
# $2 elapsed time string
function endSuiteIndex {
	cat <<-EOF >> "$1"
		</ul>
		Elapsed time : $2
		</body>
	</html>
	EOF
}
readonly -f endSuiteIndex
:
