#--variantCount=14

setVar 'TTRO_stepsCase' 'myStep'

declare -a durations=(30 20 22 44 30 60 30 30 33 34
                      55 66 88 11)
function myStep {
	useCpu ${durations[$TTRO_variantCase]} $TTRO_variantCase "false"
}
