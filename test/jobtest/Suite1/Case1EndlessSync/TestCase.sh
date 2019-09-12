PREPS='myPrep'
STEPS='myStep'
FINS='myFin'

myPrep() {
	echo "*************** $FUNCNAME $-"
}

myStep() {
	echo "*************** $FUNCNAME"
	ps -f
	"$TTRO_inputDirSuite/endless.sh" 'synchron'
	echo "*************** $FUNCNAME END"
}

myFin() {
	echo "*************** $FUNCNAME $-"
	sleep 3
	echo "$varNotInitialized"
	echo "*************** $FUNCNAME END"
}
