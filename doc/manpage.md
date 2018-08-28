
# runTTF 

The runTTF script is a framework for the control of test case execution.
The execution of test case/suite variants and the parallel execution is inherently supported.

More docs can be found here:
* [Reference for utility scripts](utils.txt)
* [Reference for streams utility scripts](streamsutils.txt)

## Test Cases, Test Suites and Test Collections
A test case is comprised of a directory with the main test case file with name: 'TestCase.sh' and other necessary artifacts
which are necessary for the test execution.
The name of a test case is the relative path from the containing entity to the main test case file.
The test case file contains the necessary definitions and the script code to execute the test.

A test suite is a collection of test cases, test suites and artifacts to prepare and finalize the execution of the suite.
The directory sub tree of the test suite may have an arbitrary depth.
A test suite is defined through a directory with the main suite file with name: 'TestSuite.sh'
The name of a test suite is the relative path from the containing entity to the main test suite file.
The test suite file contains the necessary definitions and the script code to execute the test suite preparation 
and suite finalization. The test suite file may contain common suite code (you must register functions, that are to be
used in sub-suites or test cases).
Test cases may exists without a suite.

One or more test suites and/or test cases form a Test Collection. A Test Collection is defined through a directory. 
A test collection may execute common code (functions must be registered).
A test collection may have a test properties file TestProperties.sh which should contain the definition of variables and 
properties which may be variable in different test environments.
The name of the test properties file may be changed by a command line parameter (--properties).

Common used script code may be placed in separate script files, which must be registered during test run (--tools command line option).

Test cases must not be nested in other test case directories.
All path names of test cases and suites must not contain any white space characters.

Test Cases and Test Suites may define variants. This allows the repeated execution of the artifact with changed
parameter sets.


## Execution Environment
The test framework starts with the analysis of the input directory (directory list) (option -i|--directory).

If no list with case wildcards is given as command line parameter, all found test suites and test cases which are not marked as 'skipped'
property are executed. In this case all suites (also empty suites) are executed.

If a cases list is given from the command line, all test cases with match the cases list are executed (pattern match). 
Additionally all suites are executed, which are necessary to reatch the cases with a pattern match. In this mode suites that 
do not include an active case are not executed.

There is always an enveloping 'dummy' suite, which is always executed.

All generated artifacts are stored in a sub-directory of the workdir (option -w|--workdir) for further analysis.
The sub-directory name is composed of the actual date and time when the test case execution starts.

A summary is printed after test case execution.


## Test Case File 'TestCase.sh' and Test Suite File 'TestSuite.sh'
These files have in general two sections: The preamble and a script code section. Both sections may be empty.

The preamble defines variables which are necessary before execution of appropriate artifacts starts.
A preamble statement starts with the character sequence '#--'. A preamble line may be continued after a single
\ before nl. The continuation line must start also with sequence '#--'

The script code section is a bash script. In the script section, you can define required code for the initialization
and the custom functions for the test preparation, for the test step execution and the test finalization. 

In general all collections, suites and test cases are executed in 4 phases:
- Initialization
- Preparation
- Execution
- Finalization

The script code of the main body is executed during initialization of the Test Suite or of the Test Case.

In the preparation phase of Test Case or Suite, functions that are defined through the optional variables and functions:
- TTRO_prepsSuite or TTRO_prepsCase,
- PREPS
- function testPreparation
are executed sequentially.
The variables TTRO_prepsSuite, TTRO_prepsCase have global meaning. They may be defined at global level and are executed
during the the execution of the appropriate artifact. The variable PREPS and the function testPreparation have local meaning and are
defined in the appropriate script file.

During execution phase of the Test Collection the framework iterates recursively though all defined Test Suites.

During execution phase of the Test Suite the framework iterates though all Test Cases and then all defined Sub-Suites are executed. 
Test Case execution may use parallel execution. Test Suites are always sequentially executed.

During execution phase of the Test Case the framework iterates sequentially though all Test Cases Steps.
Test steps are defined:
- The global variable TTRO_stepsCase
- the test case step local variable STEPS
- the local function testStep

In the finalization phase of the artifact, functions that are defined through the optional variables and functions:
- TTRO_finsSuite, TTRO_finsCase,
- FINS
- function testFinalization
are executed sequentially.
The variables TTRO_finsSuite and TTRO_finsCase have global meaning. They may be defined at global level and are executed
during the the execution of the appropriate artifact. The variable FINS and the function testFinalization have local meaning and are
defined in the appropriate script file.

If the variables TTPR_noPrepsSuite TTPR_noPrepsCase TTPR_noFinsSuite TTPR_noFinsCase are set to a 
non empty value the preparation and the finalization of the appropriate artifact is supressed.


## Test Property File TestProperties.sh
This file may contain global property and variable definitions. This file should no contain script code. This file is intended 
to store stuff which may change when the test collection is executed in different environments. The default name of this 
file is 'TestProperties.sh' and it is expected in the Test collection directory. An alternative file name may be assigned with 
command line parameter --properties or the environment TTRO_propertyFiles is evaluated. The command line option overwrites environment and 
the default. The properties file is a bash script.


## Test Tools
If your test collection requires special functions, you must import the appropriate script module in the initialization part of a 
Test Suite or Test Case file. The test Tools Script may define user defined variables, properties and functions. The defined 
functions in a Tools Script must be exported like:

export -f fname

The defined tool artifacs are available in nested Suites and nested cases.
Once a function has been defined, it can not be re-defined in a nested element.

Especially the streamsutils.sh must be imported at the beginning of the main body of the outermost Test Suite file:

import "$TTRO_scriptDir/streamsutils.sh"\n

An alternative way to import a Test Tools module is the command line options --tools, which imports one Tools script.
Or you may define a colon separated list of Test Tools files in variable TTRO_tools.


## Test File Preamble
The definition of the variables and properties must have the form:
#--name=value
No spaces are allowed between name '=' and value. The assignement requires the same quoting as a reqular bash assignement.
The assignment can use a continuation line if the line ends with an escaped newline character (backlslash before newline)
The continuation line must also start with #--
The preamble may define the variants of the test artifact and in case of a test case, the timeout value for the test case.

## Test Collection, Test Case and Test Suite variants
The variants of cases, suites and collections are defined in the preamble of the 'TestCase.sh' or the 'TestSuite.sh' file.
The appropriate file must have either no variant variable, a variantCount variable or a variantList variable.

The variantCount must be in the form:
#--variantCount=number

The variantList must be a space separated list of identifiers:
#--variantList='space separated list of variant identifiers'
An identifier must be composed from following characters : 0-9a-zA-Z-_
No other characters are allowd in variant list identifiers.

## Test Case timeouts
Each test case can define an individual timeout variable. When the timeout is reached for an test case, 
the job is killed with SIGTERM (15). If the job still runs after additional time (TTPR_additionalTime), 
the job is killed with SIGKILL (9).
If there is no individual timeout defined, the default values TTPR_timeout is used.
If there is no individual timeout and no property TTPR_timeout, the test case times out after 120 seconds.
If there is no property TTPR_additionalTime, the vaue 45 is used.


## Reserved Varable Name Ranges
Variables used for the framework have special prefixes.

- TTTT_ : Varaible names starting with TTTT_ are reserved for testframework usage. These variables are not exported. Do not use those 
names in test case/suite script usercode.
- TTXX_ : Global variables for internal usage. Do not use those names in test case/suite script usercode. (No automatic export)
- TT_   : Global r/w variable
- TTRO_ : Global r/o variable
- TTPR_ : Global property (empty value defines this property)
- TTPRN_: Global property (empty value may be overwritten)

## Test Framework Variables and Properties
Variables with the prefix TT_, TTRO_, TTPR_ or TTPRN_ are treated as global definitions and they are exported from 
Test Collection to Test Suite and from Test Suite to Test Case.

In the script code section, variables and properties can be assigned with function setVar 'name' "value".

## Property Variables
Property variables are not changed once they have been defined. Re-definition of property variables will be ignored. 
An pure assignment to a property in a test suite/case script may cause a script failure. Use function setVar instead.
The name of a property must be prefixed with TTPR_ or TTPRN_

Empty values are considered a defined value for properties with prefix TTPR_ and can not be overwritten.
Empty values are considered a undefined value for properties with prefix TTPRN_ and can be overwritten.

NOTE: Prefer the TTPR_ version for varables which can have different values.
NOTE: The TTPRN_ version is used as switch which can be used only once to become true.


## Simple Global Variables and Global Read-only Variables
Global variables may be defined in the script code section of the test artifacts. 
Simple variables and can be re-written in suite- or test-case-script and must have the prefix TT_. 
Read-only variables can not be re-written once they have been defined and must have the prefix TTRO_. 
In script code use function setVar to define such a variable. To re-write a global variable (TT_) 
a plain assignment is sufficient. A re-write of an read-only variable will cause a script/test failure.



## Trueness and Falseness
Logical variables with the semantics of an boolean are considered 'true' if these variables are set to something different than 
the empty value (null). An empty (null) variable or an unset variable is considered 'false'. Care must be taken if a 
variable is unset. In general the usage of an unset variable will cause a script failure.
Use function 'isExisting' or 'isNotExisting' to avoid script aborts.

Some properties are designed that the existence of the property indicates the trueness.


## Accepted Environment
- TTRO_propertyFiles - A space separated list with property files which are sourced before the test collection execution starts.

## Debug and Verbose
The testframe may print verbose information and debug information or both. The verbosity may be enabled with command line options.
Additionally the verbosity can be controlled with existence of the properties:
- TTPRN_debug            - enables debug
- TTPRN_debugDisable     - disables debug (overrides TTPRN_debug)
- TTPRN_verbose          - enables verbosity
- TTPRN_verboseDisable   - disables verbosity (overrides TTPRN_verbose)

NOTE: The check if an existing variable is empty or not is much faster then the check against existance of an variable. Therefore 
we use here the empty value an consider it as unset property.

## Variables Used
- TTPRN_skip            - Skip-Switch: if this varaible not empty, the execution of the actual Test Case variant or Test Suite variant is skipped.
                          This variable is set by function setSkip
- TTPRN_skipIgnore      - if this varaible not empty, the skip variable is ignored.

- STEPS                 - The space separated list or an array of test step commands with local meaning. If one command returns an failure (return code != 0), 
                          the test execution is stopped
- TTRO_stepsCase        - This variable is designed to store a space separated list of test step commands.
                          and the test case variant is considered an error. When the execution of all test commands return success the 
                          test case variant is considered a success.
                        
- TTRO_prepsSuite       - This variable stores the list of test suite preparation commands. If one command returns an failure (return code != 0), 
                          the test execution ot the suite is stopped.
- TTRO_prepsCase        - The space separated list of test case preparation commands. If one command returns an failure (return code != 0), 
                          the test execution is stopped and the test is considered an error.
- PREPS                 - The space separated list or an array of test preparation commands with local meaning.

- TTRO_finsSuite        - This variables stores the list of test suite finalization commands. If one command returns an failure (return code != 0), 
                          the error is logged and the execution is stopped
- TTRO_finsCase         - This variable is designed to store the list of test case finalization commands. If one command returns an failure (return code != 0), 
                          the error is logged and the execution is stopped. The result of the case is not affected.
- FINS                  - The space separated list or an array of test finalization commands.
                         
- TTPR_timeout          - The default test case timeout in seconds. default is 120 sec. This variable must be defined in the 
                          description section of test case file or anywhere in the Test Suite or Test Property file. A definition 
                          in the script section of a Test Case has no effect.
- TTPR_additionalTime    - The extra wait time after the test case time out. If the test case does not end after this 
                          time a SIGKILL is issued and the test case is stopped. The default is 45 sec. This variable 
                          must be defined in the description section of test case file or anywhere in the Test Suite or Test Property file. 
                          A definition in the script section of a Test Case has no effect.


## Variables Provided
- TTRO_workDirMain     - The main output directory
- TTRO_workDir         - The output directory of the collection variant
- TTRO_workDirSuite    - The output directory of the suite
- TTRO_workDirCase     - The output directory of the case
- TTRO_inputDir        - The input directory
- TTRO_inputDirSuite   - The input directory of the suite
- TTRO_inputDirCase    - The input directory of the case
- TTRO_collection      - The name of the Test Collection (Last path element of the input dir)
- TTRO_suite           - The suite name
- TTRO_case            - The case name
- TTRO_variantSuite    - The variant of the suite
- TTRO_variantCase     - The variant of the case
- TTRO_scriptDir       - The scripts path

- TTRO_noCpus          - The number of detected cores
- TTRO_noParallelCases - The max number of parallel executed cases. If set to 1 all cases are executed back-to-back
- TTRO_treads          - The number of threads to be used during test case execution. Is set to 1 if parallel test case
                         execution is enabled. Is set to $TTRO_noCpus if back-to-back test case execution is enabled.
- TTPR_clean           - 
- TTRO_reference       - The reference will be printed
- TTPR_noStart         - This property is provided with value "true" if the --no-start command line option is used. It is empty otherwise
- TTPR_noStop          - This  property is provided with value "true" if the --no-stop command line option is used. It is empty otherwise
- TTPRN_link           - This  property is provided with value "true" if the --link command line option is used. It is empty otherwise
- TTPR_noPrepsSuite    - This property is provided with value "true" if the --no-start command line option is used. If the property is true no Test Suite preparation is called
- TTPR_noPrepsCase     - This property is not provided. If the property is true no Test Case preparation is called
- TTPR_noFinsSuite     - This property is provided with value "true" if the --no-stop command line option is used. If the property is true no Test Suite finalization is called
- TTPR_noFinsCase      - This property is not provided. If the property is true no Test Case finalization is called
                         
- TTTT_categoryArray   - The indexed array with the categories of the current Case/Suite
- TTTT_runCategoryPatternArray - The indexed array with the run-category patterns of the current test run
- TTTT_failureOccurred - The failure condition in test case execution
- TTTT_result          - Used in some functions to return a result code
- TTTT_xxxx            - More variables used in utils


## Special Script Execution options
To maintain the correctness of the test execution all scripts are executed with special options set:

errexit: Exit immediately if a pipeline (which may consist of a single simple command),  a sub-shell command enclosed 
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

globstar: The pattern ** used in a path-name expansion context will match all files and zero or more directories and 
sub-directories. If the pattern is followed by a /, only directories and sub-directories match

If a test case requires the execution of a command that fails intentionally, you should use one of the functions:
echoExecuteAndIntercept          - echo command and parameters; execute command guarded; return value in TTTT_result
echoExecuteAndIntercept2,      
echoExecuteInterceptAndSuccess,  - echo command and parameters; execute command guarded; return value in TTTT_result;
                                   expect cmd success set failure otherwise
echoExecuteInterceptAndError,    - echo command and parameters; execute command guarded; return value in TTTT_result;
                                   expect cmd error set failure otherwise
executeAndLog                    - echo command and parameters; execute command guarded; return value in TTTT_result;
                                 - save command output into file
executeLogAndSuccess             - echo command and parameters; execute command guarded; return value in TTTT_result;
                                   save command output into file; expect cmd success set failure otherwise
executeLogAndError               - echo command and parameters; execute command guarded; return value in TTTT_result;
                                   save command output into file; expect cmd error set failure otherwise
compileAndIntercept,
compileInterceptAndSuccess,
compileInterceptAndError,
submitJobAndIntercept.


## Test Case Result Failures and Errors
To signal an failure in a test case set the failure condition with function setFailure. This prevents further
test step functions from execution.

If a test case function is returns a non zero return code the case is counted as error.

To signal the success of a test case just leave the function with success 'return 0'.

The test frame environment atempts to execute the test finalization functions in case of error and in case of failure.

## Skip Test Cases - Category Control
A test case or a test suite is skipped if the function setSkip is called during initialization phase of the artifact. 
This function sets the property TTPRN_skip with the supplied non-empty reason string.

A test case is skipped if the property TTPRN_skip is defined and not empty. This property may be set :
- In the initialization or preparation phase of an test suite variant - this disables all cases of this suite variant
- In the initialization phase of an test case (variant) - this disables only one case variant

Alternatively the existence of an file SKIP in the Test Case/Suite directory inhibits the execution of all variants of the Case/Suite.

The function 'setCategory' defines the categories of a Test Case or Test Suite.
If the function 'setCategory' is not called during Case initialization the Case has the default category 'default'.
If the function 'setCategory' is not called during Suite initialization the Suite has no category.
If the function 'setCategory' is called with an empty parameter list, all catagories are cleaned.
The categories are checked before the Case- or Suite- preparation is executed.
The run-categories of the a test run can be defined with command line parameter -c|--category VALUE. The run-categories 
are considered to be patterns.
If one of the run-category pattern matches any of the categories of the artifact, the Case/Suite is executed. Otherwise it is skipped.
A test Case or Suite without a defined categorie is always executed independently from the run-categories.
If no run-category pattern is entered, all Cases and Suite are executed, regardless of the defined categories.
If the run-caegory 'default' is specified, all Cases and Suites are executed that have no explicit category set.


## Sequence Control
The Test Collection, each Test Suite variant and each Test Case variant are executed in an own environment. 
The global variables and properties (TT.. variables) are inherited from Test Collection to Suite and to Case.

The test execution is done in the following order:

The Test Collection:

- Scan input directory and collect all test suites and cases to execute
- Set programm defined props/vars
- Set properties and variables defined with command line parameter -D..
- Source properties file if required - set props and vars
- Source all defined tools scripts
- Execute root suite in inherited environment
- print result

The Test Suite:

- Source all defined tools scripts
- Source Test Suite file - executes initialization in the main body of the script / set props and vars
- Check is suite is to be skipped and end suite execution if required
- Execute all Test Suite preparation steps if required
- Evaluate all Test Collection preambles - determine all case variants of suite
- Loop over all test cases variants - execute n cases parallel
  - Start Test Case Variant in inherited environment
- End loop over all test cases
- Loop over all sub-suites
  - Evaluate Test Suite preamble - determine variants
  - Loop over all suite variants
    - Start sub-suite Variant in inherited environment
  - End loop over all suite variants
- End loop over all sub-suites
- Execute all Test Suite finalization steps if required
- print suite result

The Test Case

- Source all defined tools scripts
- Source Test Case file - executes initialization in the main body of the script / set props and vars
- Check is cuite is to be skipped and end cuite execution if required
- Execute all Test Case preparation steps if required
- Execute all test steps
- Execute all test finalization steps
- print Test Case result
