#--variantCount=3

setVar 'TTRO_stepsCase' 'myStep'

declare -a durations=(30 20 22)
function myStep {
	useCpu ${durations[$TTRO_variantCase]} $TTRO_variantCase "false"
}
