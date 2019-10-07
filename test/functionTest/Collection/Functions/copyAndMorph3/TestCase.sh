#--variantList='one onewith oneone two1x two2x thre-e foaur fobur foxur'

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
		echoExecuteInterceptAndSuccess diff file1.spl file1_one.spl;;
	onewith)
		echoExecuteInterceptAndSuccess diff file1.spl file1_onewith.spl;;
	oneone)
		echoExecuteInterceptAndSuccess diff file1.spl file1_oneone.spl;;
	two1x)
		echoExecuteInterceptAndSuccess diff file1.spl file1_two1x.spl;;
	two2x)
		echoExecuteInterceptAndSuccess diff file1.spl file1_two1x.spl;;
	thre-e)
		echoExecuteInterceptAndSuccess diff file1.spl file1_thre-e.spl;;
	foaur)
		echoExecuteInterceptAndSuccess diff file1.spl file1_foaur.spl;;
	fobur)
		echoExecuteInterceptAndSuccess diff file1.spl file1_foaur.spl;;
	foxur)
		echoExecuteInterceptAndSuccess diff file1.spl file1_foxur.spl;;
	*)
		printErrorAndExit "wrong variant $TTRO_variantCase" $errRt;;
	esac
	return 0
}