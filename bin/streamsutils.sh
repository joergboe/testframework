#########################################
# Streams utilities for testframework

####################################################
# Initialization section

# Module initialization
#	check streams environment exits if no streams environment found
#	set required properties and variables
#	Function call is not required since all initialization is done in main body'
isDebug && printDebug "streamsutilsInitialization"
#environment check
if ! declare -p STREAMS_INSTALL > /dev/null; then
	printErrorAndExit "Missing environment: STREAMS_INSTALL must be set" ${errEnv}
fi
#set props
setVar 'TTPR_splcFlags' '-a'
setVar 'TTPRN_splc' "${STREAMS_INSTALL}/bin/sc"
setVar 'TTPRN_st' "${STREAMS_INSTALL}/bin/streamtool"
setVar 'TTPRN_md' "${STREAMS_INSTALL}/bin/spl-make-doc"
setVar 'TTPRN_mt' "${STREAMS_INSTALL}/bin/spl-make-toolkit"
setVar 'TTPRN_swsPort' '8443'
setVar 'TTPRN_jmxPort' '9443'
setVar TTPR_numresources 1
setVar TTPR_checkpointRepository "$HOME/Checkpoint"
setVar TTPR_fileStoragePath "$HOME/tmp"
setVar 'TTPR_waitForJobHealth' 60

if declare -p STREAMS_ZKCONNECT &> /dev/null && [[ -n $STREAMS_ZKCONNECT ]]; then
	setVar TTPR_streamsZkConnect "$STREAMS_ZKCONNECT"
else
	setVar TTPR_streamsZkConnect ""
fi
echo "streamsutilsInitialization: TTPR_streamsZkConnect=$TTPR_streamsZkConnect"
if declare -p STREAMS_DOMAIN_ID &> /dev/null && [[ -n $STREAMS_DOMAIN_ID ]]; then
	setVar TTPRN_streamsDomainId "$STREAMS_DOMAIN_ID"
	echo "streamsutilsInitialization: TTPRN_streamsDomainId=$TTPRN_streamsDomainId"
fi
if declare -p STREAMS_INSTANCE_ID &> /dev/null && [[ -n $STREAMS_INSTANCE_ID ]]; then
	setVar TTPRN_streamsInstanceId "$STREAMS_INSTANCE_ID"
	echo "streamsutilsInitialization: TTPRN_streamsInstanceId=$TTPRN_streamsInstanceId"
fi
# test var to check duplicate init
#setVar 'TTRO_ttt' '55'
# variables required for functions
setVar 'TTRO_testframeToolkitDir' "$TTRO_scriptDir/../streamsx.testframe"
TT_mainComposite='Main'
TT_sabFile='./output/Main.sab' 
TT_jobFile='./jobno.log'
TT_traceLevel='trace'
TT_dataDir='data'
TT_waitForFileName="$TT_dataDir/FinalMarker"
TT_waitForFileInterval=3

#make toolkit
printInfo "Make toolkit in $TTRO_testframeToolkitDir"
"$TTPRN_mt" '-i' "$TTRO_testframeToolkitDir"
#make file storages
mkdir -p "$TTPR_checkpointRepository"
mkdir -p "$TTPR_fileStoragePath"

#########################################################
# Functions section

TTRO_help_copyAndTransformSpl='
# Function copyAndTransformSpl
#	deprecated use copyAndMorphSpl
#	Copy all files from input directory to workdir and
#	Transform spl files
#	the variant identifier is $TTRO_variantCase'
function copyAndTransformSpl {
	printWarning "$FUNCNAME is deprecated use function 'copyAndMorphSpl'"
	copyAndTransform "$TTRO_inputDirCase" "$TTRO_workDirCase" "$TTRO_variantCase" '*.spl'
}
export -f copyAndTransformSpl

