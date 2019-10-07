  #--  variantList='v1 \
  #--v.2\
  #--	v-3\
#--		v4 \
#--v5'

STEPS=my

my() {
	case "$TTRO_variantCase" in
	v1)
		echo "\$TTRO_variantCase=$TTRO_variantCase";;
	v.2)
		echo "\$TTRO_variantCase=$TTRO_variantCase";;
	v-3)
		echo "\$TTRO_variantCase=$TTRO_variantCase";;
	v4)
		echo "\$TTRO_variantCase=$TTRO_variantCase";;
	v5)
		echo "\$TTRO_variantCase=$TTRO_variantCase";;
	*)
		setFailure "Invalid variant \$TTRO_variantCase=$TTRO_variantCase";;
	esac
}
