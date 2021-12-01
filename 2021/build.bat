@echo off
setlocal enabledelayedexpansion

set "root=%~dp0"
set "bindir=%root%bin"
set "tmpdir=%root%tmp"

if not defined VisualStudioVersion (
    echo Run the command from a visual studio >= 2019 command prompt
    exit /b 1
)

if "%1"=="release" (
    shift
    set "ccflags=-Ox -MD"
) else (
    set "ccflags=-Od -MDd"
)
set "ccflags=%ccflags% -std:c11 -I%root% -W4 -WX"

if not exist "%1" (
    echo Run the command:
    echo  - build name_of_c_file OR
    echo  - build release name_of_c_file
    echo File not found "%1"
    exit /b 1
)

if not exist "%bindir%" mkdir "%bindir%"
if not exist "%tmpdir%" mkdir "%tmpdir%"

pushd "%tmpdir%"

cl -nologo %ccflags% "%1" -link -INCREMENTAL:NO -OUT:"%bindir%\aoc.exe" -PDB:aoc.pdb
set ccresult=%ERRORLEVEL%

popd

exit /b %ccresult%
