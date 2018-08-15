
function testPreparation {
	case "$TTRO_variantCase" in
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
	case "$TTRO_variantCase" in
		varNotExists)
			echoExecuteInterceptAndError 'isFalse' 'varsasas';;
		varFalse)
			echoExecuteInterceptAndSuccess 'isFalse' 'varsasas';;
		varTrue)
			echoExecuteInterceptAndError 'isFalse' 'varsasas';;
	esac
}