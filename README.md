# repo2
Repository management tool

Replacement for the original `repo` tool I wrote in Raku.

## Build

Currently building using zig master.

`zig build`

## Install

Copy the output binary (`zig-out/bin/repo-zig`) to somewhere in your `$PATH`.

Add the following line to your `.bashrc`

```sh
eval "$(repo-zig shell)"
```

## Usage

```
usage: repo <command> [args]

Commands:
  cd      Change to a project directory under ~/src
  clone   Clone a repository into ~/src according to the site, user, and project
  help    Display this help information
  shell   Print shell helper functions for eval
```
