# $1 = name
# $2+ = files

set -e

NAME="$1"
shift

read -r FILE < "$1"
for _func in ./lib/shell-glossary/src/*; do
    FILE="$FILE
$(cat "$_func")"
done
for _file in "$@"; do
    FILE="$FILE
$(cat "$_file")"
done

printf "%s\n" "$FILE" > "$PWD/$NAME"
chmod 0755 "$PWD/$NAME" || :

printf "%s\n" "> $PWD/$NAME"
