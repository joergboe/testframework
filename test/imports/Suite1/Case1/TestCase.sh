import tool1.sh
import "tool2.sh"

STEPS=(
	'echo "######## STEP1"'
	'func1'
	'func2'
	'myEval'
)

myEval() {
	echo "$TTPR_var11=$TTPR_var11"
	echo "$TTPR_var12=$TTPR_var12"
	echo "$TTPR_var21=$TTPR_var21"
	echo "$TTPR_var22=$TTPR_var22"
	echo "\$TTRO_var1=$TTRO_var1"
	if [[ $TTPR_var11 != 'set_from_tool1.sh' ]]; then setError "wrong value \$TTPR_var11"; fi
	if [[ $TTPR_var12 != 'set_from_func1' ]];    then setError "wrong value \$TTPR_var12"; fi
	if [[ $TTPR_var21 != 'set_from_tool2.sh' ]]; then setError "wrong value \$TTPR_var21"; fi
	if [[ $TTPR_var22 != 'set_from_func2' ]];    then setError "wrong value \$TTPR_var22"; fi
	if [[ $TTRO_var1 != '55' ]];                 then setError "wrong value \$TTRO_var1"; fi
}
