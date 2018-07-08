##-----------the required tools ---------------------
import "$TTRO_scriptDir/streamsutils.sh"

PREPS='myPrompt'

function myPrompt {
	echo "This test collection should produce one expected failure"
	echo 'In test case:'
	echo 'Collection::RuntestSuite::InetSource2:submitJobLogAndIntercept'
	 promptYesNo
}