#--variantCount=20
setVar 'TTRO_stepsCase' 'myStep'
##--TT_timeout=21

declare -a durations=(30 20 22 44 30 60 30 30 33 34
                      55 66 88 11 30 40 50 60 11 34)
function myStep {
	useCpu ${durations[$TTRO_variantCase]} $TTRO_variantCase "false"
	echo "End Test case $TTRO_variantCase"
}