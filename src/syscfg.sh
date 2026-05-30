#!/bin/sh
#
# Use to_octal() or to_octal_offset() to obtain the POSIX shell-compatible
# octal escape sequence(s) of octal byte streams produced by `od -b -An` or
# `od -b`, respectively.

_copyright() {
    printf "%s\n" \
'Copyright (C) 2021-2026 Dimitar Yurukov <mscalindt@protonmail.com>'
}

_description() {
    printf "%s\n" \
'Declarative OS configuration.'
}

_license() {
    printf "%s\n" \
'License KEYCLA: KEYCLA 1.0 License'
}

_notice() {
    printf "%s\n" \
'This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.'
}

_misc() {
    printf "%s\n" \
'Options:
  -d, --disable-write-avoidance
                                disable write avoidance
      --disable-write-avoidance-group
                                disable the write avoidance assert of group
                                ownership
      --disable-write-avoidance-perm
                                disable the write avoidance assert of
                                permissions (mode)
      --disable-write-avoidance-type
                                disable the write avoidance assert of object
                                type
      --disable-write-avoidance-type-attr
                                disable the write avoidance assert of object
                                type attributes
      --disable-write-avoidance-user
                                disable the write avoidance assert of user
                                ownership
  -D, --disable-write-sync      disable write synchronization
      --disable-write-sync-group
                                disable the write synchronization for group
                                ownership
      --disable-write-sync-perm
                                disable the write synchronization for
                                permissions (mode)
      --disable-write-sync-type
                                disable the write synchronization for object
                                type
      --disable-write-sync-type-attr
                                disable the write synchronization for object
                                type attributes
      --disable-write-sync-user
                                disable the write synchronization
                                for user ownership
  -n, --client-name <NAME>      specify the client name
      --no-color                do not use color escape sequences
  -o, --output <PATH>           specify a file path to write the client output
                                to
  -p, --pager <NAME>            specify a pager to use if required
  -s, --source <PATH>           specify a file path to source
  -S, --silent                  disable all syscfg output
      --silent-cmd              disable command output
      --silent-cmd-info         disable commands to be ran information
      --silent-write            disable write content information
      --silent-write-avoidance  disable write avoidance information
      --silent-write-stat       disable write statistics information
      --status-pager            send the client output to a pager
  -w, --write-always            elevate to state "hard overwrite" all (soft)
                                overwrites
  -W, --write-forced            elevate to state "soft overwrite" all default
                                writes
      --help     display this help text and exit
      --version  display version information and exit

For more information, refer to the man page: `man syscfg`.'
}

_usage() {
    printf "%s\n" \
'Usage: syscfg [options] [--] FILE [ARG...]'
}

_version() {
    printf "%s\n" \
'syscfg 20260530'
}

helper_functions() { # START helper_functions
#! .desc:
# Create a parent directory respecting the API specification
#! .params:
# <$@> - __write()
# <$1> - path
#! .uses.var:
# <_pchunk> - string;
#             path
#! .rc:
# (0) success
# (*) error
#! .desc.ext:
# Supported hints:
# `-gid`: Specify GID to set;
# `-group`: Specify group name to set;
# `-uid`: Specify UID to set;
# `-user`: Specify user name to set.
#
# For more information, refer to the documentation of __write(), for_pchunk(),
# and hint().
#.
_mkdir() {
    [ ! -e "$_pchunk" ] || return 0
    [ "$3" != "$_pchunk" ] || return 0

    shift 4; set -- "$_pchunk" "$@"

    mkdir "$1" || return "$?"

    if hint 1 1 -uid "$@" || hint 1 1 -user "$@"; then
        set -- "$_hint" "$@"

        if hint 2 1 -gid "$@" || hint 2 1 -group "$@"; then
            chown -h "$1"":$_hint" -- "$2" || return "$?"
        else
            chown -h "$1" -- "$2" || return "$?"
        fi

        shift
    elif hint 1 1 -gid "$@" || hint 1 1 -group "$@"; then
        chgrp -h "$_hint" -- "$1" || return "$?"
    fi

    return 0
}

#! .desc:
# Print bytes in human-readable fmt: "N" "X"iB / "N" "X"B
#! .params:
# <$1> - bytes
#! .rc:
# (0) success
# (*) error
#! .ec:
# (255) input error
#.
bytes_size() {
    assert -eq "$#" 1 || exit 255

    awk -v 'bytes'="$1" '
	function hsize(x, base) {
		basesuf = (base == "1024") ? "iB" : "B"

		s = "BKMGTEPYZ"
		while (x >= base && length(s) > 1)
			{x /= base; s = substr(s, 2)}
		s = substr(s, 1, 1)

		xf = (s == "B") ? "%d" : "%.2f"

		if (s != "B")
			s = s basesuf

		printf((xf " %s"), x, s)
	}

	BEGIN {
		printf hsize(bytes, 1024)
		printf " / "
		print hsize(bytes, 1000)
	}
    '
}

#! .desc:
# Remove the filesystem flag protection of a physical file
#! .params:
# <$1> - path
#! .rc:
# (0) success
#! .ec:
# (255) input error
#.
chattr_remove() {
    assert -eq "$#" 1 || exit 255

    command -v chattr > /dev/null 2>&1 && \
    [ -f "$1" ] && \
    [ ! -h "$1" ] && \
    chattr -ia -- "$1" > /dev/null 2>&1 || return 0
}

#! .desc:
# Execute a command (wrapper)
#! .params:
# <$@> - __cmd()
#! .rc:
# (0) success
# (*) error
#! .ec:
# (255) input error
#! .desc.ext:
# For more information, refer to the documentation of __cmd().
#.
cmd() {
    hints_offset 0 0 "$@" && shift "$_offset"

    [ "$1" ] || {
        err -red - '${0##*/}: Missing command specification.'

        exit 255
    }

    cmd_exec "$@"
}

#! .desc:
# Execute a command
#! .params:
# <$1> - command
# [$2]+ - command argument
#! .rc:
# (0) success
# (*) error
#! .desc.ext:
# This function exists to aid in modifying behavior modularly.
#.
cmd_exec() {
    command -- "$@"
}

#! .desc:
# Output command information
#! .params:
# <$@> - __cmd()
#! .rc:
# (0) success
#! .desc.ext:
# For more information, refer to the documentation of __cmd().
#.
cmd_info() {
    hints_offset 0 0 "$@" && shift "$_offset"

    [ "$1" ] || return 0

    __info -white - 'Running command:'

    info -white -- '`'
    info - -- "$@"
    info -white - '`'

    return 0
}

#! .desc:
# Generate fed() format
#! .params:
# <$1> - N
# <[$2]> - file content
# <$@> - __ed()
#! .gives.var:
# (0) <_fmt> - [string]
#! .rc:
# (0) success
# (*) error
#! .ec:
# (255) input error
#! .desc.ext:
# $1 is a whole number that specifies the number of arguments to offset, to
# skip any __ed() arguments accordingly.
#
# For more information, refer to the documentation of __ed() and fed().
#.
ed_fmt() {
    assert -whole-n "$1" || exit 255

    _a="$2"; shift "$((2 + $1))"; set -- "$_a" "$@"
    hints_offset 1 0 "$@"
    _a="$1"; shift "$((1 + _offset))"; set -- "$_a" "$@"

    fed "$@"
}

#! .desc:
# Execute fed() format
#! .params:
# <[$1]> - log file path
# <[$2]> - file content
# <$3> - format
#! .gives.var:
# (0) <_file> - [string]
#! .rc:
# (0) success
# (*) error
#! .desc.ext:
# The format must be an evaluable array of arguments.
#
# For more information, refer to the documentation of __ed(), fed(), and
# libfile().
#.
ed_exec() {
    _a="$1"; _b="$2"; eval set -- "$3"

    libfile "$_a" "$_b" "$@"
}

#! .desc:
# Assert the content and state of a write is equal on the filesystem
#! .params:
# <$@> - __write()
#! .rc:
# (0) true
# (1) false
#! .desc.ext:
# We do not yet have write avoidance support for types `-c` and `-l`.
#
# For more information, refer to the documentation of __write().
#.
fs_equiv() {
    case "$1" in
        '-c' | '-l') return 1 ;;
    esac

    { ! hint 4 0 -no-avoid "$@"; } || return 1

    # Assert the state, i.e. the inode type and attributes.
    fs_equiv_type "$@" || return 1
    fs_equiv_type_attr "$@" || return 1
    fs_equiv_owner "$@" || return 1
    fs_equiv_group "$@" || return 1
    fs_equiv_perm "$@" || return 1

    # Assert the content.
    case "$1" in
        '-o')
            awk '
