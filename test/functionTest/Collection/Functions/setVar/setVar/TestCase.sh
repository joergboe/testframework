#--variantCount=9

function testStep {
	case $TTRO_variantCase in
	0)
		echo "check value of TT_ variable and change it"
		echo "$TT_rwVar"
		if [[ $TT_rwVar != 'suite var' ]]; then setFailure "Wrong value in check 1"; fi
		setVar TT_rwVar 'case var'
		if [[ $TT_rwVar != 'case var' ]]; then setFailure "Wrong value in check 2"; fi
		echo "$TT_rwVar";;
	1)
		echo "check value of TTRO_ variable"
		echo "$TTRO_roVar"
		if [[ $TTRO_roVar != 'suite ro var' ]]; then setFailure "Wrong value in check 1"; fi
		;;
	2)
		echo "try change value of TTRO_ variable"
		echo "$TTRO_roVar"
		if [[ $TTRO_roVar != 'suite ro var' ]]; then setFailure "Wrong value in check 1"; fi
		setVar TTRO_roVar 'case ro var'
		echo "$TTRO_roVar"
		if [[ $TTRO_roVar != 'case ro var' ]]; then setFailure "Wrong value in check 2"; fi
		;;
	3)
		echo "set non existent TTPR"
		setVar "TTPR_pr0" 'case rrr'
		echo "$TTPR_pr0"
		if [[ $TTPR_pr0 != 'case rrr' ]]; then setFailure "Wrong value in check 1"; fi
		;;
	4)
		echo "set empty TTPR"
		echo "'$TTPR_pr1'"
		if [[ -n $TTPR_pr1 ]]; then setFailure "Wrong value in check 1"; fi
		setVar "TTPR_pr1" 'case rrr'
		echo "'$TTPR_pr1'"
		if [[ -n $TTPR_pr1 ]]; then setFailure "Wrong value in check 1"; fi
		;;
	5)
		echo "set non empty empty TTPR"
		echo "'$TTPR_pr2'"
		if [[ $TTPR_pr2 != 'suite pr' ]]; then setFailure "Wrong value in check 1"; fi
		setVar "TTPR_pr2" 'case rrr'
		echo "'$TTPR_pr2'"
		if [[ $TTPR_pr2 != 'suite pr' ]]; then setFailure "Wrong value in check 1"; fi
		;;
	6)
		echo "set non existent TTPRN"
		setVar "TTPRN_pr0" 'case rrr'
		echo "$TTPRN_pr0"
		if [[ $TTPRN_pr0 != 'case rrr' ]]; then setFailure "Wrong value in check 1"; fi
		;;
	7)
		echo "set empty TTRP"
		echo "'$TTPRN_pr1'"
		if [[ -n $TTPRN_pr1 ]]; then setFailure "Wrong value in check 1"; fi
		setVar "TTPRN_pr1" 'case rrr'
		echo "'$TTPRN_pr1'"
		if [[ $TTPRN_pr1 != 'case rrr' ]]; then setFailure "Wrong value in check 1"; fi
		;;
	8)
		echo "set non empty empty TTRP"
		echo "'$TTPRN_pr2'"
		if [[ $TTPRN_pr2 != 'suite prn' ]]; then setFailure "Wrong value in check 1"; fi
		setVar "TTPRN_pr2" 'case rrr'
		echo "'$TTPRN_pr2'"
		if [[ $TTPRN_pr2 != 'suite prn' ]]; then setFailure "Wrong value in check 1"; fi
		;;
	*)
		printErrorAndExit "wron case variant $TTRO_variantCase" $errRt;;
	esac
}