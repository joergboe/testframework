#--variantCount=4

PREPS='copyAndModifyTestCollection'
STEPS='
  getOptions
  TT_expectResult=$errTestError
  runRunTTF
  TT_casesError=3
  TT_casesExecuted=3
  checkResults
  myEval'

declare -a options=( '--noprompt --no-browser' '-j 1 --noprompt --no-browser' '-j 1 -v --noprompt --no-browser' '-j 1 -v -d --noprompt --no-browser' )

getOptions() {
	TT_runOptions="${options[$TTRO_variantCase]}"
}

myEval() {
  linewisePatternMatchInterceptAndSuccess "$TTRO_workDirCase/STDERROUT1.log" 'true' '*ERROR: evalPreambl : timeout is no digit*' '*ERROR: In case :variantCountAndVariantList we have both variant variables*' '*ERROR: evalPreambl : variantCount is no digit*'
}
