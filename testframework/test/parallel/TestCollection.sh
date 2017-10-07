#--TTRO_preps:="testPreparation"
#--TTRO_fins:=testFinalization

registerTool "$TTRO_scriptDir/testutils.sh"

function testPreparation {
	echo "$FUNCNAME : Running global test preparation"
	useCpu 4 1 ""
}
function testFinalization {
	echo "$FUNCNAME : Running test shut down"
	useCpu 4 1 ""
}
