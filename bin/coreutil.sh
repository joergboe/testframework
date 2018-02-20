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
	#local suiteIndex="$1"
	#local suiteVariant="$2"
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
	echo "**** START Suite: ${suite} variant='$2' in ${suitePath} *****************"
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
			printWarning "Set SIGINT Execution of suite ${suite} variant $2 ended with result=$result"
			interruptReceived=$((interruptReceived+1))
		else
			if [[ $nestingLevel -gt 0 ]]; then
				printError "Execution of suite ${suite} variant $2 ended with result=$result"
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
			if [[ -e ${inputFileName} ]]; then
				{ while read; do
					if [[ $REPLY != \#* ]]; then
						echo "$REPLY" >> "$outputFileName"
					fi
				done } < "${inputFileName}"
			else
				printError "No result list $inputFileName in suite $sworkdir"
			fi
		done
	fi

	# html
	if [[ $nestingLevel -gt 0 ]]; then
		addSuiteEntry "$indexfilename" "$suiteNestingString" "$result" "$suitePath" "${sworkdir}"
	fi
	
	echo "**** END Suite: ${suite} variant='$2' in ${suitePath} *******************"
	return 0
} #/exeSuite

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
		text
		<div style="color: maroon">
		warning
		</div>
		<div style="color: rgb(255,204,0)">
		warning 2
		</div>
		<div style="color: red">error</div>
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
		<h1 style="text-align: center;">Test Suite '$TTRO_suite'</h1>
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
function addSuiteEntry {
	case $3 in
		0 )
			echo "<li><a href=\"$5/suite.html\">$2</a> result code: $3  work dir: <a href=\"$5\">$5</a></li>" >> "$1";;
		$errSkip )
			echo "<li style=\"color: blue\"><a href=\"$5/suite.html\">$2</a> result code: $3  work dir: <a href=\"$5\">$5</a></li>" >> "$1";;
		$errSigint )
			echo "<li style=\"color: yellow\"><a href=\"$5/suite.html\">$2</a> result code: $3  work dir: <a href=\"$5\">$5</a></li>" >> "$1";;
		* )
			echo "<li style=\"color: red\"><a href=\"$5/suite.html\">$2</a> result code: $3  work dir: <a href=\"$5\">$5</a></li>" >> "$1"
	esac
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
