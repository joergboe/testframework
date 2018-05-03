# Translation compile test for InetSource

PREPS='copyOnly'
#testStep="TT_mainComposite='Main' compile submitJob myCheckJobFile"
function testStep {
	splCompile; submitJob; myCheckJobFile;
}

function myCheckJobFile {
	if [[ -e $TT_jobFile ]]; then
		echo -n "$FUNCNAME jobno is "
		cat "$TT_jobFile"
		return 0
	else
		setFailure "No job file exists $TT_jobFile"
	fi
}
