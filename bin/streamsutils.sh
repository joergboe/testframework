#########################################
# Streams utilities for testframework

####################################################
# Initialization section

#required global varaible for result propagation
declare result=''

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
setVar TTPRN_numresources 1

if declare -p STREAMS_ZKCONNECT &> /dev/null && [[ -n $STREAMS_ZKCONNECT ]]; then
	setVar TTPRN_streamsZkConnect "$STREAMS_ZKCONNECT"
else
	setVar TTPRN_streamsZkConnect ""
fi
echo "streamsutilsInitialization: TTPRN_streamsZkConnect=$TTPRN_streamsZkConnect"
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
setVar 'TT_mainComposite' 'Main'
setVar 'TT_evaluationFile' './EVALUATION.log'
setVar 'TT_sabFile' './output/Main.sab' 
setVar 'TT_jobFile' './jobno.log'


#########################################################
# Functions section

TTRO_help_copyAndTransformSpl='
# Function copyAndTransformSpl
#	Copy all files from input directory to workdir and
#	Transform spl files'
function copyAndTransformSpl {
	copyAndTransform "$TTRO_inputDirCase" "$TTRO_workDirCase" "$TTRO_variantCase" '*.spl'
}
export -f copyAndTransformSpl

TTRO_help_compile='
# Function compile
#	Compile spl application expect successful result
#	No treatment in case of compiler error'
function compile {
	echoAndExecute ${TTPRN_splc} "$TTPR_splcFlags" -M $TT_mainComposite -t "$TT_toolkitPath" -j $TTRO_treads
}
export -f compile

TTRO_help_compileAndFile='
# Function compileAndFile
#	Compile spl application expect successful result
#	compiler colsole & error output is stored into file
#	No treatment in case of compiler error'
function compileAndFile {
	echoAndExecute ${TTPRN_splc} "$TTPR_splcFlags" -M $TT_mainComposite -t "$TT_toolkitPath" -j $TTRO_treads 2>&1 | tee "$TT_evaluationFile"
}
export -f compileAndFile 

TTRO_help_compileAndIntercept='
# Function compileAndIntercept
#	Compile spl application and intercept compile errors
#	compiler colsole & error output is stored into file
#	compiler result code is sored in result'
function compileAndIntercept {
	if echoAndExecute ${TTPRN_splc} "$TTPR_splcFlags" -M $TT_mainComposite -t "$TT_toolkitPath" -j $TTRO_treads 2>&1 | tee "$TT_evaluationFile"; then
		result=0
	else
		result=$?
	fi
	return 0
}
export -f compileAndIntercept

TTRO_help_makeZkParameter='
# Function makeZkParameter
#	makes the zk parameter from zk environment
#	$1 zk string
#	use global variable zkParam'
function makeZkParameter {
	zkParam="--embeddedzk"
	if [[ -n $1 ]]; then
		zkParam="--zkconnect $1"
	fi
}
export -f makeZkParameter 

TTRO_help_mkDomain='
# Function mkDomain
#	Make domain from global properties'
function mkDomain {
	mkDomainVariable "$TTPRN_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_swsPort" "$TTPRN_jmxPort"
}
export -f mkDomain 

TTRO_help_mkDomainVariable='
# Function mkDomainVariable
#	Make domain with variable parameters
#	$1 zk connect string
#	$2 domainname
#	$3 sws port
#	$4 jmx port'
function mkDomainVariable {
	isDebug && printDebug "$FUNCNAME $*"
	if [[ -n $TTPRN_noStart ]]; then
		printInfo "$FUNCNAME : function supressed"
		return 0
	fi
	local zkParam
	makeZkParameter "$1"
	#local params="$zkstring --property SWS.Port=8443 --property JMX.Port=9443 --property domain.highAvailabilityCount=1 --property domain.checkpointRepository=fileSystem --property domain.checkpointRepositoryConfiguration= { \"Dir\" : \"/home/joergboe/Checkpoint\" } "
	if ! echoAndExecute $TTPRN_st mkdomain "$zkParam" --domain-id "$2" --property "SWS.Port=$3" --property "JMX.Port=$4" --property domain.highAvailabilityCount=1; then
		printError "$FUNCNAME : Can not make domain $2"
		#return 1
		return $errTestFail
	fi
	if ! echoAndExecute $TTPRN_st genkey "$zkParam"; then
		printError "$FUNCNAME : Can not genrate key $2"
		return $errTestFail
	fi
}
export -f mkDomainVariable 

TTRO_help_startDomain='
# Function startDomain
#	Start domain from global properties'
function startDomain {
	startDomainVariable "$TTPRN_streamsZkConnect" "$TTPRN_streamsDomainId"
}
export -f startDomain 

TTRO_help_startDomainVariable='
# Function startDomainVariable
#	Make domain with variable parameters
#	$1 zk connect string
#	$2 domainname'
function startDomainVariable {
	isDebug && printDebug "$FUNCNAME $*"
	if [[ -n $TTPRN_noStart ]]; then
		printInfo "$FUNCNAME : function supressed"
		return 0
	fi
	local zkParam
	makeZkParameter "$1"
	if ! echoAndExecute $TTPRN_st startdomain "$zkParam" --domain-id "$2"; then
		printError "$FUNCNAME : Can not start domain $2"
		return $errTestFail
	fi
}
export -f startDomainVariable

