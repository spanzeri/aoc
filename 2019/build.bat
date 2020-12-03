@echo off

set "release="
if "%1" == "release" (
    set "release=--release"
    shift
)

if "%1" == "run" (
    cargo run %release%
) else (
    cargo build %release%
)
