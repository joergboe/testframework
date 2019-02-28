# testframework

The test script is a framework for the control of test case execution.

To learn more start with execution of help and man:

./bin/runTTF --help

and

./bin/runTTF --man

In directory samples you can see the Test Collection ANewTest, which is a sample for a basic Test Collection

# Installation

The release package is a self extracting script. Execute it and follow the instructions. You can install the tool into
an arbitrary palace.
If you want to install the tool into a system directory execute the installation script as root.
It is recommended qto enter the location of the test framework into your PATH like:

export PATH="<location of test framework>/bin:$PATH"

Whats new:
----------
Version 1.0.2
- correction in streams initialization

Version 1.0.1
- corrections in selftest


Version 1.0.0:
- re-name TestProperties to TestProperties.sh
- Removed propertie section in preamble, all properties moved to script section
- Preamble now supports only variantList, variantCount and timeout
- Preamble requires now quoting (for lists)
- Check whether variantCount and timeout are digits
- New test steps / pres / fins invocation local space separated list STEPS/PREPS/FINS
- New test steps / pres / fins invocation local array STEPS/PREPS/FINS possible
- New test steps / pres / fins invocation local functions testStep, testPreparation, testFinalization
- Global space separated lists steps / pres / fins invocation re-named:
    TTRO_prepsCase TTRO_prepsSuite TTRO_preps
    TTRO_stepsCase
    TTRO_finsCase TTRO_finsSuite TTRO_fins
- Improved handling and display in case of erroros in suite/collection initialization and preparation
- All function calls for collection/suite/case preparation and steps and finalization are now unchecked called
  to improve failure propagation
- Collections variant support
- TstCollection.sh and TestSuite.sh are now only once sourced in collection and suite context
- TTRO_extraTime renamed to TTP_additionalTime
- New utis functions isArray, isFunction, arrayHasKey, isExistingAndTrue, isTrue, isFalse
- Re-named properties TTRO_noStart -> TTPN_..
- Handle debug and verbose as propertie
- Re-names TTRO_caseVariant -> TTRO_variantCase TTRO_suiteVariant -> TTRO_variantSuite


Version 0.2.0:
- Dummy Suite support: Test cases can be defined without suite context.
- Test collection now requires a TestCollection.sh file and the TestProperties file is now optional
- Installer
- New global initialization in streamsutils
- Use variables for sab file main composite ..
- New test cases
- Streams sample

Version 2.0.0:
- Remove concept of TestCollection.sh
- Introductio of nested Test Suites

Version 2.1.0:
- New feature: Browser is started after test collection execution and execution index is displayed in browser

Version 2.2.0:
- Simple initialization of test tools. Test tools are now imported one at the beginning of tests. Test tools function must be exported.

Version 2.3.0:
- Changed reference display handling: The parameter --ref requires now the name of the module to display.
- Changed prefixes TTP_ -> TTPR and TTPN_ -> TTPRN_
- new function setFailure ti signal failure reason in test case
- new function skip to skip case and suite

Version 2.4.0
- New Feature: Category Control

Version 2.5.0
- New functions: executeAndLog, executeLogAndSuccess, executeLogAndError
- New functions: linewisePatternMatchAndIntercept, linewisePatternMatchInterceptAndSuccess, linewisePatternMatchInterceptAndError

Version 2.6.0:
- New function names splCompile, splCompileAndLog, splCompileAndIntercept, splCompileInterceptAndSuccess and splCompileInterceptAndError
- New variable TT_dataDir
- New functions waitForFileToAppear, waitForFin
- New functions checkJobNo
- New variables TT_waitForFileName, TT_waitForFileInterval, TTTT-jobno
- New spl utility toolkit streamsx.testframe with FileSink1
- New directory structure for installation target now we have <version>/bin <version>/samples and <version>/streamsx.testframe

Version 2.6.1:
- New function
- com.ibm.streamsx.testframe::FileSinke 1 : has new parameter singleTupleFiles with default true

Version 2.6.2:
- New function getLineCount
- Error corrections
- Improvementes in builReleasePackage.sh

Version 2.7.0:
- New functions to get streams job health: jobHealthyVariable, jobHealthy, jobHealthyAndIntercept,
- New function to wait for final file and check health: waitForFinAndHealth
- New utils function: trim, getSystemLoad, getSystemLoad100
- Print the elapsed time

Version 2.7.2:
- Some fixes in category handling

Version 2.7.3:
- Simplified preambl handling: Now quote like a reqular assignement

Version 2.9.0:
- New function copyAndMorph now works with expressions like:
	^[[:space:]]*//<varid1:varid2..> are effective if the argument $3 equal one of the varid1, or varid2..
	^[[:space:]]*//<!varid1:varid2> are not effective if the argument $3 equal one of the varid1, or varid2..
	and is able to work with lists of version ids in one line
- Better logging of job and pid specification
- Introduced special report for suites for automated tests
- Check variant id for valid characters [a-zA-Z0-0_]
- New option setVar xtraprint
- Make domain now with checkpointRepository and fileStoragePath

Version 3.0.0:
- new command line option --summary
- Corrections in streams utils: better jobno handling; submitjob may have optional submission time params
- New command line parameter -s|--sequential - Sequential test execution and option -j with new semantics
- Per default a suite has no category
- Function setFailure with better state check
- New functions: setSkip, isSkip. Print reason for skipped cases and failures
- correction in props TTPRN and added property test
- Print skip reason and failure reason to index
- Suites with error cases are now in read in html
- Allow preambl lienes to be continued
- Add command line option --clean to enable clean start of streams instances
- Write protect used utils and other functions
- correct identifier character class of variants to 0-9a-zA-Z-_
- Produce global SUMMARY.txt file
- Allow preambl lines to be continued
- Better jobid control. Now re-used jobids should not cause errors
- Use other formatting in web index
- Add elapsed time and add result to special report
- New replacement in New function morphFile:
	patterns like <#$varname#> are replaced with the expansion of $varname

Version 3.0.1:
- Add version number to final summary
- Correction for more then 9 arguments

Version 3.1.0:
- Use environment variable TTRO_propertyFiles to control Property files
- Adapt ..._summary file to junit output format
- Correct doc for return values
- Print result summary in order: executed, failed, errors, skipped

Version 3.1.2:
- Correct TTTT_state variable

Version 3.1.3:
- Workaround for lang setting in jobs command for bash 4.1.2

Version 3.2.0:
- New command line option --load-reduce
- Use variables TTPR_noStartxxx, TTPR_noStopxxx instead of TTPRN_ variables
- New functions cleanUpInstAndDomainAtStop and cleanUpInstAndDomainAtStart
- Evaluate skip attributes if a cases list is given as command line parameter
- Add skipped cases in special summary file

Version 3.3.0:
- Print no warning if cancelJob is used in finalization phase and empty job variable
- Correction spl compile when TT_toolkitPath is empty or not existent
- Better function parameter check in utils function setFailure: must not be called with an empty argument
- New utils functions : checkAllFilesExist, checkLineCount and checkAllFilesEqual
- Enhancements in toolkit FileSink1
- Add spldocs of spl toolkit
- New streamsutils functions cancelJobAndLogVariable and cancelJobAndLogVariable

Version 3.3.1:
- Allow compile time parameters in function splCompile

Version 3.4.0:
- Function copyAndMorph: vartiant identifieres can now be a pattern

Version 3.4.1:
- Remove unnecessary echos

Version 3.5.0:
- Timeout in test case preambl is not used if the value is lesser than the timeout in property TTPR_timeout

Version 3.5.1:
- Correct timer properties handling for nested suites

Version 3.5.2:
- Preamble continuation lines must not remove leading whitespaces
- Allow tool imports in property file
- Remove deprecated variables in Streams1 sample

Version 3.6.0:
- Improved error handling in case of duplicate case variant or suite variant
- New utils functions findTokenInFiles, findTokenInDirs, checkTokenIsInFiles, checkTokenIsNotInFiles, checkTokenIsInDirs, checkTokenIsNotInDirs
- New streamsutil functions: getHostList, getHostListVariable, getJobLogDirs, getJobLogDirsVariable, checkLogsNoError
- Correction streamsutil: all TT_ variables set with function setVar to enable export

Version 3.6.1:
- New function checkLogsNoError2, Check if pe log files and pe stdouterr have no error Token ERROR

Version 3.7.0:
- Add command option --shell
- breakdown in browser pages
