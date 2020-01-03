#--variantList='step prep'

echo "Variant step demonstrate an failed test case step"
echo "Variant prep demonstrates an failure during test preparation (This should not happen, but is is tollerated)"
echo "Both variants execute finally the testFinalization function"

testStep() {
	if [[ "$TTRO_variantCase" == "step" ]]; then
		echo "----- Execute test and set failure -----"
		setFailure "CUSTOM FAILURE during STEP"
	fi
}

testPreparation() {
	if [[ "$TTRO_variantCase" == "prep" ]]; then
		echo "----- Execute preparation and set failure -----"
		setFailure "CUSTOM FAILURE during PREPS"
	fi
}

# Demonstrate the execution of the finalization function
testFinalization() {
	echo "----- $FUNCNAME Execute finalization of the test -----"
}