function mod_string(input) {
	res = ""

	gsub(/[ \n]+/, "", input)
	for (i = 1; i <= length(input); i += 3) {
		octal = substr(input, i, 3)
		res = res "\\0" octal
	}

	return res
}

BEGIN {
	str=ARGV[1]
	file_str=ARGV[2]
	delete ARGV

	exit (mod_string(file_str) == str) ? 0 : 1;
}
            ' "$2" "$(od -b -An -- "$3")" || return 1
        ;;
        '-w')
            file_preload -cat "$3"

            [ "$_file" = "$2" ] || return 1
        ;;
    esac

    return 0
}

#! .desc:
# Assert the GID is equal on the filesystem
#! .params:
# <$@> - __write()
#! .rc:
# (0) true
# (1) false
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
fs_equiv_group() {
    case "$1" in
        '-o' | '-w')
            # Get the fourth field (group) of `ls -ld` of $3 into $_a.
            _a="$(ls -ld -- "$3")"
            _a="${_a%%'
'*}"
            _a="${_a#*' '}"
            _a="${_a#*' '}"
            _a="${_a#*' '}"
            _a="${_a%%' '*}"

            set -- "$_a" "$@"

            if hint 5 0 -group "$@"; then
                [ ! "$1" = "$_hint" ] || return 0
            else
                [ ! "$1" = "$(id -ng)" ] || return 0
            fi

            if hint 5 0 -gid "$@"; then
                [ ! "$1" = "$_hint" ] || return 0
            else
                [ ! "$1" = "$(id -g)" ] || return 0
            fi
        ;;
    esac

    return 1
}

#! .desc:
# Assert the UID is equal on the filesystem
#! .params:
# <$@> - __write()
#! .rc:
# (0) true
# (1) false
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
fs_equiv_owner() {
    case "$1" in
        '-o' | '-w')
            # Get the third field (owner) of `ls -ld` of $3 into $_a.
            _a="$(ls -ld -- "$3")"
            _a="${_a%%'
'*}"
            _a="${_a#*' '}"
            _a="${_a#*' '}"
            _a="${_a%%' '*}"

            set -- "$_a" "$@"

            if hint 5 0 -user "$@"; then
                [ ! "$1" = "$_hint" ] || return 0
            else
                [ ! "$1" = "$(id -nu)" ] || return 0
            fi

            if hint 5 0 -uid "$@"; then
                [ ! "$1" = "$_hint" ] || return 0
            else
                [ ! "$1" = "$(id -u)" ] || return 0
            fi
        ;;
    esac

    return 1
}

#! .desc:
# Assert the file mode is equal on the filesystem
#! .params:
# <$@> - __write()
#! .rc:
# (0) true
# (1) false
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
fs_equiv_perm() {
    case "$1" in
        '-o' | '-w')
            # Get the first field (file mode; "%c%s%s%s%c") of `ls -ld` of $3
            # into $_a.
            _a="$(ls -ld -- "$3")"
            _a="${_a%%' '*}"

            # Strip the last "%c" if present.
            [ "${#_a}" -eq 10 ] || _a="${_a%?}"

            set -- "$_a" "$@"

            if hint 5 0 -mode "$@"; then
                fmode_octal "$_hint"

                # `-` = "regular file"
                [ ! "$1" = "-$_mode" ] || return 0
            else
                # `-`, `rw-r--r--` = "regular file", 0644
                [ ! "$1" = '-rw-r--r--' ] || return 0
            fi
        ;;
    esac

    return 1
}

#! .desc:
# Assert the object type is equal on the filesystem
#! .params:
# <$@> - __write()
#! .rc:
# (0) true
# (1) false
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
fs_equiv_type() {
    case "$1" in
        '-o' | '-w')
            ftype "$3" && [ "$_type" = 'F' ] || return 1
        ;;
    esac

    return 0
}

#! .desc:
# Assert the attributes of the object type are equal on the filesystem
#! .params:
# <$@> - __write()
#! .rc:
# (0) true
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
fs_equiv_type_attr() {
    return 0
}

#! .desc:
# Query the presence of an independent hint among arguments
#! .params:
# <$1> - LTR N offset
# <$2> - RTL N offset
# <$3> - hint
# [$4]+ - argument
#! .gives.var:
# (0) <_hint> - [string];
#               [hint argument]
#! .rc:
# (0) true
# (1) false
#! .ec:
# (255) input error
#! .desc.ext:
# $1/$2 are whole numbers that specify count of arguments to offset LTR/RTL,
# respectively. The offset is used to skip unrelated arguments.
#
# Hint `--` will be respected at all times.
#
# For more information, refer to the documentation of hint_set().
#.
hint() {
    assert -min "$#" 2 || exit 255
    assert -whole-n "$1" || exit 255
    assert -whole-n "$2" || exit 255

    # Let an independent implementation dictate the outcome. This could be
    # desirable when, for example, a hint is to be enabled (or disabled)
    # globally.
    #
    # By default, it is expected hint_act() to return false to proceed with
    # the original hint query logic. Shall hint_act() return true, it is
    # required that $_act is set to either `0` or `1` to fulfill the outcome.
    if hint_act "$@"; then
        case "$_act" in
            0|1) return "$_act" ;;
        esac

        err -red - '${0##*/}: Invalid hint action:' "$_act"

        exit 255
    fi

    _rtl_offset="$2"; _hint="$3"; shift "$((3 + $1))"

    while [ "$(($# - _rtl_offset))" -ge 1 ]; do
        case "$1" in
            "$_hint") ;;
            '--') break ;;
            *) shift && continue ;;
        esac

        hint_set 0 0 "$@" || {
            err -red - '${0##*/}: Invalid hint:' "$1"

            exit 255
        }

        _hint="$_hint_arg"

        return 0
    done

    return 1
}

#! .desc:
# Dictate the outcome of a hint query independently
#! .params:
# <$@> - hint()
#! .gives.var:
# (0) <_act> - integer;
#              `0` = act true; `1` = act false
#! .rc:
# (0) true
# (1) false
#! .desc.ext:
# This function exists to aid in modifying behavior modularly.
#
# For more information, refer to the documentation of hint().
#.
hint_act() {
    return 1
}

#! .desc:
# Set the hint properties of the first encountered argument
#! .params:
# <$1> - LTR N offset
# <$2> - RTL N offset
# [$3]+ - argument
#! .gives.var:
# (0) <_hint> - string;
#               hint string
# (0) <_hint_arg> - [string];
#                   [hint argument]
# (0) <_offset> - integer;
#                 shift count to offset the hint and its argument(s)
#! .rc:
# (0) success
# (1) error
#! .ec:
# (255) input error
#! .desc.ext:
# Recognized hints:
# `--`: End of hints;
# `-color`: Use color;
# `-crc`, <string>: CRC32 string;
# `-del`: 'Delete' action/operation;
# `-gid`, <string>: Group ID;
# `-group`, <string>: Group name;
# `-log`, <file path>: Log file path;
# `-mode`, <[string]>: Octal mode;
# `-no-avoid`: No write avoidance;
# `-no-sanit`: No environment sanitization;
# `-out-save`, <variable name>: Save &1 (stdout);
# `-req-out`: Require &1 (stdout);
# `-sanit`: Environment sanitization;
# `-trunc`: 'Truncate' action/operation;
# `-uid`, <string>: User ID;
# `-user`, <string>: User name.
#
# $1/$2 are whole numbers that specify count of arguments to offset LTR/RTL,
# respectively. The offset is used to skip unrelated arguments.
#
# The function can only ever be successful when the first argument is
# a recognized hint; otherwise error (rc 1) is returned.
#.
hint_set() {
    assert -whole-n "$1" || exit 255
    assert -whole-n "$2" || exit 255

    _rtl_offset="$2"
    shift "$((2 + $1))"

    case "$1" in
        '--' | '-color' | '-del' | '-no-avoid' | '-no-sanit' | '-req-out' | \
        '-sanit' | '-trunc')
            [ "$(($# - _rtl_offset))" -ge 1 ] || return 1

            _hint="$1"
            _hint_arg=
            _offset=1

            return 0
        ;;
        '-mode')
            [ "$(($# - _rtl_offset))" -ge 2 ] || {
                err -red - '${0##*/}: Missing argument specification:' "$1"
                err -red - '${0##*/}: Use empty quotes to define no value.'

                exit 255
            }

            _hint="$1"
            _hint_arg="$2"
            _offset=2

            return 0
        ;;
        '-crc' | '-gid' | '-group' | '-log' | '-out-save' | '-uid' | '-user')
            [ "$(($# - _rtl_offset))" -ge 2 ] && [ "$2" ] || {
                err -red - '${0##*/}: Missing argument specification:' "$1"

                exit 255
            }

            _hint="$1"
            _hint_arg="$2"
            _offset=2

            return 0
        ;;
    esac

    return 1
}

#! .desc:
# Provide shift count to offset all hints in arguments
#! .params:
# <$1> - LTR N offset
# <$2> - RTL N offset
# [$3]+ - argument
#! .gives.var:
# (0) <_offset> - integer;
#                 LTR shift count to offset all hints
#! .rc:
# (0) success
#! .ec:
# (255) input error
#! .desc.ext:
# $1/$2 are whole numbers that specify count of arguments to offset LTR/RTL,
# respectively. The offset is used to skip unrelated arguments.
#
# For more information, refer to the documentation of hint().
#.
hints_offset() {
    assert -whole-n "$1" || exit 255

    _rtl_offset="$2"
    shift "$((2 + $1))"
    set -- 2 "$_rtl_offset" "$@"

    while hint_set "$1" "$2" "$@"; do
        _offset="$((_offset + $1))"; shift; set -- "$_offset" "$@"

        case "$_hint" in
            '--') break ;;
        esac
    done

    _offset="$(($1 - 2))"
}

#! .desc:
# Synchronize inode state for a write
#! .params:
# <$@> - __write()
#! .rc:
# (0) success
# (*) error
#! .desc.ext:
# We do not yet have write synchronization support for types `-c` and `-l`.
#
# For more information, refer to the documentation of __write().
#.
inode_align() {
    case "$1" in
        '-c' | '-l') return 1 ;;
    esac

    { ! hint 4 0 -no-sync "$@"; } || return 1

    inode_align_type "$@" && \
    inode_align_type_attr "$@" && \
    inode_align_owner "$@" && \
    inode_align_group "$@" && \
    inode_align_perm "$@"
}

#! .desc:
# Synchronize the group of a write
#! .params:
# <$@> - __write()
#! .rc:
# (0) success
# (*) error
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
inode_align_group() {
    case "$1" in
        '-o' | '-w')
            # Get the fourth field (group) of `ls -ld` of $3 into $_a. It is
            # ambiguous whether this value is the GID or the group name.
            _a="$(ls -ld -- "$3")"
            _a="${_a%%'
'*}"
            _a="${_a#*' '}"
            _a="${_a#*' '}"
            _a="${_a#*' '}"
            _a="${_a%%' '*}"

            set -- "$_a" "$@"

            if hint 5 0 -group "$@" || hint 5 0 -gid "$@"; then
                if hint 5 0 -group "$@"; then
                    if [ "$1" != "$_hint" ] || [ "$1" != "$(id -ng)" ]; then
                        __cmd -- \
                        chgrp -h "$_hint" -- "$4" && return 0 || return "$?"
                    fi
                fi

                if hint 5 0 -gid "$@"; then
                    if [ "$1" != "$_hint" ] || [ "$1" != "$(id -g)" ]; then
                        __cmd -- chgrp -h "$_hint" -- "$4" || return "$?"
                    fi
                fi
            else
                if [ "$1" != "$(id -ng)" ] && [ "$1" != "$(id -g)" ]; then
                    __cmd -- chgrp -h "$(id -g)" -- "$4" || return "$?"
                fi
            fi
        ;;
    esac

    return 0
}

#! .desc:
# Synchronize the user of a write
#! .params:
# <$@> - __write()
#! .rc:
# (0) success
# (*) error
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
inode_align_owner() {
    case "$1" in
        '-o' | '-w')
            # Get the third field (owner) of `ls -ld` of $3 into $_a. It is
            # ambiguous whether this value is the UID or the user name.
            _a="$(ls -ld -- "$3")"
            _a="${_a%%'
'*}"
            _a="${_a#*' '}"
            _a="${_a#*' '}"
            _a="${_a%%' '*}"

            set -- "$_a" "$@"

            if hint 5 0 -user "$@" || hint 5 0 -uid "$@"; then
                if hint 5 0 -user "$@"; then
                    if [ "$1" != "$_hint" ] || [ "$1" != "$(id -nu)" ]; then
                        __cmd -- \
                        chown -h "$_hint" -- "$4" && return 0 || return "$?"
                    fi
                fi

                if hint 5 0 -uid "$@"; then
                    if [ "$1" != "$_hint" ] || [ "$1" != "$(id -u)" ]; then
                        __cmd -- chown -h "$_hint" -- "$4" || return "$?"
                    fi
                fi
            else
                if [ "$1" != "$(id -nu)" ] && [ "$1" != "$(id -u)" ]; then
                    __cmd -- chown -h "$(id -u)" -- "$4" || return "$?"
                fi
            fi
        ;;
    esac

    return 0
}

#! .desc:
# Synchronize the file mode of a write
#! .params:
# <$@> - __write()
#! .rc:
# (0) success
# (*) error
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
inode_align_perm() {
    case "$1" in
        '-o' | '-w')
            # Get the first field (file mode; "%c%s%s%s%c") of `ls -ld` of $3
            # into $_a.
            _a="$(ls -ld -- "$3")"
            _a="${_a%%' '*}"

            # Strip the last "%c" if present.
            [ "${#_a}" -eq 10 ] || _a="${_a%?}"

            set -- "$_a" "$@"

            if hint 5 0 -mode "$@"; then
                fmode_octal "$_hint"

                # `-` = "regular file"
                if [ ! "$1" = "-$_mode" ]; then
                    hint 5 0 -mode "$@"
                    __cmd -- chmod "$_hint" -- "$4" || return "$?"
                fi
            else
                # `-`, `rw-r--r--` = "regular file", 0644
                if [ ! "$1" = '-rw-r--r--' ]; then
                    __cmd -- chmod 0644 -- "$4" || return "$?"
                fi
            fi
        ;;
    esac

    return 0
}

#! .desc:
# Synchronize object type of a write
#! .params:
# <$@> - __write()
#! .rc:
# (0) success
# (*) error
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
inode_align_type() {
    fs_equiv_type "$@"
}

#! .desc:
# Synchronize the attributes of the object type of a write
#! .params:
# <$@> - __write()
#! .rc:
# (0) success
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
inode_align_type_attr() {
    fs_equiv_type_attr "$@"
}

#! .desc:
# Print POSIX shell-compatible octal escape sequence(s) of `od -b -An` string
#! .params:
# <[$1]> - string
#! .rc:
# (0) success
#! .ec:
# (255) input error
#.
to_octal() {
    assert -eq "$#" 1 || exit 255

    for _octal in $1; do
        printf "%s" "\\0$_octal"
    done

    return 0
}

