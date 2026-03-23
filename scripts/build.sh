set -e

while [ "$#" -ge 1 ]; do
    FILE=$(cat "$1")
    read -r FILE_SHEBANG < "$1"

    FILE="${FILE#"$FILE_SHEBANG"}"

    for f in ./lib/shell-glossary/src/*; do
        f=$(cat "$f")
        FILE="$f
$FILE"
    done

    FILE="$FILE_SHEBANG
$FILE"

    NAME="$1"
    NAME="${NAME##*/}"
    NAME="${NAME%.sh}"
    printf "%s\n" "$FILE" > ./"$NAME"
    chmod 0755 "$NAME" || :

    printf "%s\n" "> $PWD/$NAME"

    shift
done
