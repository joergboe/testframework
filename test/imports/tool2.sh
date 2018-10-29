echo "######### tool2.sh ########"

func2() {
	echo "func2 xxxx"
	setVar 'TTRO_var1' 55
}
export -f func2
