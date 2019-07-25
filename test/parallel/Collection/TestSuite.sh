setVar 'TTRO_preps' "testPreparation"
setVar 'TTRO_fins' 'testFinalization'

import "$TTRO_scriptDir/testutils.sh"

function testPreparation {
	echo
	echo "In Suite 1 the cases 7, 11 and 12 should be terminated"
	echo
	echo "In Suite 2 cases 'Run1' (2 variants), 'Run3' (1 variant) and 'Run5' (2 variants)"
	echo "must be sequentially executed"
	echo
	promptYesNo
	echo "$FUNCNAME : Running global test preparation"
	useCpu 4 1 ""
}
function testFinalization {
	echo "$FUNCNAME : Running test shut down"
	useCpu 4 1 ""
}
