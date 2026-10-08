set -e

case "${1:-x}" in
    '-h' | '--help' | 'x')
        printf "%s\n" '$1 = SUBMODULE RELATIVE GIT PATH'
        printf "%s\n" '$2 = TAG'
        printf "%s\n" '$3 = ALIAS'

        exit 0
    ;;
esac

case "$#" in
    2|3) ;;
    *) echo "Expected 2 or 3 arguments; got $#."; exit 2 ;;
esac
[ "$1" ] || { echo '$1/SUB is empty.'; exit 2; }
[ "$2" ] || { echo '$2/TAG is empty.'; exit 2; }

cd "$1"
MAIN_DIR="$OLDPWD"
git fetch
COMMIT="$(git rev-list -n1 "$2")"
LOG="$(git log --pretty=format:'%h %s' --no-decorate "HEAD..$COMMIT")"

git checkout "$COMMIT"
cd "$MAIN_DIR"
git add .

if [ "$LOG" ]; then
    git commit -m \
".gitmodules: ${3:-$1} -> \`$2\`

$LOG" -Ss
else
    git commit -m ".gitmodules: ${3:-$1} -> \`$2\`" -Ss
fi
