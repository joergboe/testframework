#--variantCount=4

PREPS='copyAndModifyTestCollection'
STEPS='
  getOptions
  TT_expectResult=$errSuiteError
  runRunTTF
  TT_suitesExecuted=5
  TT_suitesError=5
  checkResults
  myEval'

declare -a options=( '--noprompt --no-browser' '-j 1 --noprompt --no-browser' '-j 1 -v --noprompt --no-browser' '-j 1 -v -d --noprompt --no-browser' )

getOptions() {
	TT_runOptions="${options[$TTRO_variantCase]}"
}

myEval() {
  linewisePatternMatchInterceptAndSuccess "$TTRO_workDirCase/STDERROUT1.log" 'true'\
    '*ERROR: In suite timeout timeout is not expected ! Suite preamblError*'\
    '*ERROR: On of variables variantCount, variantList or timeout is used in suite user code*'\
    '*ERROR: In suite variantCountAndVariantList we have both variant variables*'\
    '*ERROR: evalPreambl : variantCount is no digit*'
}
