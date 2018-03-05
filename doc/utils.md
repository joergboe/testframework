#######################################
#		arrayHasKey
# Function arrayHasKey
#	check is an associative array has key
#	$1 the array name
#	$2 the key value to search
#	returns
#		success(0)    if key exists in array
#		error(1)      otherwise
#	exits if called with wrong arguments


#######################################
#		copyAndTransform
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
#	exits  if called with wrong arguments


#######################################
#		copyOnly
# Function copyOnly
#	Copy all files from input directory to workdir


#######################################
#		dequote
# Removes the sorounding quotes
#	and prints result to stdout
#	to be used withg care unquoted whitespaces are removed
#	$1 the value to dequote
#	returns:
#		success (0)
#		error	in exceptional cases


#######################################
#		echoAndExecute
# Function echoAndExecute
#	echo and execute a command with variable arguments
#	$1 the command string
#	$2 .. the parameters of the command
#	returns the result code of the executed command
#	exits if no command string is given or command is empty


#######################################
#		echoExecuteAndIntercept
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
#	$3 the parameters as one string - during execution expansion and word splitting is applied


#######################################
#		fixPropsVars
# Function fixPropsVars
#	This function fixes all ro-variables and propertie variables
#	Property and variables setting is a two step action:
#	Unset help variables if no reference is printed
#	make vars STEPS PREPS FINS read-only
#	returns:
#		success (0)
#		error	in exceptional cases


#######################################
#		import
# Function registerTool
#	Treats the input as filename and adds it to TT_tools if not already there
#	sources the file if it was not in TT_tools
#	return the result code of the source command


#######################################
#		isArray
# Function isArray
#	checks whether an variable exists and is an indexed array
#	$1 var name to be checked
#	returns
#		success(0)   if the variable exists and is an indexed array
#		error(1)     otherwise


#######################################
#		isDebug
# Function isDebug
# 	returns:
#		success(0) if debug is enabled
#		error(1)   otherwise 


#######################################
#		isExisting
# Function isExisting
#	check if variable exists
#	$1 var name to be checked
#	returns
#		success(0)    if the variable exists
#		error(1)      otherwise


#######################################
#		isExistingAndFalse
# Function isExistingAndFalse
#	check if variable exists and has an empty value
#	$1 var name to be checked
#	returns
#		success(0)    exists and has an empty value
#		error(1)      otherwise


#######################################
#		isExistingAndTrue
# Function isExistingAndTrue
#	check if variable exists and has a non empty value
#	$1 var name to be checked
#	returns
#		success(0)    exists and has a non empty value
#		error(1)      otherwise


#######################################
#		isFalse
# Function isFalse
#	check if a variable has an empty value
#	$1 var name to be checked
#	returns
#		success(0)    if the variable exists and has a empty value
#		error(1)      if the variable exists and has an non empty value
#	exits if variable not exists


#######################################
#		isFunction
# Function isFunction
#	checks whether an given name is defined as function
#	$1 name to be checked
#		success(0)   if the function exists
#		error(1)     otherwise


#######################################
#		isInList
# check whether a token is in a space separated list of tokens
#	$1 the token to search. It must not contain whitespaces
#	$2 the space separated list
#	returns true if the token was in the list; false otherwise
#	exits if called with wrong parameters


#######################################
#		isNotExisting
# Function isNotExisting
#	check if variable not exists
#	$1 var name to be checked
#	returns
#		success(0)    if the variable not exists
#		error(1)      otherwise


#######################################
#		isNumber
# Checks whether the input string is a signed or unsigned number ([-+])[0-9]+
# $1 the string to check
# returns
#	success(0)  if the input is a number
#	error(1)    otherwise


#######################################
#		isPureNumber
# Checks whether the input string is a ubsigned number [0-9]+
# $1 the string to check
# returns
#	success(0)  if the input are digits only
#	error(1)    otherwise


#######################################
#		isTrue
# Function isTrue
#	check if a variable has a non empty value
#	$1 var name to be checked
#	returns
#		success(0)    variable exists and has a non empty value
#		error(1)      variable exists and has a empty value
#	exits if variable not exists


#######################################
#		isVerbose
# Function isVerbose
#	returns
#		success(0) if debug is enabled
#		error(1)   otherwise 


#######################################
#		linewisePatternMatch
# Function linewisePatternMatch
#	Line pattern validator
#	$1 - the input file
#	$2 - if set to "true" all pattern must generate a match
#	$3 .. - the pattern to match
#	returns
#		success(0)   if file exist and one patten matches ($2 -eq true)
#	                 if file exist and one patten matches ($2 -eq true)
#	return false if no complete pattern match was found or the file not exists


#######################################
#		linewisePatternMatchArray
# Function linewisePatternMatchArray
#	Line pattern validator with array input variable
#	the pattern to match as array 0..n are expected to be in patternList array variable
#	$1 - the input file
#	$2 - if set to "true" all pattern must generate a match
#	$patternList the indexed array with the pattern to search
#		success(0)   if file exist and one patten matches ($2 -eq true)
#	                 if file exist and one patten matches ($2 -eq true)
#	return false if no complete pattern match was found or the file not exists


#######################################
#		printDebug
# Function printDebug
#	prints debug info
#	$1 the debug info to print
#	returns:
#		success (0)
#		error	in exceptional cases


#######################################
#		printDebugn
# Function printDebugn
#	prints debug info without newline
#	$1 the debug info to print
#	returns:
#		success (0)
#		error	in exceptional cases


#######################################
#		printError
# Function printError
#	prints an error message
#	$1 the error message to print
#	returns:
#		success (0)
#		error	in exceptional cases


#######################################
#		printErrorAndExit
# Function printErrorAndExit
# 	prints an error message and exits
#	$1 the error message to print
#	$2 the exit code
#	returns: never


#######################################
#		printInfo
# Function printInfo
#	prints info info
#	$1 the info to print
#	returns:
#		success (0)
#		error	in exceptional cases


#######################################
#		printInfon
# Function printInfon
#	prints info info without newline
#	$1 the info to print
#	returns:
#		success (0)
#		error	in exceptional cases


#######################################
#		printTestframeEnvironment
# Function printTestframeEnvironment
# 	print special testrame environment
#	returns:
#		success (0)
#		error	in exceptional cases


#######################################
#		printVerbose
# Function printVerbose
#	prints verbose info
#	$1 the info to print
#	returns:
#		success (0)
#		error	in exceptional cases


#######################################
#		printVerbosen
# Function printVerbosen
#	prints verbose info without newline
#	$1 the info to print
#	returns:
#		success (0)
#		error	in exceptional cases


#######################################
#		printWarning
# Function printWarning
#	prints an warning message
#	$1 the warning to print
#	returns:
#		success (0)
#		error	in exceptional cases


#######################################
#		promptYesNo
# Function promptYesNo
#	Write prompt and wait for user input y/n
#	optional $1 the text for the prompt
#	honors TTRO_noPrompt
#	returns
#		success(0) if y/Y was enterd
#		error(1) if n/N was entered
#	exits id ^C was pressed


#######################################
#		renameInSubdirs
# Function renameInSubdirs
#	Renames a special file name in all base directory and in all sub directories
#	$1 the base directory
#	$2 the source filename
#	$3 the destination filename


#######################################
#		setFailure
# Function setFailure
#	set a use defined failure condition
#	to be used in failed test cases
#	$1 the failure text


#######################################
#		setVar
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
#		ignored property values do not generate an error


#######################################
#		skip
# Function skip
#	set the skip condition


#######################################
#		splitVarValue
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
#		error(1)   otherwise


