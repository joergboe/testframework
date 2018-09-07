#!/bin/bash

set -o errexit; set -o nounset;

source bin/version.sh

declare -r releasedir='releases'
declare -r docdir='doc'

#environment check
if ! declare -p STREAMS_INSTALL > /dev/null; then
	echo "Missing environment: STREAMS_INSTALL must be set" >&2
	exit 1
fi
declare -r mt="${STREAMS_INSTALL}/bin/spl-make-toolkit"
declare -r md="${STREAMS_INSTALL}/bin/spl-make-doc"

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
	read -p "To produce the release anyway press y/Y";
	if [[ $REPLY != "y" && $REPLY != "Y" ]]; then
		echo "Abort"
		exit 1
	fi
fi

#toolkit
$mt -c -i streamsx.testframe
$mt -i streamsx.testframe
rm -rf streamsx.testframe/doc
rm -rf "$docdir"

mkdir -p "$docdir"
#doc in release bundle
$md -i streamsx.testframe --include-all --doc-title "Test Toolkit streamsx.testframe" --author joergboe --warn-no-comments
#doc for gh pages
$md -i streamsx.testframe --include-all --doc-title "Test Toolkit streamsx.testframe" --author joergboe --warn-no-comments --output-directory "$docdir/spldoc.tmp"

cd bin
./runTTF --man | grep -v '===' > "../$docdir/manpage.md.tmp"
./runTTF --ref '' > ../doc/utils.txt.tmp0
./runTTF --ref ./streamsutils.sh > ../doc/streamsutils.txt.tmp0
while read -r; do
	if [[ $REPLY =~ \#[[:space:]] ]]; then
		echo "${REPLY:1}"
	else
		echo "$REPLY"
	fi;
done < ../doc/utils.txt.tmp0 > ../doc/utils.txt.tmp 
while read -r; do
	if [[ $REPLY =~ \#[[:space:]] ]]; then
		echo "${REPLY:1}"
	else
		echo "$REPLY"
	fi;
done < ../doc/streamsutils.txt.tmp0 > ../doc/streamsutils.txt.tmp 
cd -

commithash=$(git rev-parse HEAD)
echo "RELEASE.INFO commithash=$commithash"
echo "commithash=$commithash" > RELEASE.INFO

mkdir -p "$releasedir"

fname="testframeInstaller_v${TTRO_version}.sh"

tar cvJf "$releasedir/tmp.tar.xz" --exclude=.apt_generated --exclude=.toolkitList --exclude=.gitignore --exclude oldcode.sh bin samples streamsx.testframe README.md RELEASE.INFO

cat tools/selfextract.sh releases/tmp.tar.xz > "$releasedir/$fname"

chmod +x "$releasedir/$fname"

rm "$releasedir/tmp.tar.xz"

echo
echo "*************************************************"
echo "Success build release package '$releasedir/$fname'"
echo "*************************************************"

exit 0
