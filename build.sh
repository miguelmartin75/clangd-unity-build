#!/bin/bash
set -euo pipefail

timeit() {
    export TIMEFORMAT='took: %3Rs'
    echo "exec: $@"
    time bash -c "$@"
}

SRC_DIR=src
RUN=${RUN:0}
CXXFLAGS=${CXXFLAGS:-}
CXX=${CXX:-clang++}
BUILD_DIR=${BUILD_DIR:-build}
CODEGEN=${CODEGEN:-0}
CODEGEN_SCRIPT=${SCRIPT:-./scripts/compile.py}
COMMAND=${COMMAND:-""}
CXXSTD=${CXXSTD="-std=c++17"}
EXTRAFLAGS=${EXTRAFLAGS:-"-g"}
COMPILE_COMMANDS=${COMPILE_COMMANDS:-0}

while [[ $# -gt 0 ]]; do
    case "$1" in
        debug)
            EXTRAFLAGS="-g"
            shift
            ;;
        release)
            EXTRAFLAGS="-O3"
            shift
            ;;
        release-debuginfo)
            EXTRAFLAGS="-O3 -g"
            shift
            ;;
        -r|--run)
            RUN=1
            shift
            ;;
        -g|--gen)
            CODEGEN=1
            shift
            ;;
        -cc|--compile-commands)
            COMPILE_COMMANDS=1
            shift
            ;;
        --codegen-script)
            CODEGEN_SCRIPT=$1
            shift 2
            ;;
        -o|--build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [command] [-o|--build-dir <arg>] [--codegen] [-h|--help]"
            echo "command can be one of 'build' or 'clean'"
            echo "if no command given, then 'build' is assumed"
            exit 0
            ;;
        *)
            if [[ $COMMAND == "" ]]; then
                COMMAND=$1
                shift
            else
                break
            fi
            ;;
    esac
done

if [[ $COMMAND == "" ]]; then
    COMMAND="build"
fi

function setup() {
    uv sync
}

function clean() {
    rm -r build
}

function build() {
    mkdir -p build
    CXX_CMD="$CODEGEN_SCRIPT"
    if (( $CODEGEN != 1 && $COMPILE_COMMANDS != 1 )); then
        CXX_CMD=$CXX
    fi

    export CXX
    export BUILD_DIR
    export SRC_DIR
    export CODEGEN
    export COMPILE_COMMANDS
    timeit "${CXX_CMD} -Isrc src/compile.cpp ${EXTRAFLAGS} ${CXXSTD} -o $BUILD_DIR/main"
    if [[ $RUN -eq 1 ]]; then
        echo "--------------"
        echo "^ compile logs"
        echo "  running  ..."
        echo "v run logs    "
        echo "=============>"
        echo "args=" $@
        $BUILD_DIR/main $@
    fi
}

case $COMMAND in
    setup|clean|build)
        $COMMAND $@
        ;;
    *)
        echo "unknown command: $COMMAND"
        exit 1
        ;;
esac

