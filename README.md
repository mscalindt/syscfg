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

## Features

* Portable octal to binary file mechanism.
* Write avoidance and inode state synchronization.
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
