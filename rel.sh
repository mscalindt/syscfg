set -e

case "${1:-x}" in
    '-h' | '--help' | 'x')
        printf "%s\n" '$1 = RELEASE NAME'
        printf "%s\n" '$2 = PREVIOUS TAG'
        printf "%s\n" '$3 = COMMIT / HEAD'

        exit 0
    ;;
esac

[ "$#" -eq 3 ] || { echo "Expected exactly 3 arguments; got $#."; exit 2; }
[ "$1" ] || { echo '$1/REL is empty.'; exit 2; }
[ "$2" ] || { echo '$2/PRE is empty.'; exit 2; }
[ "$3" ] || { echo '$3/CUR is empty.'; exit 2; }

LOG="$(git log --pretty=format:'%h %s' --no-decorate "$2..$3")"

SRC_LOG=$(
    printf "%s\n" "$LOG" | {
        while IFS= read -r LINE; do
            case "$LINE" in
                *': [doc]'*)
                    continue
                ;;
                *'syscfg: '* | *'(): '*)
                    printf "%s\n" "$LINE"
                ;;
                *)
                    continue
                ;;
            esac
        done
    }
)

if [ "$SRC_LOG" = "$LOG" ]; then
    git tag -m \
"syscfg $1

- Complete log between $2 and $3:
$LOG" -as "$1" "$3"
elif [ "$LOG" ]; then
    git tag -m \
"syscfg $1

- Filtered log of core changes:
$SRC_LOG

- Complete log between $2 and $3:
$LOG" -as "$1" "$3"
else
    git tag -m "syscfg $1" -as "$1" "$3"
fi
