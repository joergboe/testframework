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
	case "$TTRO_variantCase" in
		varNotExists)
			echoExecuteAndIntercept 'error' 'isExistingAndFalse' 'var';;
		varFalse)
			echoExecuteAndIntercept 'success' 'isExistingAndFalse' 'var';;
		varTrue)
			echoExecuteAndIntercept 'error' 'isExistingAndFalse' 'var';;
	esac
}