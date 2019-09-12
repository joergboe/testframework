PREPS='myPrep'
STEPS='myStep'
FINS='myFin'

myPrep() {
	echo "*************** $FUNCNAME $-"
}

myStep() {
	echo "*************** $FUNCNAME"
	"$TTRO_inputDirSuite/endless.sh" 'asynchron' &
	ps -f
	echo "*************** $FUNCNAME END"
}

myFin() {
	echo "*************** $FUNCNAME $-"
	sleep 3
	echo "$varNotInitialized"
	echo "*************** $FUNCNAME END"
}