TTRO_help_mkInst='
# Function mkInst
#	Make instance from global properties'
function mkInst {
	mkInstVariable "$TTPRN_streamsZkConnect" "$TTPRN_streamsInstanceId" "$TTPRN_numresources"
}
export -f mkInst

TTRO_help_mkInstVariable='
# Function mkInstVariable
#	Make instance with variable parameters
#	$1 zk connect string
#	$2 instance name
#	$3 numresources'
function mkInstVariable {
	isDebug && printDebug "$FUNCNAME $*"
	if [[ -n $TTPRN_noStart ]]; then
		printInfo "$FUNCNAME : function supressed"
		return 0
	fi
	local zkParam
	makeZkParameter "$1"
	if ! echoAndExecute $TTPRN_st mkinst "$zkParam" --instance-id "$2" --numresources "$3"; then
		printError "$FUNCNAME : Can not make instance $2"
		return $errTestFail
	fi
}
export -f mkInstVariable

TTRO_help_startInst='
# Function startInst
#	Start instance from global properties'
function startInst {
	startInstVariable "$TTPRN_streamsZkConnect" "$TTPRN_streamsInstanceId"
}
export -f startInst

TTRO_help_startInstVariable='
# Function startInstVariable
#	Start instance with variable parameters
#	$1 zk connect string
#	$2 domainname'
function startInstVariable {
	isDebug && printDebug "$FUNCNAME $*"
	if [[ -n $TTPRN_noStart ]]; then
		printInfo "$FUNCNAME : function supressed"
		return 0
	fi
	local zkParam
	makeZkParameter "$1"
	if ! echoAndExecute $TTPRN_st startinst "$zkParam" --instance-id "$2"; then
		printError "$FUNCNAME : Can not start instance $2"
		return $errTestFail
	fi
}
export -f startInstVariable

TTRO_help_cleanUpInstAndDomainAtStart='
# Function cleanUpInstAndDomainAtStart deprecated
#	stop and clean instance and domain'
function cleanUpInstAndDomainAtStart {
	cleanUpInstAndDomainVariableOld "start" "$TTPRN_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId"
}
export -f cleanUpInstAndDomainAtStart

TTRO_help_cleanUpInstAndDomainAtStop='
# Function cleanUpInstAndDomainAtStop deprecated
#	stop and clean instance and domain'
function cleanUpInstAndDomainAtStop {
	cleanUpInstAndDomainVariableOld "stop" "$TTPRN_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId"
}
export -f cleanUpInstAndDomainAtStop

TTRO_help_cleanUpInstAndDomainVariableOld='
# Function cleanUpInstAndDomainVariableOld deprecated
#	stop and clean instance and domain from variable params
#	$1 start or stop determines the if TTPRN_noStart or TTPRN_noStop is evaluated
#	$2 zk string
#	$3 domain id
#	$4 instance id'
function cleanUpInstAndDomainVariableOld {
	isDebug && printDebug "$FUNCNAME $*"
	if [[ $1 == start ]]; then
		if [[ -n $TTPRN_noStart ]]; then
			printInfo "$FUNCNAME : at start function supressed"
			return 0
		fi
	elif [[ $1 == stop ]]; then
		if [[ -n $TTPRN_noStop ]]; then
			printInfo "$FUNCNAME : at stop function supressed"
			return 0
		fi
	else
		printErrorAndExit "wrong parameter 1 $1" $errRt
	fi

	local zkParam
	makeZkParameter "$2"
	
	echo "streamtool lsdomain $zkParam $3"
	local response
	if response=$(echoAndExecute $TTPRN_st lsdomain "$zkParam" "$3"); then # domain exists
		if [[ $response =~ $3\ Started ]]; then # domain is running
			#Running domain found check instance
			if echoAndExecute $TTPRN_st lsinst "$zkParam" --domain-id "$3" "$4"; then
				if echoAndExecute $TTPRN_st lsinst "$zkParam" --started --domain-id "$3" "$4"; then
					#TODO: check whether the retun code is fine here
					echoAndExecute $TTPRN_st stopinst "$zkParam" --force --domain-id "$3" --instance-id "$4"
				else
					isVerbose && printVerbose "$FUNCNAME : no running instance $4 found in domain $3"
				fi
				echoAndExecute $TTPRN_st rminst "$zkParam" --noprompt --domain-id "$3" --instance-id "$4"
			else
				isVerbose && printVerbose "$FUNCNAME : no instance $4 found in domain $3"
			fi
			#End Running domain found check instance
			echoAndExecute $TTPRN_st stopdomain "$zkParam" --force --domain-id "$3"
		else
			isVerbose && printVerbose "$FUNCNAME : no running domain $3 found"
		fi
		echoAndExecute $TTPRN_st rmdomain "$zkParam" --noprompt --domain-id "$3"
	else
		isVerbose && printVerbose "$FUNCNAME : no domain $3 found"
	fi
	return 0
}
export -f cleanUpInstAndDomainVariableOld

