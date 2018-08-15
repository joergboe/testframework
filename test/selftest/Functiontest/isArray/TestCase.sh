#--variantList='varNotExists varIsVariable varIsFunction varIsArray varIsMap varIsArrayRo'

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
		varIsArrayRo)
			echo "Case variable is array ro"
			var=(11, 22)
			readonly var;;
		*)
			printErrorAndExit "Wrong variant '$TTRO_variantCase'" $errRt
	esac
}

function testStep {
	case "$TTRO_variantCase" in
		varNotExists)
			echoExecuteInterceptAndError 'isArray' 'var';;
		varIsVariable)
			echoExecuteInterceptAndError 'isArray' 'var';;
		varIsFunction)
			echoExecuteInterceptAndError 'isArray' 'var';;
		varIsArray)
			echoExecuteInterceptAndSuccess 'isArray' 'var';;
		varIsMap)
			echoExecuteInterceptAndError 'isArray' 'var';;
		varIsArrayRo)
			echoExecuteInterceptAndSuccess 'isArray' 'var';;
	esac
}