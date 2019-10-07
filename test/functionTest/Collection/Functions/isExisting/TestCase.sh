#--variantList='varNotExistsIs varFalseIs varTrueIs noArgumentIs varNotExistsNot varFalseNot varTrueNot noArgumentNot'

function testPreparation {
	case "$TTRO_variantCase" in
		varNotExists*)
			echo "Case variable not exists";;
		varFalse*)
			echo "Case variable is empty";
			var='';;
		varTrue*)
			echo "Case variable is not empty";
			var='notEmpty';;
		noArgument*)
			echo "No argument";;
	esac
}

function testStep {
	setVar 'TTPRN_debug' 'true'
	case "$TTRO_variantCase" in
		varNotExistsIs)
			echoExecuteAndIntercept2 'error' 'isExisting' 'var';;
		varFalseIs)
			echoExecuteAndIntercept2 'success' 'isExisting' 'var';;
		varTrueIs)
			echoExecuteAndIntercept2 'success' 'isExisting' 'var';;
		noArgumentIs)
			echoExecuteAndIntercept2 'success' 'isExisting';;
		varNotExistsNot)
			echoExecuteAndIntercept2 'success' 'isNotExisting' 'var';;
		varFalseNot)
			echoExecuteAndIntercept2 'error' 'isNotExisting' 'var';;
		varTrueNot)
			echoExecuteAndIntercept2 'error' 'isNotExisting' 'var';;
		noArgumentNot)
			echoExecuteAndIntercept2 'error' 'isNotExisting';;
	esac
}