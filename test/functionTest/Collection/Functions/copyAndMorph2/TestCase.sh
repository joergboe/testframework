#--variantList='one two thre-e fo_ur 5 6'

var1="--This is var1--"
declare -A arr1=( [one]="--variant one--" [two]="--variant two--" [thre-e]="--variant thre-e--" [fo_ur]="--variant fo_ur--" [5]='--variant 5--' [6]='--variant 6--' ) 

PREPS=( 'var2="++ var2 ++"' )
STEPS=( 
	'setVar "TTPRN_debug" "true"'
	'copyAndMorph "$TTRO_inputDirCase" "$TTRO_workDirCase" "$TTRO_variantCase" "*.spl"'
	'setVar "TTPRN_debugDisable" "true"'
	'echoExecuteInterceptAndSuccess diff "$TTRO_inputDirCase/file1.txt" "$TTRO_workDirCase/file1.txt"'
	'myEval file1.spl'
)

function myEval {
	case "$TTRO_variantCase" in
	one)
		linewisePatternMatchInterceptAndSuccess $1 'true' 'fadgb  --This is var1--gsb sgbgbs ++ var2 ++sgfb sgb sgbgbs g' ' sbsgbsg--variant one--bsswuhjei,kg' '  G  --variant one--' ' aaaa --This is var1--' 
		return 0;;
	two)
		linewisePatternMatchInterceptAndSuccess $1 'true' 'fadgb  --This is var1--gsb sgbgbs ++ var2 ++sgfb sgb sgbgbs g' ' sbsgbsg--variant two--bsswuhjei,kg' '  G  --variant two--' ' aaaa --This is var1--' 
		return 0;;
	thre-e)
		linewisePatternMatchInterceptAndSuccess $1 'true' 'fadgb  --This is var1--gsb sgbgbs ++ var2 ++sgfb sgb sgbgbs g' ' sbsgbsg--variant thre-e--bsswuhjei,kg' '  G  --variant thre-e--' ' aaaa --This is var1--' 
		return 0;;
	fo_ur)
		linewisePatternMatchInterceptAndSuccess $1 'true' 'fadgb  --This is var1--gsb sgbgbs ++ var2 ++sgfb sgb sgbgbs g' ' sbsgbsg--variant fo_ur--bsswuhjei,kg' '  G  --variant fo_ur--' ' aaaa --This is var1--' 
		return 0;;
	5)
		linewisePatternMatchInterceptAndSuccess $1 'true' 'fadgb  --This is var1--gsb sgbgbs ++ var2 ++sgfb sgb sgbgbs g' ' sbsgbsg--variant 5--bsswuhjei,kg' '  G  --variant 5--' ' aaaa --This is var1--' 
		return 0;;
	6)
		linewisePatternMatchInterceptAndSuccess $1 'true' 'fadgb  --This is var1--gsb sgbgbs ++ var2 ++sgfb sgb sgbgbs g' ' sbsgbsg--variant 6--bsswuhjei,kg' '  G  --variant 6--' 
		linewisePatternMatchInterceptAndError $1 '' '*aaaa*'
		return 0;;
	*)
		printErrorAndExit "wrong variant $TTRO_variantCase" $errRt;;
	esac
	return 0
}