TTRO_help_cleanUpInstAndDomain='
# Function cleanUpInstAndDomain
#	stop instance and domain if running and clean instance and domain'
function cleanUpInstAndDomain {
	cleanUpInstAndDomainVariable "$TTPRN_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId"
}
export -f cleanUpInstAndDomain

TTRO_help_cleanUpInstAndDomainVariable='
# Function cleanUpInstAndDomainVariable
#	stop and clean instance and domain from variable params
#	$1 zk string
#	$2 domain id
#	$3 instance id'
function cleanUpInstAndDomainVariable {
	isDebug && printDebug "$FUNCNAME $*"
	local zkParam
	makeZkParameter "$1"
	
	echo "streamtool lsdomain $zkParam $2"
	local response
	if response=$(echoAndExecute $TTPRN_st lsdomain "$zkParam" "$2"); then # domain exists
		if [[ $response =~ $2\ Started ]]; then # domain is running
			#Running domain found check instance
			if echoAndExecute $TTPRN_st lsinst "$zkParam" --domain-id "$2" "$3"; then
				if echoAndExecute $TTPRN_st lsinst "$zkParam" --started --domain-id "$2" "$3"; then
					#TODO: check whether the retun code is fine here
					echoAndExecute $TTPRN_st stopinst "$zkParam" --force --domain-id "$2" --instance-id "$3"
				else
					isVerbose && printVerbose "$FUNCNAME : no running instance $3 found in domain $2"
				fi
				echoAndExecute $TTPRN_st rminst "$zkParam" --noprompt --domain-id "$2" --instance-id "$3"
			else
				isVerbose && printVerbose "$FUNCNAME : no instance $3 found in domain $2"
			fi
			#End Running domain found check instance
			echoAndExecute $TTPRN_st stopdomain "$zkParam" --force --domain-id "$2"
		else
			isVerbose && printVerbose "$FUNCNAME : no running domain $2 found"
		fi
		echoAndExecute $TTPRN_st rmdomain "$zkParam" --noprompt --domain-id "$2"
	else
		isVerbose && printVerbose "$FUNCNAME : no domain $2 found"
	fi
	return 0
}
export -f cleanUpInstAndDomainVariable

TTRO_help_submitJobOld='
# Function submitJobOld
#	$1 sab files
#	$2 output file name'
function submitJobOld {
	submitJobVariable "$TTPRN_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$1" "$2"
}
export -f submitJobOld

TTRO_help_submitJob='
# Function submitJob
#	submits a job and provides the joboutput file'
function submitJob {
	submitJobVariable "$TTPRN_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$TT_sabFile" "$TT_jobFile"
}
export -f submitJob

TTRO_help_submitJobAndFile='
# Function submitJobAndFile
#	submits a job and provides the joboutput file
#	provide stdout and stderror in file for evaluation'
function submitJobAndFile {
	submitJobVariable "$TTPRN_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$TT_sabFile" "$TT_jobFile" 2>&1 | tee "$TT_evaluationFile"
}
export -f submitJobAndFile

TTRO_help_submitJobAndIntercept='
# Function submitJobAndIntercept
#	submits a job and provides the joboutput file
#	provide stdout and stderror in file for evaluation
#	provides return code of in variable result'
function submitJobAndIntercept {
	if submitJobVariable "$TTPRN_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$TT_sabFile" "$TT_jobFile" 2>&1 | tee "$TT_evaluationFile"; then
		result=0
	else
		result=$?
	fi
	return 0
}
export -f submitJobAndIntercept

TTRO_help_submitJobVariable='
# Function submitJobVariable
#	$1 zk string
#	$2 domain id
#	$3 instance id
#	$4 sab files
#	$5 output file name
#	use global variable jobno for jobnumber'
function submitJobVariable {
	isDebug && printDebug "$FUNCNAME $*"
	local zkParam
	makeZkParameter "$1"
	if echoAndExecute $TTPRN_st submitjob "$zkParam" --domain-id "$2" --instance-id "$3" --outfile "$5" "$4"; then
		if [[ -e $5 ]]; then
			jobno=$(<"$5")
			return 0
		else
			return $errTestFail
		fi
	else
		return $errTestFail
	fi
}
export -f submitJobVariable
declare jobno=''

TTRO_help_cancelJob='
# Function cancelJob
#	$1 jobno'
function cancelJob {
	cancelJobVariable "$TTPRN_streamsZkConnect" "$TTPRN_streamsDomainId" "$TTPRN_streamsInstanceId" "$1"
}
export -f cancelJob

TTRO_help_cancelJobVariable='
# Function cancelJobVariable
#	$1 zk string
#	$2 domain id
#	$3 instance id
#	$4 jobno'
function cancelJobVariable {
	isDebug && printDebug "$FUNCNAME $*"
	local zkParam
	makeZkParameter "$1"
	if echoAndExecute $TTPRN_st canceljob "$zkParam" --domain-id "$2" --instance-id "$3" "$4"; then
		return 0
	else
		return $errTestFail
	fi
}
export -f cancelJobVariable

:
