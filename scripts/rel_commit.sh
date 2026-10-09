set -e

case "${1:-x}" in
    '-h' | '--help' | 'x')
        printf "%s\n" '$1 = NEWS BOOL'

        exit 0
    ;;
esac

[ "$#" -eq 1 ] || { echo "Expected exactly 1 argument; got $#."; exit 2; }
case "$1" in
    0|1) ;;
    *) echo 'Bad $1/NEWS bool.'; exit 2 ;;
esac

case "$1" in
    0) NEWS= ;;
    1) NEWS='News are available in the description of the release tag.' ;;
esac

# not UTC
DATE=$(date +%Y%m%d)
Y="${DATE%????}"
M="$DATE"
M="${M#????}"
M="${M%??}"
case "$M" in
    01) M='January' ;;
    02) M='February' ;;
    03) M='March' ;;
    04) M='April' ;;
    05) M='May' ;;
    06) M='June' ;;
    07) M='July' ;;
    08) M='August' ;;
    09) M='September' ;;
    10) M='October' ;;
    11) M='November' ;;
    12) M='December' ;;
esac
D="${DATE#??????}"
case "$D" in
    0*) D="${D#0}" ;;
esac

FILE=$(cat ./src/syscfg.sh && printf "%s" .)
FILE="${FILE%.}"
FILE=$(
    x=

    printf "%s" "$FILE" | { while IFS= read -r LINE; do
        if [ "$x" ]; then
            x=$((x+1))
        fi

        case "$LINE" in
            '_version() {') x=0 ;;
        esac

        case "$x" in
            '2') LINE="'syscfg $DATE'"; x= ;;
        esac

        printf "%s\n" "$LINE"
    done

    if [ "$LINE" ]; then
        printf "%s" "$LINE"
    fi
    printf "%s" .; }
)
FILE="${FILE%.}"
printf "%s" "$FILE" > ./src/syscfg.sh
git add ./src/syscfg.sh

FILE=$(cat ./doc/syscfg.1 && printf "%s" .)
FILE="${FILE%.}"
FILE=$(
    flag=1

    printf "%s" "$FILE" | { while IFS= read -r LINE; do
        if [ "$flag" ]; then
            LINE=".TH SYSCFG \"1\" \"$M $D, $Y\" \"syscfg $DATE\" \"\""
            flag=
        fi

        printf "%s\n" "$LINE"
    done

    if [ "$LINE" ]; then
        printf "%s" "$LINE"
    fi
    printf "%s" .; }
)
FILE="${FILE%.}"
printf "%s" "$FILE" > ./doc/syscfg.1
git add ./doc/syscfg.1

git commit -sS -m "syscfg $DATE

$NEWS"
