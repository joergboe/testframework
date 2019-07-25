#--variantCount=1

setVar 'TTRO_stepsCase' 'myStep'

declare -a durations=(22)
function myStep {
	useCpu ${durations[$TTRO_variantCase]} $TTRO_variantCase "false"
}
