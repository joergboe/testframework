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

