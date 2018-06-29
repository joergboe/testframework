#--variantList='one two three four 5 6'

STEPS=( 
	'setVar "TTPRN_debug" "true"'
	'copyAndMorph "$TTRO_inputDirCase" "$TTRO_workDirCase" "$TTRO_variantCase" "*.spl" "*.spx"'
	'setVar "TTPRN_debugDisable" "true"'
	'echoExecuteInterceptAndSuccess diff "$TTRO_inputDirCase/file1.txt" "$TTRO_workDirCase/file1.txt"'
	'echoExecuteInterceptAndSuccess diff "$TTRO_inputDirCase/adir/file2.txt" "$TTRO_workDirCase/adir/file2.txt"'
	'myEval file1.spl'
	'myEval adir/file2.spx'
)

function myEval {
	case "$TTRO_variantCase" in
	one)
		linewisePatternMatchInterceptAndSuccess $1 'true' 'one two three' '!four 5 6 ' 'one' 'one 6'
		linewisePatternMatchInterceptAndError   $1 ''                                                '!one 6'
		return 0;;
	two)
		linewisePatternMatchInterceptAndSuccess $1 'true' 'one two three' '!four 5 6 '               '!one 6'
		linewisePatternMatchInterceptAndError   $1 ''                                  'one' 'one 6'
		return 0;;
	three)
		linewisePatternMatchInterceptAndSuccess $1 'true' 'one two three' '!four 5 6 '               '!one 6'
		linewisePatternMatchInterceptAndError   $1 ''                                  'one' 'one 6'
		return 0;;
	four)
		linewisePatternMatchInterceptAndSuccess $1 'true'                                            '!one 6'
		linewisePatternMatchInterceptAndError   $1 ''     'one two three' '!four 5 6 ' 'one' 'one 6'
		return 0;;
	5)
		linewisePatternMatchInterceptAndSuccess $1 'true'                                            '!one 6'
		linewisePatternMatchInterceptAndError   $1 ''    'one two three' '!four 5 6 '  'one' 'one 6'
		return 0;;
	6)
		linewisePatternMatchInterceptAndSuccess $1 'true'                                     'one 6'
		linewisePatternMatchInterceptAndError   $1 ''    'one two three' '!four 5 6 '  'one'          '!one 6'
		return 0;;
	*)
		printErrorAndExit "wrong variant $TTRO_variantCase";;
	esac
	return 0
}