# Spec: Native source acquisition

## Problem

`dart pub get` does not recursively init git submodules. Consumer projects
that depend on this package via pub.dev or git cannot compile the native
library — the C source is missing at build time.

## Requirements

- When a consumer project depends on this package, `dart pub get` followed
  by `dart run` shall compile the native library without git submodules or
  pre-existing C source in the repository.
- The build hook shall acquire pinned, hash-verified C source automatically
  on first build.
- Subsequent builds shall reuse cached source without network access.
- The native library shall compile on Windows, macOS, and Linux from the
  acquired source.
