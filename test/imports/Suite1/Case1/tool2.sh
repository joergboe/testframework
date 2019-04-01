echo "######### tool2.sh ########"
setVar 'TTPR_var11' 'set_from_tool2.sh'
setVar 'TTPR_var21' 'set_from_tool2.sh'

func2() {
	echo "######### func2 xxxx"
	setVar 'TTPR_var11' 'set_from_func2'
	setVar 'TTPR_var12' 'set_from_func2'
	setVar 'TTPR_var21' 'set_from_func2'
	setVar 'TTPR_var22' 'set_from_func2'
}
export -f func2