#! .desc:
# Print POSIX shell-compatible octal escape sequence(s) of `od -b` string
#! .params:
# <[$1]> - string
#! .rc:
# (0) success
# (*) error
#! .ec:
# (255) input error
#.
to_octal_offset() {
    to_octal_offset_() { printf "%s" "${1#"${1%%[!0123456789]*}"}"; }

    assert -eq "$#" 1 || exit 255

    to_octal "$(for_sline "$1" to_octal_offset_)"
}

#! .desc:
# Execute 'umount' on a directory
#! .params:
# <$1> - directory
#! .rc:
# (0) success
#! .ec:
# (255) input error
#.
unmount() {
    assert -eq "$#" 1 || exit 255

    command -v umount > /dev/null 2>&1 && \
    [ -e "$1" ] && \
    [ -d "$1" ] && \
    umount -Rf -- "$1" > /dev/null 2>&1 || return 0
}

#! .desc:
# Validate a write is necessary
#! .params:
# <$@> - __write()
#! .rc:
# (0) true
# (1) false
# (2) ENOENT
# (17) EEXIST
#! .ec:
# (255) input error
#! .desc.ext:
# For more information, refer to the documentation of __write() and fs_equiv().
#.
validate_write() {
    [ "$2" ] || { err -red - 'Missing OBJ.'; exit 255; }
    [ "$3" ] || { err -red - 'Missing OBJ_PATH.'; exit 255; }

    case "$1" in
        '-c' | '-l')
            ftype "$2" || return 2
        ;;
        '-o')
            awk '
function is_valid_chunk(chunk) {
	return chunk ~ /^\\0[0-7]{3}$/ ? 0 : 1
}

BEGIN {
	string=ARGV[1]
	delete ARGV

	if (length(string) % 5 != 0)
		exit 1

	for (i = 1; i <= length(string); i += 5) {
		chunk = substr(string, i, 5)

		if (is_valid_chunk(chunk) == 1)
			exit 1
	}

	exit 0
}
    ' "$2" || { err -red - 'Bad OBJ; expected octal string.'; exit 255; }
        ;;
    esac

    path_strip "$3" 1 -floor
    if [ ! -w "$3" ] || [ ! -w "$_path" ]; then
        if [ "$(id -u)" != 0 ]; then
            err -red - 'EACCES:'

            ftype "$3" -err && {
                err - - " $3"
            } || {
                err -red -- '>'
                err - - " $3"
            }

            exit 13
        fi
    fi

    case "$4" in
        '-f') return 0 ;;
        '-o') ;;
        *) { ! ftype "$3"; } || { fs_equiv "$@" && return 1 || return 17; } ;;
    esac

    fs_equiv "$@" || return 0

    return 1
}

#! .desc:
# Perform a write
#! .params:
# <$@> - __write()
#! .rc:
# (0) success
# (*) error
#! .ec:
# (13) EACCES
#! .desc.ext:
# We do not yet have an in-place overwrite mechanism for types `-c` and `-l`.
# We do not yet have atomic overwrites.
#
# For more information, refer to the documentation of __write().
#.
write() {
    if ftype "$3"; then
        chattr_remove "$3"
        unmount "$3"

        # When the target object exists, try to align or else remove it.
        # Alignment is important for expected overwrite behavior when the inode
        # state itself forced a write, otherwise a write would keep occurring
        # in a circular chain of forced writes irrespective of the object
        # content.
        #
        # Types `-c` and `-l` are currently not supported and always removed.
        inode_align "$@" || rm -rf -- "$3" || return "$?"
    fi

    for_pchunk "$3" '' '' _mkdir "$@"

    # Atomic overwrites are currently not supported.
    case "$1" in
        '-c')
            cp -R -- "$2" "$3" || return "$?"
        ;;
        '-l')
            ln -sf -- "$2" "$3" || return "$?"
        ;;
        '-o')
            printf "%b" "$2" > "$3" || return "$?"
        ;;
        '-w')
            printf "%s" "$2" > "$3" || return "$?"
        ;;
    esac

    if hint 4 0 -uid "$@" || hint 4 0 -user "$@"; then
        set -- "$_hint" "$@"

        if hint 5 0 -gid "$@" || hint 5 0 -group "$@"; then
            chown -h "$1"":$_hint" -- "$4" || return "$?"
        else
            chown -h "$1" -- "$4" || return "$?"
        fi

        shift
    elif hint 4 0 -gid "$@" || hint 4 0 -group "$@"; then
        chgrp -h "$_hint" -- "$3" || return "$?"
    fi

    if hint 4 0 -mode "$@"; then
        chmod "$_hint" -- "$3" || return "$?"
    fi

    return 0
}

#! .desc:
# Output write information
#! .params:
# <$@> - __write()
#! .rc:
# (0) success
#! .ec:
# (2) ENOENT
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
write_info() {
    case "$1$4" in
        '-c-f') __info -white - 'Will write (copy) from/to (OW_HARD):' ;;
        '-c-o') __info -white - 'Will write (copy) from/to (OW_SOFT):' ;;
        '-c') __info -white - 'Will write (copy) from/to:' ;;
        '-l-f') __info -white - 'Will symbolic link source/target (OW_HARD):' ;;
        '-l-o') __info -white - 'Will symbolic link source/target (OW_SOFT):' ;;
        '-l') __info -white - 'Will symbolic link source/target:' ;;
        '-o-f') __info -white - 'Will write a binary file (OW_HARD):' ;;
        '-o-o') __info -white - 'Will write a binary file (OW_SOFT):' ;;
        '-o') __info -white - 'Will write a binary file:' ;;
    esac

    if hint 4 0 -log "$@"; then
        case "$1$4" in
            '-w-f') __info -white - 'Will update a file (OW_HARD):' ;;
            '-w-o') __info -white - 'Will update a file (OW_SOFT):' ;;
            '-w') __info -white - 'Will update a file:' ;;
        esac
    else
        case "$1$4" in
            '-w-f') __info -white - 'Will write a file (OW_HARD):' ;;
            '-w-o') __info -white - 'Will write a file (OW_SOFT):' ;;
            '-w') __info -white - 'Will write a file:' ;;
        esac
    fi

    case "$1" in
        '-c' | '-l')
            # Do not assume the path still exists.
            ftype "$2" -info && {
                info - - " $2"
            } || {
                err -red - 'ENOENT:'

                err -red -- '>'
                err - - " $2"

                exit 2
            }

            info -white -- '>'
            info - - " $3"
        ;;
        '-o' | '-w')
            info -white -- F
            info - - " $3"
        ;;
    esac

    return 0
}

#! .desc:
# Output write avoidance information
#! .params:
# <$@> - __write()
#! .rc:
# (0) success
#! .ec:
# (2) ENOENT
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
write_info_avoidance() {
    case "$1$4" in
        '-c-o') __info -white - 'Copy avoided (OW_SOFT):' ;;
        '-c') __info -white - 'Copy avoided:' ;;
        '-l-o') __info -white - 'Symbolic link avoided (OW_SOFT):' ;;
        '-l') __info -white - 'Symbolic link avoided:' ;;
        '-o-o') __info -white - 'Binary write avoided (OW_SOFT):' ;;
        '-o') __info -white - 'Binary write avoided:' ;;
        '-w-o') __info -white - 'File write avoided (OW_SOFT):' ;;
        '-w') __info -white - 'File write avoided:' ;;
    esac

    # Do not assume the path still exists.
    ftype "$3" -info && {
        info - - " $3"
    } || {
        err -red - 'ENOENT:'

        err -red -- '>'
        err - - " $3"

        exit 2
    }

    return 0
}

