#--variantCount=4

PREPS='copyAndModifyTestCollection'
STEPS="getOptions TT_expectResult=$errTestError runRunTTF TT_suitesExecuted=0 TT_casesExecuted=3 TT_casesError=1 checkResults"

declare -a options=( '' '--verbose' '--debug' '--debug --verbose' )

function getOptions {
	TT_runOptions="$TT_runOptions --noprompt --no-browser"
	TT_runOptions="$TT_runOptions ${options[$TTRO_variantCase]}"
}

