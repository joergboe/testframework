#--variantCount=5

#prepare the case categories
case "$TTRO_variantCase" in
	0) setCategory ;;
	1) setCategory 'cat1' 'other' ;;
	2) setCategory 'cat1' 'cat2' 'cat3' 'other' ;;
	3) setCategory 'cat3' ;;
	4) setCategory 'cat4' ;;
esac

function testStep {
	echo "Execute test case $TTRO_case variant $TTRO_variantCase"
	echo -n "My cats are: "; declare -p TTTT_categoryArray
	return 0
}
