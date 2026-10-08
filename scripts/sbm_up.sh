set -e

case "${1:-x}" in
    '-h' | '--help' | 'x')
        printf "%s\n" '$1 = SUBMODULE RELATIVE GIT PATH'
        printf "%s\n" '$2 = TAG'

        exit 0
    ;;
esac

[ "$#" -eq 2 ] || { echo "Expected exactly 2 arguments; got $#."; exit 2; }
[ "$1" ] || { echo '$1/SUB is empty.'; exit 2; }
[ "$2" ] || { echo '$2/TAG is empty.'; exit 2; }

case "$1" in
    *'shell-glossary'*) MOD_ALIAS='shell-glossary' ;;
esac

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
".gitmodules: $MOD_ALIAS -> \`$2\`

$LOG" -Ss
else
    git commit -m ".gitmodules: $MOD_ALIAS -> \`$2\`" -Ss
fi
