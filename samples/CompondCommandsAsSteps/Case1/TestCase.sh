STEPS=( \
	'ps' \
	'( echo "******"; ps )' \
	'for (( x=0; x<5; x++)); do echo $x; done' \
)

#do not use parts of composite commands as a test step like
#STEPS='ps ( ps )'

FINS=( 'echo "******* test finailzation done *********"' )