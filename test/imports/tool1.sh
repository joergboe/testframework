
echo "######### tool1.sh ########"

func1() {
	echo "func1 xxxx"
	echo "TTRO_var1=$TTRO_var1"
}
export -f func1

func2() {
	echo "func2 xxxx"
	setVar 'TTRO_var2' 'func2'
}
export -f func2
