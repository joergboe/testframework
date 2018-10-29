STEPS=(
	'echo "######## STEP1"'
	'func1'
	'func2'
	'myEval'
)

myEval() {
	if [[ $TTRO_var1 -ne 55 ]]; then setFailure "wrong var1"; fi
	if [[ $TTRO_var2 != func2 ]]; then setFailure "wrong var2"; fi
}
