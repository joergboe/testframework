
echo "######### tool1.sh ########"
setVar 'TTPR_var11' 'set_from_tool1.sh'

func1() {
	echo "######### func1 xxxx"
	setVar 'TTPR_var11' 'set_from_func1'
	setVar 'TTPR_var12' 'set_from_func1'
}
export -f func1
