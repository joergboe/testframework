
function testPreparation {
	echo "*********************************************************"
	echo " this suite tests helper functions and expected result is"
	echo "cases  executed=172 failures=22 errors=31 skipped=0"
	echo "*********************************************************"
	echo
	echo "Expected failures are:"
	echo
	echo "**** CASE_FAILURE List : ****"
echo "#suite[:variant][::suite[:variant]..]::case[:variant]"
echo "Functions::echoAndExecute:falseCheck"
echo "Functions::echoExecuteAndIntercept2:expectSuccFails"
echo "Functions::echoExecuteAndIntercept2:expectErrorFails"
echo "Functions::echoExecuteAndIntercept2:simpleCommands27Fails"
echo "Functions::echoExecuteInterceptAndError:succ"
echo "Functions::echoExecuteInterceptAndError:simpleCommands1Succ"
echo "Functions::echoExecuteInterceptAndError:simpleCommands2Succ"
echo "Functions::echoExecuteInterceptAndSuccess:wrongCommand"
echo "Functions::echoExecuteInterceptAndSuccess:fails"
echo "Functions::echoExecuteInterceptAndSuccess:simpleCommands27"
echo "Functions::executeLogAndError:succ"
echo "Functions::executeLogAndError:simpleCommands1Succ"
echo "Functions::executeLogAndError:simpleCommands2Succ"
echo "Functions::executeLogAndSuccess:wrongCommand"
echo "Functions::executeLogAndSuccess:fails"
echo "Functions::executeLogAndSuccess:simpleCommands27"
echo "Functions::findTokenInDirs:checkTokenIsInDirsFail: Token ERROXR was not in one of these directories:..."
echo "Functions::findTokenInDirs:scheckTokenIsNotInDirsFail: Token ERROR was found in one of these directories:..."
echo "Functions::findTokenInFiles:checkTokenIsInFilesFailure: Token ERROXR was not in one of these files:..."
echo "Functions::findTokenInFiles:checkTokenIsNotInFilesFailure: Token ERROR was not in one of these files:..."
echo "Functions::linewisePatternMatch:matchSuccessFail: Not enough matches: 'linewisePatternMatchInterceptAndSuccess ...'"
echo "Functions::linewisePatternMatch:matchErrorFail: Match found: 'linewisePatternMatchInterceptAndError ...'"

echo
echo "**** CASE_ERROR List : ****"
echo "#suite[:variant][::suite[:variant]..]::case[:variant]"
echo "Functions::arrayInsert:pasteEnd"
echo "Functions::echoAndExecute:noParm"
echo "Functions::echoAndExecute:emptyCommand"
echo "Functions::echoAndExecute:false"
echo "Functions::echoAndExecute:emptyCommandCheck"
echo "Functions::echoAndExecute:noParmCheck"
echo "Functions::echoExecuteAndIntercept:noParm"
echo "Functions::echoExecuteAndIntercept:emptyCommand"
echo "Functions::echoExecuteAndIntercept2:noParm"
echo "Functions::echoExecuteAndIntercept2:wrongCode"
echo "Functions::echoExecuteAndIntercept2:emptyCommand"
echo "Functions::echoExecuteInterceptAndError:noParm"
echo "Functions::echoExecuteInterceptAndError:emptyCommand"
echo "Functions::echoExecuteInterceptAndSuccess:noParm"
echo "Functions::echoExecuteInterceptAndSuccess:emptyCommand"
echo "Functions::executeAndLog:noParm"
echo "Functions::executeAndLog:emptyCommand"
echo "Functions::executeLogAndError:noParm"
echo "Functions::executeLogAndError:emptyCommand"
echo "Functions::executeLogAndSuccess:noParm"
echo "Functions::executeLogAndSuccess:emptyCommand"
echo "Functions::findTokenInDirs:noDirsError"
echo "Functions::findTokenInDirs:wrongDirname"
echo "Functions::findTokenInDirs:fileNotReadable"
echo "Functions::findTokenInFiles:noFilesError"
echo "Functions::findTokenInFiles:wrongFilename"
echo "Functions::isExisting:noArgumentIs"
echo "Functions::isExisting:noArgumentNot"
echo "Functions::isFalse:varNotExists"
echo "Functions::isTrue:varNotExists"
echo "Functions::setVar::setVar:2"

	promptYesNo
}
