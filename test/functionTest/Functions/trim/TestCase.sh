#--variantCount=9

declare -a varsToTrim=( '' ' ' 'abc:' ' cde ' 'fg sas' ' a b' 'b a ' $' \t a\t b \t  ' $'\n 1\n\t 2 \t\n ')
declare -a theResults=(    '' ''  'abc:' 'cde'   'fg sas' 'a b'  'b a'   $'a\t b'    $'1\n\t 2')

STEPS=( 'trim "${varsToTrim[$TTRO_variantCase]}"' 'echo "trim \"${varsToTrim[$TTRO_variantCase]}\" TTTT_trim=\"$TTTT_trim\""' 'myEval' )

function myEval {
	if [[ $TTTT_trim != ${theResults[$TTRO_variantCase]} ]]; then
		setFailure "wrong result from trim '$TTTT_trim' expected is '${theResults[$TTRO_variantCase]}'"
	fi
}