TTRO_help_copyAndTransformSpl2='
# Function copyAndTransformSpl2
#	deprecated use copyAndMorphSpl2
#	Copy all files from input directory to workdir and
#	Transform spl files
#	the variant identifier is $1'
function copyAndTransformSpl2 {
	printWarning "$FUNCNAME is deprecated use function 'copyAndMorphSpl2'"
	if [[ $# -ne 1 ]]; then printErrorAndExit "${FUNCNAME[0]} called with no or empty command" $errRt; fi
	copyAndTransform "$TTRO_inputDirCase" "$TTRO_workDirCase" "$1" '*.spl'
}
export -f copyAndTransformSpl2

TTRO_help_copyAndMorphSpl='
# Function copyAndMorphSpl
#	Copy all files from input directory to workdir and
#	Transform spl files
#	the variant identifier is $TTRO_variantCase'
function copyAndMorphSpl {
	copyAndMorph "$TTRO_inputDirCase" "$TTRO_workDirCase" "$TTRO_variantCase" '*.spl'
}
export -f copyAndMorphSpl

TTRO_help_copyAndMorphSpl2='
# Function copyAndMorphSpl2
#	Copy all files from input directory to workdir and
#	Transform spl files
#	the variant identifier is $1'
function copyAndMorphSpl2 {
	if [[ $# -ne 1 ]]; then printErrorAndExit "${FUNCNAME[0]} called with wrong number of params" $errRt; fi
	copyAndMorph "$TTRO_inputDirCase" "$TTRO_workDirCase" "$1" '*.spl'
}
export -f copyAndMorphSpl2

TTRO_help_splCompile='
# Function splCompile
#	Compile spl application expect successful result
#	No treatment in case of compiler error
# Parameters:
#	TTPR_splcFlags   - compiler flags
#	TT_mainComposite - the bname of the main composite
#	TT_toolkitPath   - the toolkit path (the testframe toolkit is automatically appended
#	TTRO_treads      - the number os used cpu threads
#	$1 --            - further compiler arguments (compile time arguments)'
function splCompile {
	local tkdir=
	if isExistingAndTrue 'TT_toolkitPath'; then
		tkdir="$TT_toolkitPath:$TTRO_testframeToolkitDir"
	else
		tkdir="$TTRO_testframeToolkitDir"
	fi
	if [[ -z $TT_dataDir ]]; then
		echoAndExecute ${TTPRN_splc} "$TTPR_splcFlags" -M $TT_mainComposite -t "$tkdir" -j $TTRO_treads "$@"
	else
		echoAndExecute ${TTPRN_splc} "$TTPR_splcFlags" -M $TT_mainComposite -t "$tkdir" --data-directory "$TT_dataDir" -j $TTRO_treads "$@"
	fi
}
export -f splCompile

TTRO_help_splCompileAndLog='
# Function splCompileAndLog
#	Compile spl application expect successful result
#	compiler colsole & error output is stored into file
#	No treatment in case of compiler error
# Parameters: see splCompile'
function splCompileAndLog {
	splCompile "$@" 2>&1 | tee "$TT_evaluationFile"
}
export -f splCompileAndLog

TTRO_help_splCompileAndIntercept='
# Function splCompileAndIntercept
#	Compile spl application and intercept compile errors
#	compiler console & error output is stored into file TT_evaluationFile
#	compiler result code is sored in TTTT_result
# Parameters: see splCompile'
function splCompileAndIntercept {
	if splCompile "$@" 2>&1 | tee "$TT_evaluationFile"; then
		TTTT_result=0
	else
		TTTT_result=$?
	fi
	return 0
}
export -f splCompileAndIntercept

TTRO_help_splCompileInterceptAndSuccess='
# Function splCompileInterceptAndSuccess
#	Compile spl application and intercept compile errors
#	Expect success. Otherwise failure condition is set
#	compiler console & error output is stored into file TT_evaluationFile
#	compiler result code is sored in TTTT_result
# Parameters: see splCompile'
function splCompileInterceptAndSuccess {
	if splCompile "$@" 2>&1 | tee "$TT_evaluationFile"; then
		TTTT_result=0
	else
		TTTT_result=$?
	fi
	if [[ $TTTT_result -ne 0 ]]; then
		setFailure "$TTTT_result : is not expected"
	fi
	return 0
}
export -f splCompileInterceptAndSuccess

TTRO_help_splCompileInterceptAndError='
# Function splCompileInterceptAndError
#	Compile spl application and intercept compile errors
#	Expect error. Otherwise failure condition is set
#	compiler console & error output is stored into file TT_evaluationFile
#	compiler result code is sored in TTTT_result
# Parameters: see splCompile'
function splCompileInterceptAndError {
	if splCompile "$@" 2>&1 | tee "$TT_evaluationFile"; then
		TTTT_result=0
	else
		TTTT_result=$?
	fi
	if [[ $TTTT_result -eq 0 ]]; then
		setFailure "$TTTT_result : is not expected"
	fi
	return 0
}
export -f splCompileInterceptAndError

TTRO_help_mkDomain='
# Function mkDomain
#	Make domain from global properties
#	If variable  TTPR_noStart or TTTT_noStreamsStart is true, do nothing'
function mkDomain {
	mkDomainVariable "$TTPR_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_swsPort" "$TTPRN_jmxPort" "$TTPR_checkpointRepository" "$TTPR_fileStoragePath"

}
export -f mkDomain 

TTRO_help_mkDomainVariable='
# Function mkDomainVariable
#	Make domain with variable parameters
#	If variable  TTPR_noStart or TTTT_noStreamsStart is true, do nothing
#	$1 zk connect string or "" for embeddedzk
#	$2 domainname
#	$3 sws port
#	$4 jmx port
#	$5 checkpointRepository path
#	$6 fileStoragePath'
function mkDomainVariable {
	isDebug && printDebug "$FUNCNAME $*"
	if isExistingAndTrue 'TTPR_noStart' || isExistingAndTrue 'TTTT_noStreamsStart'; then
		printInfo "$FUNCNAME : function supressed"
		return 0
	fi
	local commandResult
	if [[ -z $1 ]]; then
		if echoAndExecute $TTPRN_st mkdomain --embeddedzk --domain-id "$2" --property "SWS.Port=$3" --property "JMX.Port=$4" --property domain.highAvailabilityCount=1 --property "domain.checkpointRepositoryConfiguration= { \"Dir\" : \"$5\" } " --property "domain.fileStoragePath=$6"; then
			commandResult=$?
		else
			commandResult=$?
		fi
	else
		if echoAndExecute $TTPRN_st mkdomain --zkconnect "$1" --domain-id "$2" --property "SWS.Port=$3" --property "JMX.Port=$4" --property domain.highAvailabilityCount=1 --property "domain.checkpointRepositoryConfiguration= { \"Dir\" : \"$5\" } " --property "domain.fileStoragePath=$6"; then
			commandResult=$?
		else
			commandResult=$?
		fi
	fi
	if [[ $commandResult -ne 0 ]]; then
		printError "$FUNCNAME : Can not make domain $2"
		#return 1
		return $errTestFail
	fi
	if ! echoAndExecute $TTPRN_st genkey; then
		printError "$FUNCNAME : Can not genrate key $2"
		return $errTestFail
	fi
}
export -f mkDomainVariable

TTRO_help_startDomain='
# Function startDomain
#	Start domain from global properties
#	If variable  TTPR_noStart or TTTT_noStreamsStart is true, do nothing'
function startDomain {
	startDomainVariable "$TTPRN_streamsDomainId"
}
export -f startDomain 

TTRO_help_startDomainVariable='
# Function startDomainVariable
#	Make domain with variable parameters
#	If variable  TTPR_noStart or TTTT_noStreamsStart is true, do nothing
#	$1 domainname'
function startDomainVariable {
	isDebug && printDebug "$FUNCNAME $*"
	if isExistingAndTrue 'TTPR_noStart' || isExistingAndTrue 'TTTT_noStreamsStart'; then
		printInfo "$FUNCNAME : function supressed"
		return 0
	fi
	if ! echoAndExecute $TTPRN_st startdomain --domain-id "$1"; then
		printError "$FUNCNAME : Can not start domain $1"
		return $errTestFail
	fi
}
export -f startDomainVariable

TTRO_help_mkInst='
# Function mkInst
#	Make instance from global properties
#	If variable  TTPR_noStart or TTTT_noStreamsStart is true, do nothing'
function mkInst {
	mkInstVariable "$TTPRN_streamsInstanceId" "$TTPR_numresources"
}
export -f mkInst

TTRO_help_mkInstVariable='
# Function mkInstVariable
#	Make instance with variable parameters
#	If variable  TTPR_noStart or TTTT_noStreamsStart is true, do nothing
#	$1 instance name
#	$2 numresources'
function mkInstVariable {
	isDebug && printDebug "$FUNCNAME $*"
	if isExistingAndTrue 'TTPR_noStart' || isExistingAndTrue 'TTTT_noStreamsStart'; then
		printInfo "$FUNCNAME : function supressed"
		return 0
	fi
	if ! echoAndExecute $TTPRN_st mkinst --instance-id "$1" --numresources "$2"; then
		printError "$FUNCNAME : Can not make instance $1"
		return $errTestFail
	fi
}
export -f mkInstVariable

TTRO_help_startInst='
# Function startInst
#	Start instance from global properties
#	If variable  TTPR_noStart or TTTT_noStreamsStart is true, do nothing'
function startInst {
	startInstVariable "$TTPRN_streamsInstanceId"
}
export -f startInst

TTRO_help_startInstVariable='
# Function startInstVariable
#	Start instance with variable parameters
#	If variable  TTPR_noStart or TTTT_noStreamsStart is true, do nothing
#	$1 domainname'
function startInstVariable {
	isDebug && printDebug "$FUNCNAME $*"
	if isExistingAndTrue 'TTPR_noStart' || isExistingAndTrue 'TTTT_noStreamsStart'; then
		printInfo "$FUNCNAME : function supressed"
		return 0
	fi
	if ! echoAndExecute $TTPRN_st startinst --instance-id "$1"; then
		printError "$FUNCNAME : Can not start instance $1"
		return $errTestFail
	fi
}
export -f startInstVariable

TTRO_help_cleanUpInstAndDomainVariableOld='
# Function cleanUpInstAndDomainVariableOld deprecated, use cleanUpInstAndDomain
#	stop and clean instance and domain from variable params
#	$1 start or stop determines the if TTPR_noStart or TTPR_noStop is evaluated
#	$2 zk string
#	$3 domain id
#	$4 instance id'
function cleanUpInstAndDomainVariableOld {
	printWarning "$FUNCNAME is deprecated use cleanUpInstAndDomain instead"
	isDebug && printDebug "$FUNCNAME $*"
	if [[ $1 == start ]]; then
		if isExistingAndTrue 'TTPR_noStart'; then
			printInfo "$FUNCNAME : at start function supressed"
			return 0
		fi
	elif [[ $1 == stop ]]; then
		if isExistingAndTrue 'TTPR_noStop'; then
			printInfo "$FUNCNAME : at stop function supressed"
			return 0
		fi
	else
		printErrorAndExit "wrong parameter 1 $1" $errRt
	fi

	echo "streamtool lsdomain $3"
	local response
	if response=$(echoAndExecute $TTPRN_st lsdomain "$3"); then # domain exists
		if [[ $response =~ $3\ Started ]]; then # domain is running
			#Running domain found check instance
			if echoAndExecute $TTPRN_st lsinst --domain-id "$3" "$4"; then
				if echoAndExecute $TTPRN_st lsinst --started --domain-id "$3" "$4"; then
					#TODO: check whether the retun code is fine here
					echoAndExecute $TTPRN_st stopinst --force --domain-id "$3" --instance-id "$4"
				else
					isVerbose && printVerbose "$FUNCNAME : no running instance $4 found in domain $3"
				fi
				echoAndExecute $TTPRN_st rminst --noprompt --domain-id "$3" --instance-id "$4"
			else
				isVerbose && printVerbose "$FUNCNAME : no instance $4 found in domain $3"
			fi
			#End Running domain found check instance
			echoAndExecute $TTPRN_st stopdomain --force --domain-id "$3"
		else
			isVerbose && printVerbose "$FUNCNAME : no running domain $3 found"
		fi
		echoAndExecute $TTPRN_st rmdomain --noprompt --domain-id "$3"
	else
		isVerbose && printVerbose "$FUNCNAME : no domain $3 found"
	fi
	return 0
}
export -f cleanUpInstAndDomainVariableOld

TTRO_help_cleanUpInstAndDomainAtStart='
# Function cleanUpInstAndDomainAtStart
#	stop and clean instance and domain at script start
#	Function is not executed if TTPR_noStart is true
#	If variable TTPR_clean is true
#	    a clean up is forced, the instance and domain is stopped and removed
#	If variable TTPR_clean is not true
#	    no clean up is done if the instace is running
#	    otherwise instance and domain is cleaned up'
function cleanUpInstAndDomainAtStart {
	cleanUpInstAndDomainAtStartVariable "$TTPR_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId"
}
export -f cleanUpInstAndDomainAtStart

TTRO_help_cleanUpInstAndDomainAtStartVariable='
# Function cleanUpInstAndDomainAtStartVariable
#	like cleanUpInstAndDomainAtStart but with parameters
#	$1 zk string
#	$2 domain id
#	$3 instance id
#	return_code: success'
function cleanUpInstAndDomainAtStartVariable {
	[[ $# -ne 3 ]] && printErrorAndExit "Wrong number of arguments in $FUNCNAME # $#" $errRt
	if isExistingAndTrue 'TTPR_noStart'; then
		printInfo "$FUNCNAME : function supressed"
		return 0
	fi
	local runCleanup=''
	if isExistingAndTrue 'TTPR_clean'; then
		runCleanup='true'
	else
		if response=$(export LC_ALL='en_US.UTF-8'; $TTPRN_st lsinst --started --domain-id "$2" "$3"); then
			if [[ $response =~ $3 ]]; then
				printInfo "$FUNCNAME : Instance $3 of domain $2 is running -> start over"
				TTTT_noStreamsStart='true'
			else
				runCleanup='true'
			fi
		else
			runCleanup='true'
		fi
	fi 
	if [[ -n $runCleanup ]]; then
		cleanUpInstAndDomainVariable "$1" "$2" "$3"
	fi
	return 0
}
export -f cleanUpInstAndDomainAtStartVariable

TTRO_help_cleanUpInstAndDomainAtStop='
# Function cleanUpInstAndDomainAtStop
#	stop and clean instance and domain at script stop
#	Function is not executed if TTPR_noStop is true
#	If variable TTPR_clean is true
#	    a clean up is forced, the instance and domain is stopped and removed
#	otherwise
#	    no clean up is done'
function cleanUpInstAndDomainAtStop {
	cleanUpInstAndDomainAtStopVariable "$TTPR_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId"
	return 0
}
export -f cleanUpInstAndDomainAtStop

TTRO_help_cleanUpInstAndDomainAtStopVariable='
# Function cleanUpInstAndDomainAtStopVariable
#	like cleanUpInstAndDomainAtStop but with parameters
#	$1 zk string
#	$2 domain id
#	$3 instance id
#	return_code: success'
function cleanUpInstAndDomainAtStopVariable {
	[[ $# -ne 3 ]] && printErrorAndExit "Wrong number of arguments in $FUNCNAME # $#" $errRt
	if isExistingAndTrue 'TTPR_noStop'; then
		printInfo "$FUNCNAME : function supressed"
		return 0
	fi
	if isExistingAndTrue 'TTPR_clean'; then 
		cleanUpInstAndDomainVariable "$1" "$2" "$3"
	fi
	return 0
}
export -f cleanUpInstAndDomainAtStopVariable

TTRO_help_cleanUpInstAndDomain='
# Function cleanUpInstAndDomain
#	stop instance and domain if running and clean instance and domain'
function cleanUpInstAndDomain {
	cleanUpInstAndDomainVariable "$TTPR_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId"
}
export -f cleanUpInstAndDomain

TTRO_help_cleanUpInstAndDomainVariable='
# Function cleanUpInstAndDomainVariable
#	stop and clean instance and domain from variable params
#	$1 zk string
#	$2 domain id
#	$3 instance id
#	return_code: success'
function cleanUpInstAndDomainVariable {
	isDebug && printDebug "$FUNCNAME $*"
	[[ $# -ne 3 ]] && printErrorAndExit "Wrong number of arguments in $FUNCNAME # $#" $errRt
	local response
	if response=$(export LC_ALL='en_US.UTF-8'; $TTPRN_st lsdomain "$2"); then # domain exists
		printInfo "$FUNCNAME : Domain $2 exists"
		if [[ $response =~ $2\ Started ]]; then # domain is running
			printInfo "$FUNCNAME : Domain $2 is running"
			if $TTPRN_st lsinst --domain-id "$2" "$3"; then
				printInfo "$FUNCNAME : Instance $3 exists"
				if response=$(export LC_ALL='en_US.UTF-8'; $TTPRN_st lsinst --started --domain-id "$2" "$3"); then
					printInfo "$FUNCNAME : Instance $3 exists"
					if [[ $response =~ $3 ]]; then
						printInfo "$FUNCNAME : Instance $3 is running -> stop it"
						echoAndExecute $TTPRN_st stopinst --force --domain-id "$2" --instance-id "$3"
					else
						printInfo "$FUNCNAME : no running instance $3 found in domain $2"
					fi
				else
					printInfo "$FUNCNAME : no running instance $3 found in domain $2"
				fi
				echoAndExecute $TTPRN_st rminst --noprompt --domain-id "$2" --instance-id "$3"
			else
				printInfo "$FUNCNAME : no instance $3 found in domain $2"
			fi
			echoAndExecute $TTPRN_st stopdomain --force --domain-id "$2"
		else
			printInfo "$FUNCNAME : no running domain $2 found"
		fi
		echoAndExecute $TTPRN_st rmdomain --noprompt --domain-id "$2"
	else
		printInfo "$FUNCNAME : no domain $2 found"
	fi
	return 0
}
export -f cleanUpInstAndDomainVariable

TTRO_help_submitJobOld='
# Function submitJobOld
#	$1 sab files
#	$2 output file name
#	return_code: the returncode of the called function'
function submitJobOld {
	printWarning "$FUNCNAME is deprecated use submitJob"
	submitJobVariable "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$1" "$2"
}
export -f submitJobOld

TTRO_help_submitJob='
# Function submitJob
#	create data directory if data directory variable is non empty
#	and submit the job
#	submits a job and provides the jobnumber file
# Parameters:
#	$1 ...$n - optionally more config and submission time parameters
#	$TTPRN_streamsDomainId   - domain id
#	$TTPRN_streamsInstanceId - instance id
#	$TT_sabFile              - sab file
#	$TT_jobFile              - output jobnumber file name
#	$TT_traceLevel           - trace level
#	TT_dataDir - the data directory variable
# Returns:
#	the return code of the executed command
# Exits:
#	if the job was started and the jobnumber file does not exists
# Side Effects:
#	TTTT_jobno - jobnumber if job was started or empty'
function submitJob {
	submitJobVariable "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$TT_sabFile" "$TT_jobFile" "$TT_traceLevel" "$@"
}
export -f submitJob

TTRO_help_submitJobAndIntercept='
# Function submitJobAndIntercept
#	create data directory if data directory variable is non empty
#	and submit the job and write the result code into TTTT_result
#	submits a job and provides the jobnumber file
# Parameters:
#	$1 ...$n - optionally more config and submission time parameters
#	$TTPRN_streamsDomainId   - domain id
#	$TTPRN_streamsInstanceId - instance id
#	$TT_sabFile              - sab file
#	$TT_jobFile              - output jobnumber file name
#	$TT_traceLevel           - trace level
#	TT_dataDir - the data directory variable
# Returns:
#	success
# Exits:
#	if the job was started and the jobnumber file does not exists
# Side Effects:
#	TTTT_result - the result code of the executed command
#	TTTT_jobno - jobnumber if job was started or empty'
function submitJobAndIntercept {
	if submitJobVariable "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$TT_sabFile" "$TT_jobFile" "$TT_traceLevel" "$@"; then
		TTTT_result=0
	else
		TTTT_result=$?
	fi
	return 0
}
export -f submitJobAndIntercept

TTRO_help_submitJobInterceptAndSuccess='
# Function submitJobInterceptAndSuccess
#	create data directory if data directory variable is non empty
#	and submit the job and expect a successful submission
#	submits a job and provides the jobnumber file
# Parameters:
#	$1 ...$n - optionally more config and submission time parameters
#	$TTPRN_streamsDomainId   - domain id
#	$TTPRN_streamsInstanceId - instance id
#	$TT_sabFile              - sab file
#	$TT_jobFile              - output jobnumber file name
#	$TT_traceLevel           - trace level
#	TT_dataDir - the data directory variable
# Returns:
#	success
# Exits:
#	if the job was started and the jobnumber file does not exists
# Side Effects:
#	TTTT_result - the result code of the executed command
#	TTTT_jobno - jobnumber if job was started or empty
#	the failure condition is set if the job submission fails'
function submitJobInterceptAndSuccess {
	if submitJobVariable "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$TT_sabFile" "$TT_jobFile" "$TT_traceLevel" "$@"; then
		TTTT_result=0
	else
		TTTT_result=$?
		setFailure "Job submission failed: $TT_sabFile"
	fi
	return 0
}
export -f submitJobInterceptAndSuccess

TTRO_help_submitJobLogAndIntercept='
# Function submitJobLogAndIntercept
#	create data directory if data directory variable is non empty
#	and submit the job and and write the result code into TTTT_result
#	submits a job and provides the jobnumber file and the console output of the command in evaluation file
# Parameters:
#	$1 ...$n - optionally more config and submission time parameters
#	$TTPRN_streamsDomainId   - domain id
#	$TTPRN_streamsInstanceId - instance id
#	$TT_sabFile              - sab file
#	$TT_jobFile              - output jobnumber file name
#	$TT_traceLevel           - trace level
#	TT_dataDir - the data directory variable
#	$TT_evaluationFile - the file name of the evaluation file
# Returns:
#	success
# Exits:
#	if the job was started and the jobnumber file does not exists
# Side Effects:
#	TTTT_result - the result code of the executed command
#	TTTT_jobno - jobnumber if job was started or empty'
function submitJobLogAndIntercept {
	TTTT_result=0
	TTTT_jobno=''
	if submitJobVariable "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$TT_sabFile" "$TT_jobFile" "$TT_traceLevel" "$@" 2>&1 | tee "$TT_evaluationFile"; then
		if [[ -e $TT_jobFile ]]; then
			TTTT_jobno=$(<"$TT_jobFile")
			return 0
		else
			printErrorAndExit "Job was started but not joblog was found: $TT_jobFile" $errRt
		fi
	else
		TTTT_result=$?
	fi
	return 0
}
export -f submitJobLogAndIntercept

TTRO_help_submitJobVariable='
# Function submitJobVariable
#	create data directory if data directory variable is non empty
#	and submit the job
# Parameters:
#	$1     - domain id
#	$2     - instance id
#	$3     - sab file
#	$4     - output jobnumber file name
#	$5     - trace level
#	$6 ... - optionally more command line parameters (submission time and config params)
#	TT_dataDir - the data directory variable
# Returns:
#	the return code of the executed command
# Exits:
#	if the command is called with wrong parameters
#	if the job was started and the jobnumber file does not exists
# Side Effects:
#	TTTT_jobno - jobnumber if job was started or empty'
function submitJobVariable {
	isDebug && printDebug "$FUNCNAME $*"
	[[ $# -lt 5 ]] && printErrorAndExit "$FUNCNAME called with wrong number of params: $#" $errRt
	TTTT_jobno=''
	if [[ -n $TT_dataDir ]]; then
		mkdir -p "$TT_dataDir"
	fi
	local d_id="$1"; local i_id="$2"; local sab_f="$3"; local out_f="$4"; local tr_l="$5"
	shift; shift; shift; shift; shift;
	local rcode=0
	if echoAndExecute $TTPRN_st submitjob --domain-id "$d_id" --instance-id "$i_id" --outfile "$out_f" -C tracing="$tr_l" "$sab_f" "$@"; then
		if [[ -e $out_f ]]; then
			TTTT_jobno=$(<"$out_f")
			return 0
		else
			printErrorAndExit "Job was started but not joblog was found: $out_f" $errRt
		fi
	else
		TTTT_jobno=''
		rcode=$?
		return $rcode
	fi
}
export -f submitJobVariable

TTRO_help_cancelJobOld='
# Function cancelJobOld
#	$1 jobno'
function cancelJobOld {
	cancelJobVariable "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$1"
}
export -f cancelJobOld

TTRO_help_cancelJob='
# Function cancelJob
#	if TTTT_jobno is not empty, cancel the job
#	emits a warning if TTTT_jobno is empty and the execution pase is not finalization
# Parameters:
#	$TTTT_jobno - the job number
#	$TTPRN_streamsDomainId - domain id
#	$TTPRN_streamsInstanceId - instance id
# Returns:
#	success
# Exits:
#	if the cancel command fails, e. g. when the command is called with a wrong job number
# Side Effect:
#	TTTT_jobno is empty'
function cancelJob {
	if isExistingAndTrue 'TTTT_jobno'; then
		cancelJobVariable "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$TTTT_jobno"
		TTTT_jobno=''
	else
		isDebug && printDebug "\$TTTT_executionState=$TTTT_executionState"
		if [[ $TTTT_executionState != 'finalization' ]]; then
			printWarning "Variable TTTT_jobno is empty. No job to stop"
		fi
	fi
}
export -f cancelJob

TTRO_help_cancelJobAndLog='
# Function cancelJobAndLog
#	cancel job and provide log files in current directory
#	if TTTT_jobno is not empty, cancel the job
#	emits a warning if TTTT_jobno is empty and the execution pase is not finalization
# Parameters:
#	$TTTT_jobno - the job number
#	$TTPRN_streamsDomainId - domain id
#	$TTPRN_streamsInstanceId - instance id
# Returns:
#	success
# Exits:
#	if anythig goes wrong, e. g. when the command is called with a wrong job number
# Side Effect:
#	TTTT_jobno is empty'
function cancelJobAndLog {
	if isExistingAndTrue 'TTTT_jobno'; then
		cancelJobAndLogVariable "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$TTTT_jobno"
		TTTT_jobno=''
	else
		isDebug && printDebug "\$TTTT_executionState=$TTTT_executionState"
		if [[ $TTTT_executionState != 'finalization' ]]; then
			printWarning "Variable TTTT_jobno is empty. No job to stop"
		fi
	fi
}
export -f cancelJobAndLog

TTRO_help_cancelJobVariable='
# Function cancelJobVariable
# Parameters:
#	$1 - domain id
#	$2 - instance id
#	$3 - jobno
# Returns:
#	the result code of the executed command'
function cancelJobVariable {
	isDebug && printDebug "$FUNCNAME $*"
	echoAndExecute $TTPRN_st canceljob --domain-id "$1" --instance-id "$2" "$3"
}
export -f cancelJobVariable

TTRO_help_cancelJobAndLogVariable='
# Function cancelJobAndLogVariable
#	cancel job and provide log files in current directory
# Parameters:
#	$1 - domain id
#	$2 - instance id
#	$3 - jobno
# Returns:
#	the result code of the executed tar command
# Exits:
#	if anything goes wrong, e. g. when the command is called with a wrong job number'
function cancelJobAndLogVariable {
	isDebug && printDebug "$FUNCNAME $*"
	echoAndExecute $TTPRN_st canceljob --collectlogs --domain-id "$1" --instance-id "$2" "$3"
	tar xzf "StreamsLogsJob${3}.tgz"
}
export -f cancelJobAndLogVariable

TTRO_help_checkJobNo='
# Function checkJobNo
#	Checks whether the variable TTTT_jobno has a valid job number (is not empty)
#	and set the error condition if the check fails
# Parameters:
#	TTTT_jobno - the job number to check
# Returns:
#	success
# Side Effects:
#	set failure variable if chck has failed'
function checkJobNo {
	if isExistingAndTrue 'TTTT_jobno'; then
		printInfo "The job number is \$TTTT_jobno=$TTTT_jobno"
	else
		setFailure "TTTT_jobno is not existing or empty"
	fi
	return 0
}
export -f checkJobNo

TTRO_help_jobHealthyVariable='
# Function jobHealthyVariable
#	checks whether a job is healthy
# Parameters:
#	$1 - domain id
#	$2 - instance id
#	$3 - jobno
# Returns:
#	success (0) if job is healthy and running
#	error       if job is not healthy or is not running or the command (streamtool lsjob failed
# Exits:
#	if the command is called with wrong parameters
#	if the streamtool lsjob return wrong information
# Side Effects:
#	TTTT_state - the state of the job
#	TTTT_healthy the health information of the job'
function jobHealthyVariable {
	isDebug && printDebug "$FUNCNAME $*"
	if [[ $# -ne 3 ]]; then
		printErrorAndExit "$FUNCNAME $* called with insufficient arguments" $errRt
	fi
	local rr
	if ! rr=$(LC_ALL=en_US $TTPRN_st lsjob --domain-id "$1" --instance-id "$2" --jobs "$3" --xheaders --fmt %Mf); then
		printError "command failed LC_ALL=en_US $TTPRN_st lsjob --domain-id $1 --instance-id $2 --jobs $3 --xheaders --fmt %Mf"
		return $errTestFail
	fi
	local ifsSave="$IFS"
	local IFS=$'\n'
	local x
	local id=''
	local healthyLoc=''
	local stateLoc=''
	for x in $rr; do
		if [[ $x =~ (.*):(.*) ]]; then
			local TTTT_trim
			trim "${BASH_REMATCH[1]}"
			if [[ $TTTT_trim == 'Id' ]]; then
				if [[ -n $id ]]; then printErrorAndExit "Duplicate Id in lsjob response \n $rr" $errRt; fi
				trim "${BASH_REMATCH[2]}"
				id="$TTTT_trim"
			elif [[ $TTTT_trim == 'State' ]]; then
				if [[ -n $stateLoc ]]; then printErrorAndExit "Duplicate State in lsjob response \n $rr" $errRt; fi
				trim "${BASH_REMATCH[2]}"
				stateLoc="$TTTT_trim"
			elif [[ $TTTT_trim == 'Healthy' ]]; then
				if [[ -n $healthyLoc ]]; then printErrorAndExit "Duplicate Healthy in lsjob response \n $rr" $errRt; fi
				trim "${BASH_REMATCH[2]}"
				healthyLoc="$TTTT_trim"
			fi
		fi
	done
	IFS="$ifsSave"
	TTTT_state="$stateLoc"
	TTTT_healthy="$healthyLoc"
	isDebug && printDebug "$FUNCNAME loop end result id=$id State=$stateLoc Healthy=$healthyLoc"
	if [[ $id -ne $3 ]]; then
		printErrorAndExit "Differet job returned $3 $id" $errRt
	fi
	if [[ ( $stateLoc == 'Running' ) && ( $healthyLoc == 'yes' ) ]]; then
		return 0
	else
		return $errTestFail
	fi
}
export -f jobHealthyVariable

TTRO_help_jobHealthy='
# Function jobHealthy
#	checks whether a job is healthy
#	This function has the same function as function jobHealthyVariable except parameters
# Parameters:
#	TTPRN_streamsDomainId   - domain id
#	TTPRN_streamsInstanceId - instance id
#	TTTT_jobno              - job number
# Returns:
#	see jobHealthyVariable
# Exits:
#	see jobHealthyVariable
# Side Effects:
#	see jobHealthyVariable'
function jobHealthy {
	jobHealthyVariable "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$TTTT_jobno"
}
export -f jobHealthy

TTRO_help_jobHealthyAndIntercept='
# Function jobHealthyAndIntercept
#	checks whether a job is healthy and return code is always 0
#	This function has the same function as function jobHealthy except return and side effects
#	provides return code of in variable TTTT_result
# Parameters:
#	see jobHealthy
# Returns:
#	success
# Exits:
#	see jobHealthyVariable
# Side Effects:
#	see jobHealthyVariable
#	TTTT_result - success if job is healthy and running
#	              error  if job is not healthy or not running or command has failed'
function jobHealthyAndIntercept {
	if jobHealthyVariable "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$TTTT_jobno"; then
		TTTT_result=0
	else
		TTTT_result=$?
	fi
	return 0
}
export -f jobHealthyAndIntercept

TTRO_help_waitForFin='
# Function waitForFin
#	waits until the final file appears
#	see also function waitForFileToAppear
# Parameters:
#	$TT_waitForFileName - the name of the file to wait for
#	$TT_waitForFileInterval - the interval for that check
# Returns
#	success if the file was found
#	failure otherwise'
function waitForFin {
	waitForFileToAppear "$TT_waitForFileName" "$TT_waitForFileInterval"
}
export -f waitForFin

TTRO_help_waitForFinAndHealth='
# Function waitForFinAndHealth
#	waits until the final file appears and the job remains healthy
#	set failure condition if job changes state from healthy to non healthy
#	$TT_waitForFileName - the name of the file to wait for
#	$TT_waitForFileInterval - the interval
#	returns success if the file was found'
function waitForFinAndHealth {
	local start=$(date -u +%s)
	local now
	local difftime
	while ! jobHealthy; do
		printInfo "Wait for jobno=$TTTT_jobno to become healthy State=$TTTT_state Healthy=$TTTT_healthy"
		sleep "$TT_waitForFileInterval"
		now=$(date -u +%s)
		difftime=$((now-start))
		if [[ $difftime -gt $TTPR_waitForJobHealth ]]; then
			setFailure "Takes to long ( $difftime ) for the job to become healty"
			return 0
		fi
	done
	printInfo "jobno=$TTTT_jobno becomes healthy State=$TTTT_state Healthy=$TTTT_healthy"
	while ! [[ -e "$TT_waitForFileName" ]]; do
		printInfo "Wait for file to appear $TT_waitForFileName"
		sleep "$TT_waitForFileInterval"
		if ! jobHealthy; then
			setFailure "The jobno=$TTTT_jobno becomes unhealty State=$TTTT_state Healthy=$TTTT_healthy"
			return 0
		fi
	done
	printInfo "File to appear $TT_waitForFileName exists"
	return 0
}
export -f waitForFinAndHealth

:
