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

case "$MOD_ALIAS" in
    'shell-glossary')
        SRC_LOG=$(
            printf "%s\n" "$LOG" | {
                while IFS= read -r LINE; do
                    case "$LINE" in
                        *'(): [doc]'*)
                            continue
                        ;;
                        *'src: '* | *'(): '*)
                            printf "%s\n" "$LINE"
                        ;;
                        *)
                            continue
                        ;;
                    esac
                done
            }
        )
    ;;
esac

git checkout "$COMMIT"
cd "$MAIN_DIR"
git add .

if [ "$SRC_LOG" ] && [ ! "$SRC_LOG" = "$LOG" ]; then
    git commit -m \
".gitmodules: $MOD_ALIAS -> \`$2\`

- Filtered log:
$SRC_LOG

- Complete log:
$LOG" -Ss
elif [ "$LOG" ]; then
    git commit -m \
".gitmodules: $MOD_ALIAS -> \`$2\`

- Complete log:
$LOG" -Ss
else
    git commit -m ".gitmodules: $MOD_ALIAS -> \`$2\`" -Ss
fi