#! .desc:
# Output write statistics
#! .params:
# <$@> - __write()
#! .rc:
# (0) success
#! .desc.ext:
# For more information, refer to the documentation of __write().
#.
write_info_stat() {
    if hint 4 0 -color "$@" && hint 4 0 -log "$@"; then
        if [ ! -e "$_hint" ]; then
            __info -yellow - 'No log available.'

            return 0
        fi

        while IFS=" " read -r _n _line || [ "$_line" ]; do
            set -- "$_line"

            case "$_n" in
                *'+') info -green -- "$_n " && info - - "$1" ;;
                *'-') info -red -- "$_n " && info - - "$1" ;;
            esac
        done < "$_hint"
    elif hint 4 0 -log "$@"; then
        if [ ! -e "$_hint" ]; then
            __info -yellow - 'No log available.'

            return 0
        fi

        while IFS= read -r _line || [ "$_line" ]; do
            info - - "$1"
        done < "$_hint"
    else
        case "$1" in
            '-o')
                info -white -- 'SIZE: '
                ccount \\ "$2" && bytes_size "$_count"
            ;;
            '-w')
                case "$2" in
                    *'
')
                        info -white - '0:'

                        info - -- "$2"
                    ;;
                    *)
                        info -white - '0 (no final newline):'

                        info - - "$2"
                    ;;
                esac
            ;;
        esac
    fi

    return 0
}
} # END helper_functions

# Maintainer note for any functions in client_lib():
#
# Utility functions shall always begin with two underscore characters.
client_lib() { # START client_lib
#! .desc:
# Execute an action on an object on the filesystem
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# [OBJ] - [string]
# <OBJ_PATH> - string;
#              path
#! .rc:
# (0) success
# (*) error
#! .ec:
# (2) ENOENT
# (13) EACCES
# (255) input error
#! .desc.ext:
# Supported hints:
# `-del`: Delete $OBJ_PATH;
# `-no-sanit`: Preserve $OBJ and $OBJ_PATH;
# `-trunc`: Truncate $OBJ_PATH.
#
# For more information, refer to the documentation of hint().
#.
__action() {
    set -- "$OBJ" "$OBJ_PATH" "$@"

    [ "$2" ] || {
        err -red - 'Missing OBJ_PATH.'; exit 255
    }

    path_strip "$2" 1 -floor
    if [ ! -w "$2" ] || [ ! -w "$_path" ]; then
        if [ "$(id -u)" != 0 ]; then
            err -red - 'EACCES:'

            ftype "$2" -err && {
                err - - " $2"
            } || {
                err -red -- '>'
                err - - " $2"
            }

            exit 13
        fi
    fi

    if hint 2 0 -trunc "$@"; then
        if ftype "$2"/; then
            rm -rf -- "$2"/* || return "$?"
        else
            { : > "$2"; } || return "$?"
        fi
    fi

    if hint 2 0 -del "$@"; then
        chattr_remove "$2"
        unmount "$2"
        rm -rf -- "$2" || return "$?"
    fi

    if hint 2 0 -no-sanit "$@"; then
        OBJ="$1"; OBJ_PATH="$2"
    fi

    return 0
}

#! .desc:
# Write a binary (octal) file
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         POSIX shell-compatible octal escape sequence(s) of the file
# <OBJ_PATH> - string;
#              path to write the file at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__bin_write() {
    __write -o "$OBJ" "$OBJ_PATH" '' "$@"
}

#! .desc:
# Write a binary (octal) file (overwrite by deletion)
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         POSIX shell-compatible octal escape sequence(s) of the file
# <OBJ_PATH> - string;
#              path to write the file at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__bin_write_ow_hard() {
    __write -o "$OBJ" "$OBJ_PATH" -f "$@"
}

#! .desc:
# Write a binary (octal) file (in-place + atomic overwrite)
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         POSIX shell-compatible octal escape sequence(s) of the file
# <OBJ_PATH> - string;
#              path to write the file at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__bin_write_ow_soft() {
    __write -o "$OBJ" "$OBJ_PATH" -o "$@"
}

#! .desc:
# Perform a command
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
# <$3> - --
# <$4> - command
# [$5]+ - command argument
#! .rc:
# (0) success
# (*) error
#! .ec:
# (1) hint assertion failed
# (255) input error
#! .desc.ext:
# Supported hints:
# `-out-save`: Specify variable name to save &1 to;
# `-req-out`: Empty &1 is a fatal error condition.
#
# For more information, refer to the documentation of cmd() and hint().
#.
__cmd() {
    assert -min "$#" 2 || exit 255

    cmd_info "$@"

    if hint 0 0 -req-out "$@" || hint 0 0 -out-save "$@"; then
        set -- "$(cmd "$@" && printf "%s" x)" "$@" || return "$?"
        set -- "${1%?}" "$@"
    else
        cmd "$@" && return 0 || return "$?"
    fi

    if hint 1 0 -req-out "$@"; then
        [ "$1" ] || {
            __err -red - 'No output has been received.'

            exit 1
        }
    fi

    if hint 1 0 -out-save "$@"; then
        arg_set "$_hint" "$1" || return "$?"
    fi

    return 0
}

#! .desc:
# Modify file data in-place according to format
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
# <$3> - --
# <$4>+ - operation
#! .uses.var:
# <OBJ> - string;
#         file data
# [OBJ_PATH] - string;
#              file path to read if $OBJ empty
#! .rc:
# (0) success
# (*) error
#! .ec:
# (1) CRC32 mismatch
# (255) input error
#! .desc.ext:
# Supported hints:
# `-crc`: Specify CRC32 string to assert the format against;
# `-log`: Specify log file path for libfile();
# `-no-sanit`: Preserve $OBJ_PATH alongside $OBJ.
#
# For more information, refer to the documentation of fed(), hint() and
# libfile().
#.
__ed() {
    set -- "$OBJ" "$OBJ_PATH" "$@"

    assert -min "$#" 4 || exit 255

    [ "$1" ] || {
        file_preload -cat "$2"

        shift && set -- "$_file" "$@"
    }

    # `1` = N offset = Skip $OBJ_PATH.
    ed_fmt 1 "$@"

    if [ "$_fmt" ]; then
        set -- "$_fmt" "$@"

        if hint 3 0 -crc "$@"; then
            _crc="$(printf "%s" "$1" | cksum)"
            _crc="${_crc%%' '*}"

            [ "$_crc" = "${_hint%
}" ] || {
                __err -red - "CRC32 mismatch. (hint = ${_hint%
}; crc = $_crc)"
                __err -red - 'Format string:'
                __err - - "$1"

                exit 1
            }
        fi

        if hint 3 0 -log "$@"; then
            ed_exec "$_hint" "$2" "$1" || return "$?"
        else
            ed_exec '' "$2" "$1" || return "$?"
        fi

        shift 2 && set -- "$_file" "$@"
    fi

    if hint 2 0 -no-sanit "$@"; then
        OBJ="$1"; OBJ_PATH="$2"
    else
        OBJ="$1"; OBJ_PATH=
    fi

    return 0
}

#! .desc:
# Print formatted text to stderr
#! .params:
# <$@> - err()
#! .desc.ext:
# For more information, refer to the documentation of err().
#.
__err() {
    _clr="$1"
    _fmt="$2"

    shift 2 && set -- "$_clr" "$_fmt" "[E $$ $CLIENT_NAME]" "$@"

    err "$@"
}

#! .desc:
# Write a file
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         file
# <OBJ_PATH> - string;
#              path to write the file at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__file_write() {
    __write -w "$OBJ" "$OBJ_PATH" '' "$@"
}

#! .desc:
# Write a file (overwrite by deletion)
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         file
# <OBJ_PATH> - string;
#              path to write the file at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__file_write_ow_hard() {
    __write -w "$OBJ" "$OBJ_PATH" -f "$@"
}

#! .desc:
# Write a file (in-place + atomic overwrite)
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         file
# <OBJ_PATH> - string;
#              path to write the file at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__file_write_ow_soft() {
    __write -w "$OBJ" "$OBJ_PATH" -o "$@"
}

#! .desc:
# Print formatted text
#! .params:
# <$@> - info()
#! .desc.ext:
# For more information, refer to the documentation of info().
#.
__info() {
    _clr="$1"
    _fmt="$2"

    shift 2 && set -- "$_clr" "$_fmt" "[I $$ $CLIENT_NAME]" "$@"

    info "$@"
}

#! .desc:
# Symbolic link an object on the filesystem
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         path
# <OBJ_PATH> - string;
#              path to link the object at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__obj_link() {
    __obj_link_ow_hard "$@"
}

#! .desc:
# Symbolic link an object on the filesystem (overwrite by deletion)
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         path
# <OBJ_PATH> - string;
#              path to link the object at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__obj_link_ow_hard() {
    __write -l "$OBJ" "$OBJ_PATH" -f "$@"
}

#! .desc:
# Symbolic link an object on the filesystem (in-place + atomic overwrite)
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         path
# <OBJ_PATH> - string;
#              path to link the object at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__obj_link_ow_soft() {
    __obj_link_ow_hard "$@"
}

#! .desc:
# Write (copy) an object on the filesystem
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         path
# <OBJ_PATH> - string;
#              path to copy the object at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__obj_write() {
    __obj_write_ow_hard "$@"
}

#! .desc:
# Write (copy) an object on the filesystem (overwrite by deletion)
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         path
# <OBJ_PATH> - string;
#              path to copy the object at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__obj_write_ow_hard() {
    __write -c "$OBJ" "$OBJ_PATH" -f "$@"
}

#! .desc:
# Write (copy) an object on the filesystem (in-place + atomic overwrite)
#! .params:
# [$1]+ - hint
# [$2]+ - hint argument
#! .uses.var:
# <OBJ> - string;
#         path
# <OBJ_PATH> - string;
#              path to copy the object at
#! .desc.ext:
# For more information, refer to the documentation of __write() and hint().
#.
__obj_write_ow_soft() {
    __obj_write_ow_hard "$@"
}

#! .desc:
# Validate and perform a write
#! .params:
# <$1> - type(
#     '-c' - filesystem copy
#     '-l' - symbolic link
#     '-o' - octal write
#     '-w' - file write
#     .
# )
# <$2> - string/object
# <$3> - path to write/copy/link the object at
# <[$4]> - state(
#     '-f' - hard overwrite ($3 is to be deleted)
#     '-o' - soft overwrite (in-place + atomic)
#     .
# )
# [$5]+ - hint
# [$6]+ - hint argument
#! .rc:
# (0) success
# (1) error
#! .ec:
# (1) error
# (2) ENOENT
# (17) EEXIST
# (255) input error
#! .desc.ext:
# Supported hints:
# `-color`: Colorize the `-log` parse assuming fed() format;
# `-gid`: Specify GID to assert/set;
# `-group`: Specify group name to assert/set;
# `-log`: Specify file path for write statistics;
# `-mode`: Specify file mode in octal to assert/set;
# `-no-avoid`: Disable write avoidance;
# `-no-sanit`: Preserve $OBJ and $OBJ_PATH;
# `-no-sync`: Disable write synchronization;
# `-sanit`: Delete hint paths, unset $OBJ and $OBJ_PATH;
# '-trunc': Truncate the path specified by `-log`;
# `-uid`: Specify UID to assert/set;
# `-user`: Specify user name to assert/set.
#
# Missing directory parents will be created and inherit ownership hints, with
# default (mkdir-driven) directory mode "777 - umask" (755) unaffected by
# the `-mode` hint.
#
# For more information, refer to the documentation of hint(), validate_write(),
# and write().
#.
__write() {
    assert -min "$#" 4 || exit 255
    case "$1" in '-c'|'-l'|'-o'|'-w') ;; *) exit 255 ;; esac
    case "$4" in '-f'|'-o') ;; *) [ ! "$4" ] || exit 255 ;; esac

    validate_write "$@" && _rc=0 || _rc="$?"

    case "$_rc" in
        0)
            write_info "$@"
            write_info_stat "$@"

            write "$@" || {
                case "$1" in
                    '-c') __err -red - "Copy error ($?):" ;;
                    '-l') __err -red - "Symbolic link error ($?):" ;;
                    '-o') __err -red - "Binary write error ($?):" ;;
                    '-w') __err -red - "File write error ($?):" ;;
                esac

                ftype "$3" -err && {
                    err - - " $3"
                } || {
                    err -red -- '>'
                    err - - " $3"
                }

                exit 1
            }
        ;;
        1)
            write_info_avoidance "$@"
        ;;
        2)
            case "$1" in
                '-c') __err -red - 'Copy error: ENOENT.' ;;
                '-l') __err -red - 'Symbolic link error: ENOENT.' ;;
                '-o') __err -red - 'Binary write error: ENOENT.' ;;
                '-w') __err -red - 'File write error: ENOENT.' ;;
            esac

            err -red -- '>'
            err - - " $2"

            exit 2
        ;;
        17)
            case "$1" in
                '-c') __err -red - 'Copy error: EEXIST.' ;;
                '-l') __err -red - 'Symbolic link error: EEXIST.' ;;
                '-o') __err -red - 'Binary write error: EEXIST.' ;;
                '-w') __err -red - 'File write error: EEXIST.' ;;
            esac

            # Do not assume the path still exists.
            ftype "$3" -err && {
                err - - " $3"
            } || {
                err -red - 'ENOENT:'

                err -red -- '>'
                err - - " $3"
            }

            exit 17
        ;;
        *)
            case "$1" in
                '-c') err -red - "Copy unhandled error: $_rc" ;;
                '-l') err -red - "Symbolic link unhandled error: $_rc" ;;
                '-o') err -red - "Binary write unhandled error: $_rc" ;;
                '-w') err -red - "File write unhandled error: $_rc" ;;
            esac

            exit 1
        ;;
    esac

    if hint 4 0 -trunc "$@" && hint 4 0 -log "$@"; then
        if [ -e "$_hint" ]; then
            { : > "$_hint"; } || {
                err -white - "Failed to truncate the log file. ($?)"

                return 1
            }
        fi
    fi

    if hint 4 0 -sanit "$@"; then
        if hint 4 0 -log "$@"; then
            if [ -e "$_hint" ]; then
                rm -rf "$_hint" || {
                    err -white - "Failed to delete the log file. ($?)"

                    return 1
                }
            fi
        fi

        unset OBJ OBJ_PATH
    elif hint 4 0 -no-sanit "$@"; then
        OBJ="$2"; OBJ_PATH="$3"
    fi

    return 0
}
} # END client_lib

#! .desc:
# Perform error handling on trap/signal
#! .params:
# [$1] - signal
# [$2] - exit status
#! .desc.ext:
# Recognized portable signals: 2/INT; 15/TERM.
#.
err_handler() {
    IFS=' 	''
'

    trap - 0 2 15

    case "$1" in
        INT|2)
            err - - "${0##*/}: Received INT/2 signal."
            kill -2 "$$"
        ;;
        TERM|15)
            err - - "${0##*/}: Received TERM/15 signal."
            kill -15 "$$"
        ;;
    esac

    exit "${2:-1}"
}

