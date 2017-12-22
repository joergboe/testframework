#!/bin/bash

set -o errexit; set -o nounset;

source bin/version.sh

declare -r releasdir='releases'

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

commithash=$(git rev-parse HEAD)
echo "RELEASE.INFO commithash=$commithash"
echo "commithash=$commithash" > RELEASE.INFO

mkdir -p "$releasdir"

fname="testframeInstaller_v${TTRO_version}.sh"

tar cvJf "$releasdir/tmp.tar.xz" bin samples README.md RELEASE.INFO

cat tools/selfextract.sh releases/tmp.tar.xz > "$releasdir/$fname"

chmod +x "$releasdir/$fname"

rm "$releasdir/tmp.tar.xz"

echo
echo "*************************************************"
echo "Success build release package '$releasdir/$fname'"
echo "*************************************************"

exit 0
