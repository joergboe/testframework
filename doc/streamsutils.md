streamsutilsInitialization: TTPRN_streamsZkConnect=
streamsutilsInitialization: TTPRN_streamsDomainId=StreamsDomain
streamsutilsInitialization: TTPRN_streamsInstanceId=StreamsInstance
#######################################
#		cancelJob
# Function cancelJob
#	$1 jobno


#######################################
#		cancelJobVariable
# Function cancelJobVariable
#	$1 zk string
#	$2 domain id
#	$3 instance id
#	$4 jobno


#######################################
#		cleanUpInstAndDomain
# Function cleanUpInstAndDomain
#	stop instance and domain if running and clean instance and domain


#######################################
#		cleanUpInstAndDomainAtStart
# Function cleanUpInstAndDomainAtStart deprecated
#	stop and clean instance and domain


#######################################
#		cleanUpInstAndDomainAtStop
# Function cleanUpInstAndDomainAtStop deprecated
#	stop and clean instance and domain


#######################################
#		cleanUpInstAndDomainVariable
# Function cleanUpInstAndDomainVariable
#	stop and clean instance and domain from variable params
#	$1 zk string
#	$2 domain id
#	$3 instance id


#######################################
#		cleanUpInstAndDomainVariableOld
# Function cleanUpInstAndDomainVariableOld deprecated
#	stop and clean instance and domain from variable params
#	$1 start or stop determines the if TTPRN_noStart or TTPRN_noStop is evaluated
#	$2 zk string
#	$3 domain id
#	$4 instance id


#######################################
#		compile
# Function compile
#	Compile spl application expect successful result
#	No treatment in case of compiler error


#######################################
#		compileAndFile
# Function compileAndFile
#	Compile spl application expect successful result
#	compiler colsole & error output is stored into file
#	No treatment in case of compiler error


#######################################
#		compileAndIntercept
# Function compileAndIntercept
#	Compile spl application and intercept compile errors
#	compiler colsole & error output is stored into file
#	compiler result code is sored in result


#######################################
#		copyAndTransformSpl
# Function copyAndTransformSpl
#	Copy all files from input directory to workdir and
#	Transform spl files


#######################################
#		makeZkParameter
# Function makeZkParameter
#	makes the zk parameter from zk environment
#	$1 zk string
#	use global variable zkParam


#######################################
#		mkDomain
# Function mkDomain
#	Make domain from global properties


#######################################
#		mkDomainVariable
# Function mkDomainVariable
#	Make domain with variable parameters
#	$1 zk connect string
#	$2 domainname
#	$3 sws port
#	$4 jmx port


#######################################
#		mkInst
# Function mkInst
#	Make instance from global properties


#######################################
#		mkInstVariable
# Function mkInstVariable
#	Make instance with variable parameters
#	$1 zk connect string
#	$2 instance name
#	$3 numresources


#######################################
#		startDomain
# Function startDomain
#	Start domain from global properties


#######################################
#		startDomainVariable
# Function startDomainVariable
#	Make domain with variable parameters
#	$1 zk connect string
#	$2 domainname


#######################################
#		startInst
# Function startInst
#	Start instance from global properties


#######################################
#		startInstVariable
# Function startInstVariable
#	Start instance with variable parameters
#	$1 zk connect string
#	$2 domainname


#######################################
#		submitJob
# Function submitJob
#	submits a job and provides the joboutput file


#######################################
#		submitJobAndFile
# Function submitJobAndFile
#	submits a job and provides the joboutput file
#	provide stdout and stderror in file for evaluation


#######################################
#		submitJobAndIntercept
# Function submitJobAndIntercept
#	submits a job and provides the joboutput file
#	provide stdout and stderror in file for evaluation
#	provides return code of in variable result


#######################################
#		submitJobOld
# Function submitJobOld
#	$1 sab files
#	$2 output file name


#######################################
#		submitJobVariable
# Function submitJobVariable
#	$1 zk string
#	$2 domain id
#	$3 instance id
#	$4 sab files
#	$5 output file name
#	use global variable jobno for jobnumber


