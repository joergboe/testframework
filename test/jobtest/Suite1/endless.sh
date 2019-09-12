#!/bin/bash

#set -o posix;

echo "Run $0 \$\$=$$"

function testErrorTrapFunc {
	echo -e "\033[31mERROR: $FUNCNAME ***************"
	local -i i=0;
	while caller $i; do
		i=$((i+1))
	done
	echo -e "************************************************\033[0m"
}
trap testErrorTrapFunc ERR

function testExitFunction {
	echo "$FUNCNAME and sleep a bit"
	for x in 9 8 7 6 5 4 3 2 1 0; do
		echo "$FUNCNAME sleep # $x"
		sleep 1
	done
	echo "$FUNCNAME And now exit"
}
trap testExitFunction EXIT

while true; do
	:
done
exit 0

