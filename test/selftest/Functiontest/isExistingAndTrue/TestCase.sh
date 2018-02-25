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
			echoExecuteAndIntercept 'error' 'isExistingAndTrue' 'var';;
		varFalse)
			echoExecuteAndIntercept 'error' 'isExistingAndTrue' 'var';;
		varTrue)
			echoExecuteAndIntercept 'success' 'isExistingAndTrue' 'var';;
	esac
}