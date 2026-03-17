: ; # Polyglot script: runs as bash on Unix, cmd on Windows
: ; SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" ; exec bash "${SCRIPT_DIR}/$1" ; exit $?
@echo off
set "SCRIPT_DIR=%~dp0"
bash "%SCRIPT_DIR%\%1"
