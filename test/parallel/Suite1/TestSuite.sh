setVar 'TTRO_prepsSuite' 'myFunc'

TTP_timeout=90
TTP_additionalTime=10

function myFunc {
	echo "$FUNCNAME : Test suite prep"
	useCpu 5 1 ""
}