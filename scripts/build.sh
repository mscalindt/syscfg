# $1  = name
# $2+ = source files

set -e

SHEBANG='#!/bin/sh'
NAME="$1"

shift

FILE="$SHEBANG"
for _arg in "$@"; do
    FILE="$FILE
$(cat "$_arg")"
done

printf "%s\n" "$FILE" > ./"$NAME"
chmod 0755 ./"$NAME" || :

printf "%s\n" "> $PWD/$NAME"
