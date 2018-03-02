#--variantList='varNotExists varIsVariable varIsFunction varIsArray varIsMap varIsFunctionRo'

function testPreparation {
	case "$TTRO_variantCase" in
		varNotExists)
			echo "Case variable not exists";;
		varIsVariable)
			echo "Case variable is empty";
			var='xxx';;
		varIsFunction)
			echo "Case variable is function";
			function var {
				echo "function"
			};;
		varIsArray)
			echo "Case variable is array"
			var=(11, 22);;
		varIsMap)
			echo "Case variable is map"
			declare -A var=(['key1']=11, ['key2']=22);;
		varIsFunctionRo)
			echo "Case variable is function ro"
			function var {
				echo "function"
			}
			readonly -f var;;
		*)
			printErrorAndExit "Wrong variant '$TTRO_variantCase'" $errRt
	esac
}

function testStep {
	case "$TTRO_variantCase" in
		varNotExists)
			echoExecuteAndIntercept 'error' 'isFunction' 'var';;
		varIsVariable)
			echoExecuteAndIntercept 'error' 'isFunction' 'var';;
		varIsFunction)
			echoExecuteAndIntercept 'success' 'isFunction' 'var';;
		varIsArray)
			echoExecuteAndIntercept 'error' 'isFunction' 'var';;
		varIsMap)
			echoExecuteAndIntercept 'error' 'isFunction' 'var';;
		varIsFunctionRo)
			echoExecuteAndIntercept 'success' 'isFunction' 'var';;
		*)
			printErrorAndExit "Wrong variant '$TTRO_variantCase'" $errRt
	esac
}