###################################
# test tools for the self test
###################################

# register tool module
import "$TTRO_inputDirSuite/TestTools.sh"

#Test collection preparation
PREPS='modifyAll'

TTRO_help_modifyPrefix='
# This function modifies the varname prefix and copies the code
# 1 the input file
# 2 the output file'
function modifyPrefix {
	if [[ $1 == $2 ]]; then
		printErrorAndExit "$FUNCNAME: Origin and destination must be different file" $errRt
	fi
	sed -e "s/TT_/TY_/g;s/TTRO_/TYRO_/g;s/TTP_/TYP_/g;s/TTPN_/TYPN_/g;s/TTXX_/TYXX_/g" "$1" > "$2"
}
export -f modifyPrefix

TTRO_help_modifyAll='
# This function copies the bin dir into workdir/bin
# and morphes the code'
function modifyAll {
	setVar 'TTPN_binDir' "$TTRO_workDir/bin"
	mkdir "$TTPN_binDir"
	local x filename destf
	for x in $TTPN_sourceDir/*; do
		filename="${x##*/}"
		destf="$TTPN_binDir/$filename"
		modifyPrefix "$x" "$destf"
		if [[ -x $x ]]; then
			chmod +x "$destf"
		fi
	done
}
export -f modifyAll