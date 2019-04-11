#--variantList='matchAllOk matchAllOk2 matchAllNotOk matchOneOk matchOneNotOk matchNoFile matchIntercept1 matchIntercept2 matchSuccess matchError matchSuccessFail matchErrorFail matchArray'

STEPS='myTest'

myTest() {
  case $TTRO_variantCase in
    matchAllOk)
      if linewisePatternMatch "$TTRO_inputDirCase/file" 'true' "${arrayMatchAllOk[@]}"; then
        echo "Test success"
      else
        setFailure "Function failure"
      fi;;
    matchAllOk2)
      if linewisePatternMatch "$TTRO_inputDirCase/file" 'true' "${arrayMatchAllOk2[@]}"; then
        echo "Test success"
      else
        setFailure "Function failure"
      fi;;
    matchAllNotOk)
      if linewisePatternMatch "$TTRO_inputDirCase/file" 'true' "${arrayMatchAllNotOk[@]}"; then
        setFailure "Function failure"
      else
        echo "Test success"
      fi;;
    matchOneOk)
      if linewisePatternMatch "$TTRO_inputDirCase/file" '' "${arrayMatchOneOk[@]}"; then
        echo "Test success"
      else
        setFailure "Function failure"
      fi;;
    matchOneNotOk)
      if linewisePatternMatch "$TTRO_inputDirCase/file" '' "${arrayMatchOneNotOk[@]}"; then
        setFailure "Function failure"
      else
        echo "Test success"
      fi;;
    matchNoFile)
      if linewisePatternMatch "$TTRO_inputDirCase/filex" '' "${arrayMatchOneNotOk[@]}"; then
        setFailure "Function failure"
      else
        echo "Test success"
      fi;;
    matchIntercept1)
      linewisePatternMatchAndIntercept "$TTRO_inputDirCase/file" 'true' "${arrayMatchAllOk[@]}"
      echo "\$TTTT_result=$TTTT_result"
      if [[ $TTTT_result -eq 0 ]]; then
        echo "Test success"
      else
        setFailure "Function failure"
      fi;;
    matchIntercept2)
      linewisePatternMatchAndIntercept "$TTRO_inputDirCase/file" 'true' "${arrayMatchAllNotOk[@]}"
      echo "\$TTTT_result=$TTTT_result"
      if [[ $TTTT_result -ne 0 ]]; then
        echo "Test success"
      else
        setFailure "Function failure"
      fi;;
    matchSuccess)
      linewisePatternMatchInterceptAndSuccess "$TTRO_inputDirCase/file" 'true' "${arrayMatchAllOk[@]}"
      echo "Test end";;
    matchError)
      linewisePatternMatchInterceptAndError "$TTRO_inputDirCase/file" 'true' "${arrayMatchAllNotOk[@]}"
      echo "Test end";;
    matchSuccessFail)
      linewisePatternMatchInterceptAndSuccess "$TTRO_inputDirCase/file" 'true' "${arrayMatchAllNotOk[@]}"
      echo "Test end";;
    matchErrorFail)
      linewisePatternMatchInterceptAndError "$TTRO_inputDirCase/file" 'true' "${arrayMatchAllOk[@]}"
      echo "Test end";;
    matchArray)
      TTTT_patternList=(
        "A test case is comprised of a directory with the main test case file with name: 'TestCase.sh' and other necessary artifacts"
        'which are necessary for the test execution.'
        'The name of a test case is the relative path from the containing entity to the main test case file.'
        'The test case file contains the necessary definitions and the script code to execute the test.'
      )
      linewisePatternMatchArray "$TTRO_inputDirCase/file" 'true'
      echo "Test end";;
    *)
      printErrorAndExit "Wrong variant '$TTRO_variantCase'" $errRt;;
  esac
}

arrayMatchAllOk=(
"A test case is comprised of a directory with the main test case file with name: 'TestCase.sh' and other necessary artifacts"
"which are necessary for the test execution."
"The name of a test case is the relative path from the containing entity to the main test case file."
"The test case file contains the necessary definitions and the script code to execute the test."
"A test suite is a collection of test cases, test suites and artifacts to prepare and finalize the execution of the suite."
"The directory sub tree of the test suite may have an arbitrary depth."
"A test suite is defined through a directory with the main suite file with name: 'TestSuite.sh'"
"The name of a test suite is the relative path from the containing entity to the main test suite file."
)

arrayMatchAllOk2=(
"A test case is *"
"which are*"
"*name*"
"The test case file contains the necessary definitions and the script code to execute the test."
"*suite is a collection of test cases, test suites and artifacts to prepare and finalize the execution of the suite."
"*directory sub tree of the test suite may have an arbitrary depth."
"A test suite is defined through a directory with the main suite file with name: 'TestSuite.sh'"
"The name of a test suite is the relative path from the containing entity to the main test suite file."
)

arrayMatchAllNotOk=(
"A test case is *"
"whichxare*"
"*name*"
"Thextest case file contains the necessary definitions and the script code to execute the test."
"*suite is a collection of test cases, test suites and artifacts to prepare and finalize the execution of the suite."
"*directory sub tree of the test suite may have an arbitrary depth."
"A test suite is defined through a directory with the main suite file with name: 'TestSuite.sh'"
"The name of a test suite is the relative path from the containing entity to the main test suite file."
)

arrayMatchOneOk=(
"lll1 *"
"llll2"
"which are*"
"llll3"
"*name*"
"*llll4"
"*lllll5"
"*llllllls"
)

arrayMatchOneNotOk=(
"lll1 *"
"llll2"
"llll3"
"*llll4"
"*lllll5"
"*llllllls"
)
