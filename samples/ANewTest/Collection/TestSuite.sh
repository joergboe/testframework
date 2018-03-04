#the intro
cat "$TTRO_inputDirSuite/../README.md"
promptYesNo

# Put here more fixed variables and properties
setVar 'TTPRN_myProperty2' "This is a sample property #2"

# Put here the immediate global test collection initialization steps
echo "********************************"
echo "global initialization steps"
echo "\$PATH=$PATH"
if isExisting STREAMS_INSTALL; then
	echo "Streams Environment is $STREAMS_INSTALL"
else
	echo "No Streams environment"
fi
echo "********************************"

#Global test collection preparation steps
preps=mySpecialPreparation

#Function definitions for test collections
function mySpecialPreparation {
	echo "**** $FUNCNAME ****"
	echo "TTPRN_myProperty= $TTPRN_myProperty"
	echo "TTPRN_myProperty2=$TTPRN_myProperty2"
}
#export -f mySpecialPreparation

function testFinalization {
	echo "**** $FUNCNAME ****"
	echo "TTPRN_myProperty=$TTPRN_myProperty"
	echo "TTPRN_myProperty2=$TTPRN_myProperty2"
}