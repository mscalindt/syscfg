set -e

case "${1:-x}" in
    '-h' | '--help' | 'x')
        printf "%s\n" '$1 = RELEASE NAME'
        printf "%s\n" '$2 = PREVIOUS TAG'
        printf "%s\n" '$3 = NEWS BOOL'
        printf "%s\n" '$4 = EDIT BOOL'

        exit 0
    ;;
esac

case "$#" in
    3|4) ;;
    *) echo "Expected 3 or 4 arguments; got $#."; exit 2 ;;
esac
[ "$1" ] || { echo '$1/REL is empty.'; exit 2; }
[ "$2" ] || { echo '$2/PRE is empty.'; exit 2; }
case "$3" in
    0|1) ;;
    *) echo 'Bad $3/NEWS bool.'; exit 2 ;;
esac
case "${4:-0}" in
    0|1) ;;
    *) echo 'Bad $4/EDIT bool.'; exit 2 ;;
esac

make NEWS="$3" rel_commit

LOG="$(git log --pretty=format:'%h %s' --no-decorate "$2..HEAD")"

SRC_LOG=$(
    printf "%s\n" "$LOG" | {
        while IFS= read -r LINE; do
            case "$LINE" in
                *': [doc]'* | *': [fmt]'*)
                    continue
                ;;
                *'syscfg: '* | *'(): '* | *'.gitmodules: '*)
                    printf "%s\n" "$LINE"
                ;;
                *)
                    continue
                ;;
            esac
        done
    }
)

if [ "$3" -eq 1 ]; then
    NEWS=$(cat NEWS)
    NEWS="${NEWS#*
=======================
}"
    NEWS="${NEWS%%
=======================
*}"
    NEWS="${NEWS%


*}"
    NEWS="NEWS:
$NEWS"
else
    NEWS='No news are available for this release.'
fi

case "$4" in
    0) EDIT= ;;
    1) EDIT='-e' ;;
esac

if [ "$SRC_LOG" ] && [ ! "$SRC_LOG" = "$LOG" ]; then
    git tag "$EDIT" -m \
"syscfg $1

$NEWS

- Filtered log of core changes:
$SRC_LOG

- Complete log between $2 and $1:
$LOG" -as "$1" HEAD
elif [ "$LOG" ]; then
    git tag "$EDIT" -m \
"syscfg $1

$NEWS

- Complete log between $2 and $1:
$LOG" -as "$1" HEAD
else
    git tag "$EDIT" -m "syscfg $1" -as "$1" HEAD
fi
