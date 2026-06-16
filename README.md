## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [Build](#build)
4. [Releases](#releases)
5. [License](#license)
6. [Notice](#notice)

## Introduction

[`syscfg`](https://github.com/mscalindt/syscfg) is a general-purpose system
configuration utility that exposes a powerful administration API for
its clients to use.

```
$ git describe
20260422
$ ./syscfg --help
Usage: syscfg [options] [--] FILE [ARG...]
Declarative OS configuration.

Options:
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

For more information, refer to the man page: `man syscfg`.
```

System runtime and _make_ dependencies (GNU/Linux-oriented packages):

* `coreutils` (POSIX subset)
  - `install` (_make_)
* `dash` (POSIX sh)
* `gawk` (POSIX awk)
* `make` (POSIX make; _make_)

Optional runtime dependencies (GNU/Linux-oriented packages):

* `e2fsprogs`
* `less`
* `util-linux`

## Features

* 99.9% human written and architectured.
* Portable octal to binary file mechanism.
* Write avoidance and integrity.
* Written in POSIX shell language.

## Build

Clone the repository using the `--recursive` option to ensure all submodules
are downloaded.

```
git clone --recursive https://github.com/mscalindt/syscfg
cd syscfg
make
```

If the repository has been cloned without the submodules, they can be
initialized and fetched with:

```
git submodule update --init --recursive
```

## Releases

Source code releases follow the `YYYYMMDD` format.

To list the available releases, check out the available tags or use `git tag`.

For updates on recent changes, see the [NEWS](NEWS) file. Changes that break
backward compatibility should always be mentioned.

## License

[KEYCLA 1.0 License](LICENSE)

For a list of external dependencies and their licenses,
refer to the [DEPENDENCIES](DEPENDENCIES) file.

## Notice

This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

For detailed information on external dependencies,
see the [DEPENDENCIES](DEPENDENCIES) file.
