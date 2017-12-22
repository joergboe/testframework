#!/bin/bash

set -o errexit; set -o nounset;

source bin/version.sh

declare -r releasedir='releases'
declare -r docdir='doc'

echo
echo "Build release package version v$TTRO_version"
echo

while read -p "Is this correct: y/e "; do
	if [[ $REPLY == "y" || $REPLY == "Y" ]]; then
		break
	elif [[ $REPLY == "e" || $REPLY == "E" ]]; then
		exit 2
	fi
done

commitstatus=$(git status --porcelain)
if [[ $commitstatus ]]; then
	echo "Repository has uncommited changes:"
	echo "$commitstatus"
	read -p "To produce the release anyay press y/Y";
	if [[ $REPLY != "y" && $REPLY != "Y" ]]; then
		echo "Abort"
		exit 1
	fi
fi

mkdir -p "$docdir"
./runTTFLink --man > "$docdir/manpage.md"

commithash=$(git rev-parse HEAD)
echo "RELEASE.INFO commithash=$commithash"
echo "commithash=$commithash" > RELEASE.INFO

mkdir -p "$releasedir"

fname="testframeInstaller_v${TTRO_version}.sh"

tar cvJf "$releasedir/tmp.tar.xz" bin samples README.md RELEASE.INFO

cat tools/selfextract.sh releases/tmp.tar.xz > "$releasedir/$fname"

chmod +x "$releasedir/$fname"

rm "$releasedir/tmp.tar.xz"

echo
echo "*************************************************"
echo "Success build release package '$releasedir/$fname'"
echo "*************************************************"

exit 0
