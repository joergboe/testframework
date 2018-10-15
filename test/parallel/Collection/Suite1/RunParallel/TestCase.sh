#--variantCount=20
#--timeout=21

# the timeout value is not effective because it is lesser than the defined timeout from TestSuite

setVar 'TTRO_stepsCase' 'myStep'

declare -a durations=(30 20 10 44 10 10 30 80 55 50
                      55 66 88 11 30 40 50 58 11 34)
function myStep {
	useCpu ${durations[$TTRO_variantCase]} $TTRO_variantCase "false"
	echo "End Test case $TTRO_variantCase"
}