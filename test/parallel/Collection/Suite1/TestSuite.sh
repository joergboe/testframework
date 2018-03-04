setVar 'TTRO_prepsSuite' 'myFunc'

TTPR_timeout=90
TTPR_additionalTime=10

function myFunc {
	echo "$FUNCNAME : Test suite prep"
	useCpu 5 1 ""
}