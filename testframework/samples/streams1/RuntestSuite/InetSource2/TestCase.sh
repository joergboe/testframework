# Translation compile test for InetSource

testPrep='copyOnly'
#testStep="TT_mainComposite='Main' compile submitJob myCheckJobFile"
function testStep {
	compile; submitJob; myCheckJobFile;
}

function myCheckJobFile {
	if [[ -e $TT_jobFile ]]; then
		echo -n "$FUNCNAME jobno is "
		cat "$TT_jobFile"
		return 0
	else
		failureExit
	fi
}