#! .desc:
# Wrapper for simultaneous opt() and opt_long()
#! .desc.ext:
# First "short form", then "long form". No hyphen prefixes.
#
# For more information, refer to the documentation of opt() and opt_long().
#.
option() {
    opt "$1" "$2" "$3" "$4" || opt_long "$1" "$2" "$3" "$5"
}

main() {
    # Set `-o posix` for compatibility with other shells to specify strict
    # POSIX compliance. We do not care if only `bash` specifically recognizes
    # `-o posix`.
    case "$(set -o posix 2> /dev/null && echo 0)" in
        0) set -o posix ;;
    esac

    set -e

    LC_ALL=C; export LC_ALL
    trap 'err_handler ERR $?' 0  # 0 = `EXIT` signal.
    trap 'err_handler INT' 2
    trap 'err_handler TERM' 15

    # Save options and operands in an evaluable string, then slice and save it
    # into options and operands; operands shall be a pseudo array of
    # single-quote-escaped arguments.
    #
    # To prevent ambiguity in slicing with the single-quote-escaped variable
    # assignments (options), any options taking arguments shall end with `;`,
    # for example option `foo` and argument `bar`: `foo='bar';`.
    # This is a requirement to make slicing based on `'--'` unambiguous.
    _arr=$(
        o_client_name() {
            arg_set _quot "$2"
            printf " %s" "client_name=$_quot;"
        }
        o_disable_write_avoidance() {
            printf " %s" "disable_write_avoidance='1';"
        }
        o_disable_write_avoidance_group() {
            printf " %s" "disable_write_avoidance_group='1';"
        }
        o_disable_write_avoidance_perm() {
            printf " %s" "disable_write_avoidance_perm='1';"
        }
        o_disable_write_avoidance_type() {
            printf " %s" "disable_write_avoidance_type='1';"
        }
        o_disable_write_avoidance_type_attr() {
            printf " %s" "disable_write_avoidance_type_attr='1';"
        }
        o_disable_write_avoidance_user() {
            printf " %s" "disable_write_avoidance_user='1';"
        }
        o_disable_write_sync() {
            printf " %s" "disable_write_sync='1';"
        }
        o_disable_write_sync_group() {
            printf " %s" "disable_write_sync_group='1';"
        }
        o_disable_write_sync_perm() {
            printf " %s" "disable_write_sync_perm='1';"
        }
        o_disable_write_sync_type() {
            printf " %s" "disable_write_sync_type='1';"
        }
        o_disable_write_sync_type_attr() {
            printf " %s" "disable_write_sync_type_attr='1';"
        }
        o_disable_write_sync_user() {
            printf " %s" "disable_write_sync_user='1';"
        }
        o_help() {
            printf " %s" "help='1';"
        }
        o_no_color() {
            printf " %s" "no_color='1';"
        }
        o_output() {
            arg_set _quot "$2"
            printf " %s" "output=$_quot;"
        }
        o_pager() {
            arg_set _quot "$2"
            printf " %s" "pager=$_quot;"
        }
        o_silent() {
            printf " %s" "silent='1';"
        }
        o_silent_cmd() {
            printf " %s" "silent_cmd='1';"
        }
        o_silent_cmd_info() {
            printf " %s" "silent_cmd_info='1';"
        }
        o_silent_write() {
            printf " %s" "silent_write='1';"
        }
        o_silent_write_avoidance() {
            printf " %s" "silent_write_avoidance='1';"
        }
        o_silent_write_stat() {
            printf " %s" "silent_write_stat='1';"
        }
        o_source() {
            arg_set _quot "$2"
            printf " %s" "source=$_quot;"
        }
        o_status_pager() {
            printf " %s" "status_pager='1';"
        }
        o_version() {
            printf " %s" "version='1';"
        }
        o_write_always() {
            printf " %s" "write_always='1';"
        }
        o_write_forced() {
            printf " %s" "write_forced='1';"
        }

        # Sanitize the environment.
        printf " %s" "client_name="
        printf " %s" "disable_write_avoidance="
        printf " %s" "disable_write_avoidance_group="
        printf " %s" "disable_write_avoidance_perm="
        printf " %s" "disable_write_avoidance_type="
        printf " %s" "disable_write_avoidance_type_attr="
        printf " %s" "disable_write_avoidance_user="
        printf " %s" "disable_write_sync="
        printf " %s" "disable_write_sync_group="
        printf " %s" "disable_write_sync_perm="
        printf " %s" "disable_write_sync_type="
        printf " %s" "disable_write_sync_type_attr="
        printf " %s" "disable_write_sync_user="
        printf " %s" "help="
        printf " %s" "output="
        printf " %s" "no_color="
        printf " %s" "pager="
        printf " %s" "silent="
        printf " %s" "silent_cmd="
        printf " %s" "silent_cmd_info="
        printf " %s" "silent_write="
        printf " %s" "silent_write_avoidance="
        printf " %s" "silent_write_stat="
        printf " %s" "source="
        printf " %s" "status_pager="
        printf " %s" "version="
        printf " %s" "write_always="
        printf " %s" "write_forced="

        # Parse options.
        while [ "$#" -ge 1 ]; do
            case "$1" in
                '-') opt_invalid "-"; exit 2 ;;
                '--') shift && break ;;
            esac

            # Options set again for $_opt and $_shift.
            if option "$1" "$2" -c 'n' 'client-name'; then
                o_client_name "$_match" "$_arg"
                option "$1" "$2" -c 'n' 'client-name'
            elif option "$1" "$2" -s 'd' 'disable-write-avoidance'; then
                o_disable_write_avoidance;
                option "$1" "$2" -s 'd' 'disable-write-avoidance'
            elif opt_long "$1" "$2" -s 'disable-write-avoidance-group'; then
                o_disable_write_avoidance_group;
                opt_long "$1" "$2" -s 'disable-write-avoidance-group'
            elif opt_long "$1" "$2" -s 'disable-write-avoidance-perm'; then
                o_disable_write_avoidance_perm;
                opt_long "$1" "$2" -s 'disable-write-avoidance-perm'
            elif opt_long "$1" "$2" -s 'disable-write-avoidance-type'; then
                o_disable_write_avoidance_type;
                opt_long "$1" "$2" -s 'disable-write-avoidance-type'
            elif opt_long "$1" "$2" -s 'disable-write-avoidance-type-attr'; then
                o_disable_write_avoidance_type_attr;
                opt_long "$1" "$2" -s 'disable-write-avoidance-type-attr'
            elif opt_long "$1" "$2" -s 'disable-write-avoidance-user'; then
                o_disable_write_avoidance_user;
                opt_long "$1" "$2" -s 'disable-write-avoidance-user'
            elif option "$1" "$2" -s 'D' 'disable-write-sync'; then
                o_disable_write_sync;
                option "$1" "$2" -s 'D' 'disable-write-sync'
            elif opt_long "$1" "$2" -s 'disable-write-sync-group'; then
                o_disable_write_sync_group;
                opt_long "$1" "$2" -s 'disable-write-sync-group'
            elif opt_long "$1" "$2" -s 'disable-write-sync-perm'; then
                o_disable_write_sync_perm;
                opt_long "$1" "$2" -s 'disable-write-sync-perm'
            elif opt_long "$1" "$2" -s 'disable-write-sync-type'; then
                o_disable_write_sync_type;
                opt_long "$1" "$2" -s 'disable-write-sync-type'
            elif opt_long "$1" "$2" -s 'disable-write-sync-type-attr'; then
                o_disable_write_sync_type_attr;
                opt_long "$1" "$2" -s 'disable-write-sync-type-attr'
            elif opt_long "$1" "$2" -s 'disable-write-sync-user'; then
                o_disable_write_sync_user;
                opt_long "$1" "$2" -s 'disable-write-sync-user'
            elif opt_long "$1" "$2" -s 'help'; then
                o_help;
                opt_long "$1" "$2" -s 'help'
            elif opt_long "$1" "$2" -s 'no-color'; then
                o_no_color;
                opt_long "$1" "$2" -s 'no-color'
            elif option "$1" "$2" -s 'S' 'silent'; then
                o_silent;
                option "$1" "$2" -s 'S' 'silent'
            elif option "$1" "$2" -c 'o' 'output'; then
                o_output "$_match" "$_arg"
                option "$1" "$2" -c 'o' 'output'
            elif option "$1" "$2" -c 'p' 'pager'; then
                o_pager "$_match" "$_arg"
                option "$1" "$2" -c 'p' 'pager'
            elif opt_long "$1" "$2" -s 'silent-cmd'; then
                o_silent_cmd;
                opt_long "$1" "$2" -s 'silent-cmd'
            elif opt_long "$1" "$2" -s 'silent-cmd-info'; then
                o_silent_cmd_info;
                opt_long "$1" "$2" -s 'silent-cmd-info'
            elif opt_long "$1" "$2" -s 'silent-write'; then
                o_silent_write;
                opt_long "$1" "$2" -s 'silent-write'
            elif opt_long "$1" "$2" -s 'silent-write-avoidance'; then
                o_silent_write_avoidance;
                opt_long "$1" "$2" -s 'silent-write-avoidance'
            elif opt_long "$1" "$2" -s 'silent-write-stat'; then
                o_silent_write_stat;
                opt_long "$1" "$2" -s 'silent-write-stat'
            elif option "$1" "$2" -c 's' 'source'; then
                o_source "$_match" "$_arg"
                option "$1" "$2" -c 's' 'source'
            elif opt_long "$1" "$2" -s 'status-pager'; then
                o_status_pager;
                opt_long "$1" "$2" -s 'status-pager'
            elif opt_long "$1" "$2" -s 'version'; then
                o_version;
                opt_long "$1" "$2" -s 'version'
            elif option "$1" "$2" -s 'w' 'write-always'; then
                o_write_always;
                option "$1" "$2" -s 'w' 'write-always'
            elif option "$1" "$2" -s 'W' 'write-forced'; then
                o_write_forced;
                option "$1" "$2" -s 'W' 'write-forced'
            else
                case "$1" in
                    '--'*) opt_invalid "$1"; exit 2 ;;
                    '-'*) opt_invalid "${1%"${1#??}"}"; exit 2 ;;
                    *) break ;;
                esac
            fi

            # If $_opt is still present and `--` is the prefix, it means `-`
            # has been specified as an option in a "group of options"
            # construct; reject it here.
            case "$_opt" in
                '--'*) opt_invalid "-"; exit 2 ;;
            esac

            shift; set -- "$_opt" "$@"; shift "$_shift"
        done

        printf " %s" "'--'"

        # Parse operands.
        for _arg in "$@"; do
            arg_set _quot "$_arg"; printf " %s" "$_quot"
        done
    )
    _opts="$_arr "
    _opts="${_opts%%"'--' "*}"
    _opts="${_opts%"${_opts##*[! ]}"}"
    _opds=" $_arr"
    _opds="${_opds#*" '--'"}"
    _opds="${_opds#"${_opds%%[! ]*}"}"
    set -- "$_opts" "$_opds"

    # Set variables according to any specified options.
    eval " $1"

    if [ "$help" ]; then
        _usage; _description; echo
        _misc;

        exit 0
    elif [ "$version" ]; then
        _version; echo
        _copyright; echo
        _license; _notice;

        exit 0
    fi

    if [ "$no_color" ]; then
        NO_COLOR=1
        readonly NO_COLOR
    fi

    if [ ! "$2" ]; then
        err - - "${0##*/}: No clients have been specified."

        exit 2
    fi

    if [ "$disable_write_avoidance" ]; then
        fs_equiv() { return 1; }
    fi

    if [ "$disable_write_avoidance_group" ]; then
        fs_equiv_group() { return 0; }
    fi

    if [ "$disable_write_avoidance_perm" ]; then
        fs_equiv_perm() { return 0; }
    fi

    if [ "$disable_write_avoidance_type" ]; then
        fs_equiv_type() { return 0; }
    fi

    if [ "$disable_write_avoidance_type_attr" ]; then
        fs_equiv_type_attr() { return 0; }
    fi

    if [ "$disable_write_avoidance_user" ]; then
        fs_equiv_owner() { return 0; }
    fi

    if [ "$disable_write_sync" ]; then
        inode_align() { return 1; }
    fi

    if [ "$disable_write_sync_group" ]; then
        inode_align_group() { return 0; }
    fi

    if [ "$disable_write_sync_perm" ]; then
        inode_align_perm() { return 0; }
    fi

    if [ "$disable_write_sync_type" ]; then
        inode_align_type() { return 0; }
    fi

    if [ "$disable_write_sync_type_attr" ]; then
        inode_align_type_attr() { return 0; }
    fi

    if [ "$disable_write_sync_user" ]; then
        inode_align_owner() { return 0; }
    fi

    if [ "$silent" ]; then
        __info() { info "$@"; }
        cmd_info() { return 0; }
        write_info() { return 0; }
        write_info_avoidance() { return 0; }
        write_info_stat() { return 0; }
    fi

    if [ "$silent_cmd" ]; then
        cmd_exec() { command -- "$@" > /dev/null; }
    fi

    if [ "$silent_cmd_info" ]; then
        cmd_info() { return 0; }
    fi

    if [ "$silent_write" ]; then
        write_info() { return 0; }
    fi

    if [ "$silent_write_avoidance" ]; then
        write_info_avoidance() { return 0; }
    fi

    if [ "$silent_write_stat" ]; then
        write_info_stat() { return 0; }
    fi

    if [ "$write_always" ]; then
        __bin_write_ow_soft() { __bin_write_ow_hard "$@"; }
        __file_write_ow_soft() { __file_write_ow_hard "$@"; }
        __obj_link_ow_soft() { __obj_link_ow_hard "$@"; }
        __obj_write_ow_soft() { __obj_write_ow_hard "$@"; }
    fi

    if [ "$write_forced" ]; then
        __bin_write() { __bin_write_ow_soft "$@"; }
        __file_write() { __file_write_ow_soft "$@"; }
        __obj_link() { __obj_link_ow_soft "$@"; }
        __obj_write() { __obj_write_ow_soft "$@"; }
    fi

    # Expand the pseudo array of single-quote-escaped file operand arguments.
    _opts="$1"; eval set -- "$2"; set -- "$_opts" "$@"

    if [ ! -f "$2" ]; then
        err - - "${0##*/}: Not a valid file: $2"

        exit 2
    fi

    eval " $1"
    if [ ! "$client_name" ]; then
        _name="$2"
        _name="${_name%"${_name##*[!/]}"}"
        _name="${_name##*/}"

        arg_set _quot "$_name"
        _opts="$1"; shift; set -- "$_opts client_name=$_quot;" "$@"
    fi

    eval " $1"
    # In the future, clients will be launched as an external command,
    # lexed and parsed by syscfg.
    (
        CLIENT_NAME="$client_name"
        readonly CLIENT_NAME

        if [ "$source" ]; then
            if [ ! -f "$source" ]; then
                err - - "${0##*/}: Not a valid file: $source"

                exit 1
            fi

            . "$source"
        fi

        eval " $1"
        pager="${pager:-less}"
        readonly pager
        if [ "$output" ]; then
            if [ -e "$output" ] || [ -h "$output" ]; then
                err - - "${0##*/}: Will not overwrite: $output"

                exit 1
            fi

            if [ "$status_pager" ]; then
                shift
                { \
                (. "$@" 2>&1) && \
                printf "%s" '01' || \
                printf "%s" "$?${#?}"; } | {
                    file_preload -
                    case "${_file#"${_file%?}"}" in
                        1) set -- "${_file#"${_file%??}"}" "${_file%??}" ;;
                        2) set -- "${_file#"${_file%???}"}" "${_file%???}" ;;
                        3) set -- "${_file#"${_file%????}"}" "${_file%????}" ;;
                    esac; set -- "${1%?}" "$2"
                    printf "%s" "$2" > "$output"
                    printf "%s" "$2" | "$pager"
                    return "$1"
                }
            else
                shift
                { . "$@"; } > "$output"
            fi
        else
            if [ "$status_pager" ]; then
                shift
                { \
                (. "$@" 2>&1) && \
                printf "%s" '01' || \
                printf "%s" "$?${#?}"; } | {
                    file_preload -
                    case "${_file#"${_file%?}"}" in
                        1) set -- "${_file#"${_file%??}"}" "${_file%??}" ;;
                        2) set -- "${_file#"${_file%???}"}" "${_file%???}" ;;
                        3) set -- "${_file#"${_file%????}"}" "${_file%????}" ;;
                    esac; set -- "${1%?}" "$2"
                    printf "%s" "$2" | "$pager"
                    return "$1"
                }
            else
                shift
                . "$@"
            fi
        fi
    )
    if [ ! "$silent" ]; then
        info -green - "$2:" 'Done!'
    fi

    return 0
}

helper_functions;
client_lib;
main "$@"
