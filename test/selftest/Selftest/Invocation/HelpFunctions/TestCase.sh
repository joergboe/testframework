#--variantList='help man bashhelp ref'

STEPS='executeCase myEvaluate'

declare -A outputValidation=()

case $TTRO_variantCase in
	help)
		patternList=('usage: run*'
					'OPTIONS:*'
					'-h|--help                : display this help'
					'--man                    : display man page'
					'--ref VALUE              : display function reference. If value is the empty value, the reference of the internal functions is displayed.'
					'-w|--workdir  VALUE      : The working directory. Here are all work files and results are stored. Default is ./runTTFWorkdir .'
					'-f|--flat                : Use flat working directory - does not include the date/time string into the workdir path'
					'--noprompt               : Do not prompt berfore an existing working directory is removed.'
					'-i|--directory VALUE     : The input directory - the test collection directory. There is no default. This option must be entered.'
					'-p|--properties VALUE    : This specifies the file with the global property values. Default is file TestProperties.sh in input directory.'
					'                           This option can be given more than one time. '
					'-t|--tools VALUE         : Includes (source) files with test tool scripts. This option can be given more than one time.'
					'-c|--category VALUE      : Enter the category pattern for this test run. The pattern must not contain white spaces. '
					'                           Quote the value or escape special characters. This option can be given more than one time.'
					'--skip-ignore            : If this option is given the skip and category attributes of the cases and suite are ignored'
					'-s|--sequential          : Sequential test execution. No parallel test execution is performed.'
					'-j|--threads VALUE       : The number of parallel threads used. (you have 8 (virtual) cores this is default)'
					'-l|--link                : Content found in data directoy are linked to workspace not copied (Set TYPRN_link=true)'
					'--no-start               : Supress the execution of the start sequence (Set TYPRN_noStart)'
					'--no-stop                : Supress the execution of tear stop sequencd (Set TYPRN_noStop)'
					'--no-browser             : Do not start browser after test execution.')
		;;
	man)
		patternList=('The runTTF script is a framework for the control of test case execution.*'
					 'The execution of test case/suite variants and the parallel execution is inherently supported.*'
					 '## Test Cases, Test Suites and Test Collections*'
					 '==============================================='
					 "A test case is comprised of a directory with the main test case file with name: 'TestCase.sh' and other necessary artifacts"
					 "which are necessary for the test execution."
					 "The name of a test case is the relative path from the containing entity to the main test case file."
					 "The test case file contains the necessary definitions and the script code to execute the test.")
		;;
	bashhelp)
		patternList=('Export Variables*'
					 '================*'
					 'The ro attribute (and others) is not availble in the child shell*')
		;;
	ref)
		patternList=('############################*')
		;;
esac

function executeCase {
	local tmp="--$TTRO_variantCase"
	if [[ $TTRO_variantCase == "ref" ]]; then
		if $TTPRN_binDir/runTTF '--ref' '' '--directory' "$TTRO_inputDirCase/test" '--noprompt' '-d' 2>&1 | tee STDERROUT1.log; then
			return 0
		else
			return $errTestFail
		fi
	else
		echo "$tmp"
		if $TTPRN_binDir/runTTF $tmp 2>&1 | tee STDERROUT1.log; then
			return 0
		else
			return $errTestFail
		fi
	fi
}

function myEvaluate {
	if ! linewisePatternMatchArray './STDERROUT1.log' "true"; then
		setFailure "Output evaluation failed"
	fi
	return 0
}