PREPS='myPrep'
STEPS='true'
FINS='myFin'

myPrep() {
	echo "*************** $FUNCNAME $-"
	local x=0
	if read -p "**************************************** prompt ***"; then
		echo "Read success REPLY='$REPLY'"
	else
		x=$?
		echo "Read return $x REPLY='$REPLY'"
	fi
	echo "*************** $FUNCNAME END"
	return $x
}

myFin() {
	echo "*************** $FUNCNAME $-"
	echo "$varNotInitialized"
	echo "*************** $FUNCNAME END"
}
