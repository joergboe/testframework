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
			echoExecuteAndIntercept2 'success' 'isFalse' 'var';;
		varFalse)
			echoExecuteAndIntercept2 'success' 'isFalse' 'var';;
		varTrue)
			echoExecuteAndIntercept2 'error' 'isFalse' 'var';;
	esac
}