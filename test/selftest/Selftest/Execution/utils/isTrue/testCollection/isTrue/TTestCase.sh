#--variantList='varNotExists varFalse varTrue'

function testPreparation {
	case "$TYRO_variantCase" in
		varNotExists)
			echo "Case variable not exists";;
		varFalse)
			echo "Case variable is empty";
			varsasas='';;
		varTrue)
			echo "Case variable is not empty";
			varsasas='notEmpty';;
	esac
}

function testStep {
	case "$TYRO_variantCase" in
		varNotExists)
			echoExecuteAndIntercept 'error' 'isTrue' 'varsasas';;
		varFalse)
			echoExecuteAndIntercept 'error' 'isTrue' 'varsasas';;
		varTrue)
			echoExecuteAndIntercept 'success' 'isTrue' 'varsasas';;
	esac
}