#--variantList='varNotExists varFalse varTrue'

function testPreparation {
	case "$TTRO_variantCase" in
		varNotExists)
			echo "Case variable not exists";;
		varFalse)
			echo "Case variable is empty";
			var='';;
		varTrue)
			echo "Case variable is not empty";
			var='notEmpty';;
	esac
}

function testStep {
	setVar 'TTPRN_debug' 'true'
	case "$TTRO_variantCase" in
		varNotExists)
			echoExecuteAndIntercept 'error' 'isTrue' 'var';;
		varFalse)
			echoExecuteAndIntercept 'error' 'isTrue' 'var';;
		varTrue)
			echoExecuteAndIntercept 'success' 'isTrue' 'var';;
	esac
}