PREPS='myPrep'
STEPS='true'
FINS='myFin'

myPrep() {
	echo "*************** $FUNCNAME $-"
	echo "*************** $FUNCNAME END"
	return 0
}

myFin() {
	echo "*************** $FUNCNAME $-"
	echo "\$varNotInitialized=$varNotInitialized"
	false
	echo "*************** $FUNCNAME END"
}
