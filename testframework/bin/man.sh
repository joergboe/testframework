function manpage () {
	local command=${0##*/}
	less <<-EOF

	The $command script is a framework for the control of test case execution.
	The execution of test case/suite variants and the parallel execution is inherently supported.


	Test Cases, Test Suites and Test Collections
	============================================
	A test case is comprised of a directory with the main test case file with name: '$TEST_CASE_FILE' and other necessary artifacts
	which are necessary for the test execution.
	The name of a test case is the last component of the path-name of the main test case file.
	The test case file conains the necessary definitions and the script code to execute the test.
	
	A test suite is a collection of test cases which are organized in a test suite directory. The directory sub tree
	of the test suite may have an arbitrary depth.
	A test suite is defined through a directory with the main suite file with name: '$TEST_SUITE_FILE'
	The name of a test suite is the last component of the path-name of the main test suite file.
	The test suite file contains the necessary definitions and the script code to execute the test suite preparation 
	and suite finalization. The test suite file may contain common suite code (functions must be exported).
	Suites may be omitted.
	
	One or more test suites and / or test cases form a Test Collection. A test collection is defined through a directory with the 
	test collection file with name: '$TEST_COLLECTION_FILE'.
	The test collection file contains the necessary definitions and the script code to execute the test collection preparation 
	and collection finalization. The test collection file may contain common code (functions must be exported).
	A test collection may have a test properties file $TEST_PROPERTIES which should contain the definition of varaible and 
	properties which may be variable in different test environments.
	The name of the test properties file may be changed by a comman line parameter (--properties).
	
	Common used script code may be placed in separate script files, which must be registered during test run.
	
	Test suites must not be nested in other test suites or test cases.
	Test cases must not be nested in other test case directories.
	All path names of test cases and suites must not contain any white space characters. A test Suite must not have the name '--'.
	
	Test Cases, Test Suites and Test Collections may define variants. This allows the repeated execution of the artifact with changed
	parameter sets.


	Execution Environment
	======================
	The test framework starts with the analysis of the input directory (option -i|--directory). If no cases list is given as
	command line parameter, all found test cases which are not marked with a 'skipped' property are executed.
	If a cases list is given from the command line, all test cases with match the cases list are executed (pattern match)
	
	All generated artifacts are stored in a sub-directory of the workdir (option -w|--workdir) for further analysis.
	The sub-directory name is composed of the actual date and time when the test case execution starts.
	
	A summary is printed after test case execution.


	Test Case File '$TEST_CASE_FILE', Test Suite File '$TEST_SUITE_FILE' and the '$TEST_COLLECTION_FILE'
	====================================================================================================
	These files may have two sections: The preamble and a script code section. Both sections may be empty.
	
	The preamble defines variables which are neccessary before execution of appropriate artifacts starts.
	A preamble statement starts with the character sequence '#--' and the variable definition must follow
	immediately. (No spaces). The definition of the variables and properties must have the form:
	#--<name>=<value>
	or
	#--<name>:=<value>
	No spaces are allowed between name '='/':=' and value.
	If the ':=' operator is used, the assignment is literally executed. That means no expansion and no word splitting is 
	performed and no quoting is required.
	If the '=' operator is used, the assignment executed with eval. That means expansion and word splitting is 
	performed and hence quoting is required.
	The whole assignment must fit into one line.
	The expansion is executed in the environment of the calling artifact.
	
	The script code section is a bash script. In the script section, you can define required custom functions for the 
	initialization, the test preparation, for the test step execution and the test finalization. The script code of the main body 
	is executed during initialization of the Test collection, of the Test suite or of the Test case.


	Test Property File $TEST_PROPERTIES
	===================================
	This file may contain global property and variable definitions. This file should no contain script code. This file is intended 
	to store stuff which may change when the test collection is executed in different environments. The default name of this 
	file is '$TEST_PROPERTIES' and it is expected in the Test collection directory. An alternative file name may be assigned with 
	command line parameter --properties or the environment TT_properties is evaluated. The properties file is a bash script.


	Test Tools and Modules
	======================
	If your test collection requires special functions, you must source the appropriate modules from the test collection file. 
	Especially the streamsutils.sh must be sourced at the beginning of the main body of the test collection file:
	
	registerTool "$TTRO_scriptDir/streamsutils.sh"
	or
	setVar 'TT_tools' "$TT_tools $TTRO_scriptDir/streamsutils.sh"
	
	The first form sources the script 'streamsutils.sh' and modifies the TT_tools variable.
	The seconmd form modifies the TT_tools variable only. The utilites script is sourced during start up of the called artifact.


	Test File Preample
	==================
	The preamble defines the variants of the test artifacts and in case of a tes case, the timeout values for the test case.
	NOTE: The values do not require enclosing quotes.
	
	Test Collection, Test Case and Test Suite variants
	
	The variants of cases, suites and collections are defined in the preamble of the '$TEST_CASE_FILE', the '$TEST_SUITE_FILE' or
	the $TEST_COLLECTION_FILE file.
	The appropriate file must have either no variant variable, a variantCount variable or a variantList variable.
	
	The variantCount must be in the form:
	#--variantCount=<number>
	#--variantCount:=<number>
	
	The variantList must be a space separated list of identifiers or numbers or a mixture of identifiers and numbers:
	#--variantList=<list>
	#--variantList:=<list>
	
	NOTE: Currently only the operator '=' is supported.
	
	Test Case timeouts
	
	Each test case can define an individual timeout variable. When the timout is reached for an test case, 
	the job is killed with SIGTERM (15). If the job still runs after additional time (TTP_additionalTime), 
	the job is killed with SIGKILL (9).
	If there is no individual timeout defined, the default values TTP_timeout is used.


	Test Framework Variables and Properties
	=======================================
	Variables with the prefix TT_, TTRO_, TTP_ or TTPN_ are treated as global definitions and they are exported from 
	Test Collection to Test Suite and from Test Suite to Test Case.
	
	The variable/property assignment in a description section must have one of these forms:
	
	#--TT_<name>=<value><NL>
	#--TT_<name>:=<value><NL>
	#--TTRO_<name>=<value><NL>
	#--TTRO_<name>:=<value><NL>
	#--TTP_<name>=<value><NL>
	#--TTP_<name>:=<value><NL>
	#--TTPN_<name>=<value><NL>
	#--TTPN_<name>:=<value><NL>
	
	No spaces are allowed between #-- and the property name and between the name and the '=' ':=' operator.
	If the := is used the value is literally assigned to the variable. If the = is used, the value is expanded 
	(e.g. $STREAMS_INSTALL is expanded to the real path value of your streams installation)
	
	The assignments must fit into one line.
	
	In the script code section variables and properties can be assigned with function 'setVar'.
	
	Property Variables
	==================
	Property variables are not changed once they have been defined. Re-definition of property variables will be ignored. 
	An pure assignment to a property in a test suite/case script may cause a script failure. Use function setVar instead.
	The name of a property must be prefixed with TTP_ or TTPN_
	
	Empy values are considered a defined value for properties with prefix TTP_ and can not be overwritten.
	Empy values are considered a undefined value for properties with prefix TTPN_ and can be overwritten.


	Simple Global Variables and Global Readonly Variables
	=====================================================
	Global variables may be defined in the description section or in the script code section of the test artifacts. 
	Simple variables and can be re-written in suite- or test-case-script and must have the prefix TT_. 
	Readonly variables can not be re-written in suite- or in test-case-script and must have the prefix TTRO_. 
	In script code use function setVar to define such a variable. To re-write a global variable a plain assignment is sufficient. 
	A re-write of an readonly varable will cause a script/test failure.
	
	The names of simple variables must be prefixed with TT_. The names of readonly variables must be prefixed 
	with TTRO_
	
	Define simple variables in a script in the form:
	export <name>=<value>
		or
	declare -x <name>=<value>


	Trueness and Falseness
	======================
	Logical variables with the semantics of an boolean are considered 'true' if these variables are set to something different than 
	the empty value (null). An empty (null) variable or an unset variable is considered 'false'. Care must be taken if a 
	variable is unset. In general the usage of an unset variable will cause a script failure. Use function 'isExisting' or 
	'isNotExisting' to avoid script abort.

	Accepted Environment
	====================

	Debug and Verbose
	=================
	The testframe may print verbose information and debug information or both. The verbosity may be enabled with command line options.
	Additionally the verbosity can be controlled with property values:
	TTPN_debug           - enables debug
	TTPN_debugDisable    - disables debug (overrides TTPN_debug)
	TTPN_verbose         - enables verbosity
	TTPN_verboseDisable  - disables verbosity (overrides TTPN_verbose)


	Variables Used
	==============
	TTPN_skip             - Skips the execution of test case preparation, test case execution and test case finalization steps
	TTPN_skipIgnore       - If set to true, the skip variable is ignored.
	
	STEPS                 - The list or an XXXXXof test step commands.  If one command returns an failure (return code != 0), the test execution is stopped
	TTRO_stepsCase        - This variable is designed to store the list of test commands.
	                         and the test is considered a failure. When the execution of all test commands return success the test case is
	                         considered a success.
	PREPS
	TTRO_prepsCase         - This variable is designed to store the list of test case preparation commands. If one command returns an failure (return code != 0), the test execution is stopped
	                         and the test is considered an error.
	FINS
	TTRO_finsCase          - This variable is designed to store the list of test case finalization commands. If one command returns an failure (return code != 0), the error is logged and the execution
	                         is continued
	                         and the test is considered an error.
	TTRO_prepsSuite         - This variable stores the list of test suite preparation commands. If one command returns an failure (return code != 0), the test execution is stopped.
	TTRO_finsSuite          - This variables stores the list of test suite finalization commands. If one command returns an failure (return code != 0), the error is logged and the execution
	                        is continued
	TTRO_preps             - This variable stores the list of global test preparation commands. If one command returns an failure (return code != 0), the test execution is stopped.
	TTRO_fins              - This variable stores the list of global test finalization commands. If one command returns an failure (return code != 0), the error is logged and the execution
	                        is continued
	                         
	TTP_timeout           - The default test case timeout in seconds. default is 120 sec. This variable must be defined in the 
	                        description section of test case file or in the Test Suite or Test Collection. A definition 
	                        in the script section of a Test Case has no effect.
	TTP_additionalTime    - The extra wait time after the test case time out. If the test case does not end after this 
	                        time a SIGKILL is issued and the test case is stopped. The default is 45 sec. This variable 
	                        must be defined in the description section of test case file or in the Test Suite or Test Collection. 
	                        A definition in the script section of a Test Case has no effect.


	Variables Provided
	==================
	TTRO_workDirMain     - The main output directory
	TTRO_workDir         - The output directory of the collection variant
	TTRO_workDirSuite    - The output directory of the suite
	TTRO_workDirCase     - The output directory of the case
	TTRO_inputDir        - The input directory
	TTRO_inputDirSuite   - The input directory of the suite
	TTRO_inputDirCase    - The input directory of the case
	TTRO_collection      - The name of the collection
	TTRO_suite           - The suite name
	TTRO_case            - The case name
	TTRO_variant         - The variant of the collection
	TTRO_suiteVariant    - The variant of the suite
	TTRO_caseVariant     - The variant of the case
	TTRO_scriptDir       - The scripts path
	
	TTRO_noCpus          - The number of detected cores
	TTRO_noParallelCases - The max number of parallel executed cases. If set to 1 all cases are executed back-to-back
	TTRO_treads          - The number of threads to be used during test case execution. Is set to 1 if parallel test case
	                       execution is enabled. Is set to \$TTRO_noCpus if back-to-back test case execution is enabled.
	TTRO_reference       - The reference will be printed
	TTRO_noStart         - This property is provided with value "true" if the --no-start command line option is used. It is empty otherwise
	TTRO_noStop          - This  property is provided with value "true" if the --no-stop command line option is used. It is empty otherwise
	TTPN_link            - This  property is provided with value "true" if the --link command line option is used. It is empty otherwise
	TTRO_noPreps         - This property is provided with value "true" if the --no-start command line option is used. It is empty otherwise
	                       If the property is true no Test Collection preparation is called
	TTRO_noPrepsSuite    - This property is provided with value "true" if the --no-start command line option is used. It is empty otherwise
	                       If the property is true no Test Suite preparation is called
	TTRO_noPrepsCase     - This property is not provided.
	                       If the property is true no Test Case preparation is called
	TTRO_noFins          - This property is provided with value "true" if the --no-stop command line option is used. It is empty otherwise
	                       If the property is true no Test Collection finalization is called
	TTRO_noFinsSuite     - This property is provided with value "true" if the --no-stop command line option is used. It is empty otherwise
	                       If the property is true no Test Suite finalization is called
	TTRO_noFinsCase      - This property is not provided.
	                       If the property is true no Test Case finalization is called


	Special Script Execution options
	===============================
	To maintain the correctness of the test execution all scripts are executed with special options set:
	
	errexit: Exit immediately if a pipeline (which may consist of a single simple command),  a subshell command enclosed 
	in parentheses, or one of the commands executed as part of a command  list  enclosed  by  braces exits with a non-zero 
	status.
	The shell does not exit if the command that fails is part of the command list immediately following a while or until keyword, 
	part of the test following the if or elif reserved words, part of any command executed in a && or || list except the 
	command  following the final && or ||, any command in a pipeline but the last, or if the command's return value is 
	being inverted with !.
	
	pipefail: If  set, the return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero 
	status, or zero if all commands in the pipeline exit successfully.
	
	posix:  Change the behavior of bash where the default operation differs from the POSIX standard to match the standard.
	
	nounset: Treat unset variables and parameters other than the special parameters "@" and "*" as an error when performing 
	parameter expansion. If expansion is attempted on an unset variable or parameter, the shell prints an error message, 
	and exits with a non-zero status.
	
	nullglob: bash allows patterns which match no files to expand to a null string, rather than themselves.
	
	globstar: The pattern ** used in a pathname expansion context will match all files and zero or more directories and 
	subdirectories. If the pattern is followed by a /, only directories and subdirectories match


	Sequence Control
	================
	The Test Collection, each Test Suite variant and each Test Case variant are executed in an own environment. 
	The global variables and properties (TT.. variables) are inherited from Test Collection to Suite and to Case.
	
	The test execution is done in the following order:
	
	- Scan input directory and collect all test suites and cases to execute
	- start test collection
	- set properties and variables from command line
	- evaluate description section of Test Collection
	- source Test Collection file - executes all script code of the main body
	- execute all test collection preparation steps
	- loop over all Suites
	    - read variants from Suite file
	    - loop over all Suite variants
	        - evaluate description section of Test Suite
	        - source Test Collection file - executes all script code of the main body
	        - source Test Suite file      - executes all script code of the main body
	        - read variants from all Case files and prepare the list of all Test Case variants
	        - execute all test Suite preparation steps
	        - loop over all test cases - execute n cases parallel
	            - evaluate description section of Test Case
	            - source Test Collection file - executes all script code of the main body
	            - source Test Suite file      - executes all script code of the main body
	            - source Test Case file       - executes all script code of the main body
	            - execute all test Case preparation steps
	            - execute all test steps
	            - execute all test finalization steps
	            - print test case result
	        - end loop over all test cases - execute n cases parallel
	        - execute all test Suite finalization steps
	    - end loop over all Suite variants
	- end loop over all Suites
	- execute all test collection finalization steps
	- print result
	
	
	EOF
}