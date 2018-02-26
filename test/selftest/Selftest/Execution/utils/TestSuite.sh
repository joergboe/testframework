#--variantCount=5

TT_runOptions='--noprompt --no-browser'

PREPS='getOptions'

declare -a options=( '' '-j 1' '--verbose' '--debug' '--verbose --debug')

function getOptions {
	TT_runOptions="$TT_runOptions ${options[$TTRO_variantSuite]}"
}
