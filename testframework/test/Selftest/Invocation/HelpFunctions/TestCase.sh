#--variantList='help man bashhelp ref'

STEPS='executeCase myEvaluate'

declare -A outputValidation=()

case $TTRO_caseVariant in
	help)
		patternList=('usage: run*'
					'OPTIONS:*'
					'-h|--help                : display this help'
					'--man                    : display man page'
					'--ref                    : display function reference. This function requires a specified input directory.'
					'-w|--workdir  VALUE      : The working directory. Here are all work files and results are stored. Default is*'
					'-f|--flat                : Use flat working directory - does not include the date/time string into the workdir path'
					'--noprompt               : Do not prompt berfore an existing working directory is removed.'
					'-i|--directory VALUE     : The input directory - the test collection directory. There is no default. This option must be entered.'
					'-p|--properties VALUE    : This specifies the file with the global property values. Default is file TestProperties.sh in input directory.'
					'*If this path is an relative path, it is expanded relative to the input directory.'
					'-t|--tools VALUE         : Includes (source) files with test tool scripts. This option can be given more than one time. This overwrites then'
					'*TYRO_tools environment.'
					'-n|--no-checks           : The script omits the checkes for the streams environment and does not attempt to start domain/instance. Saves time'
					'-s|--skip-ignore         : If this option is given the ignore attribute of the cases are ignored'
					'-j|--threads VALUE       : The number of parallel test executions. \(you have 8 \(virtual\) cores this is default\)'
					'*If the value is set to 1 no parallel execution is performed'
					'-l|--link                : Content found in data directoy are linked to workspace not copied \(Set TYPN_link=true\)'
					'--no-start               : Supress the execution of the start sequence \(Set TYPN_noStart\)'
					'--no-stop                : Supress the execution of tear stop sequencd \(Set TYPN_noStop\)'
					'-D value                 : Set the specified TY_-, TYRO_-, TYP_- or TYPN_- variable value \(Use one of varname=value\)'
					'-v|--verbose             : Be verbose to stdout'
					'-V|--version             : Print the version string'
					'-d|--debug               : Print debug information. Debug implies verbose.'
					'--bashhelp               : Print some hints for the use of bash')
		;;
	man)
		patternList=('The runTTF script is a framework for the control of test case execution.*'
					 'The execution of test case/suite variants and the parallel execution is inherently supported.*'
					 'Test Cases, Test Suites and Test Collections*'
					 '============================================'
					 "A test case is comprised of a directory with the main test case file with name: 'TestCase.sh' and other necessary artifacts"
					 "which are necessary for the test execution."
					 'The name of a test case is the last component of the path-name of the main test case file.')
		;;
	bashhelp)
		patternList=('Export Variables*'
					 '================*'
					 'The ro attribute (and others) is not availble in the child shell*')
		;;
	ref)
		patternList=('# Function copyAndTransform*'
					'#	Copy and change all files from input dirextory into workdir'
					'#	Filenames that match one of the transformation pattern are transformed. All other files are copied.'
					'#	In case of transformation the pattern //_<varid> is removed if varid equals*'
					'#	In case of transformation the pattern //!<varid> is removed if varid is different than*'
					'#	If the variant identifier is empty, the pattern list sould be also empty and the function is a pure copy function'
					'#	If $3 is empty and $4 .. do not exist, this function is a pure copy'
					'#	$1 - input dir'
					'#	$2 - output dir'
					'#	$3 - the variant identifier'
					'#	$4 ... pattern for file names to be transformed')
		;;
esac

function executeCase {
	local tmp="--$TTRO_caseVariant"
	if [[ $TTRO_caseVariant == "ref" ]]; then
		tmp="--ref --directory $TTRO_inputDirCase/test --noprompt"
	fi
	echo "$tmp"
	if $TTPN_binDir/runTTF $tmp 2>&1 | tee STDERROUT1.log; then
		return 0
	else
		return $errTestFail
	fi
}

function myEvaluate {
	if ! linewisePatternMatchArray './STDERROUT1.log' "true"; then
		failureOccurred='true'
	fi
	return 0
}