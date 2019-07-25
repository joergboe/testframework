#--variantCount=2
#--exclusive=true

setVar 'TTRO_stepsCase' 'myStep'

declare -a durations=(15 14)
function myStep {
	useCpu ${durations[$TTRO_variantCase]} $TTRO_variantCase "false"
}
