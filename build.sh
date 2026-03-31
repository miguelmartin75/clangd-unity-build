#!/bin/bash
set -euo pipefail

timeit() {
    export TIMEFORMAT='took: %3Rs'
    echo "exec: $@"
    time bash -c "$@"
}

CXXFLAGS=${CXXFLAGS:-}
CXX=${CXX:-clang++}
BUILD_DIR=${BUILD_DIR:-build}
CODEGEN=${CODEGEN:-0}
CODEGEN_SCRIPT=${SCRIPT:-./scripts/compile.py}
COMMAND=${COMMAND:-"build"}
EXTRAFLAGS=${EXTRAFLAGS:-"-g"}

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
        --codegen)
            CODEGEN=1
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
            COMMAND=$1
            shift
            ;;
    esac
done

function clean() {
    rm -r build
}

function build() {
    mkdir -p build
    mkdir -p src/meta
    cat src/*.cpp | sed -n 's/^fn \(.*\){/\1;/p' > src/meta/fns.h
    cat src/*.cpp | sed -n 's/^struct \(.*\){/struct \1;/p' > src/meta/types.h
    sed "s|\"directory\": \"\$PWD\"|\"directory\": \"${PWD}\"|g" compile_commands_template.json > compile_commands.json

    CXX_CMD="$CODEGEN_SCRIPT"
    if [[ $CODEGEN -ne 1 ]] ; then
        CXX_CMD=$CXX
    fi

    CXX=$CXX \
        BUILD_DIR=$BUILD_DIR \
        timeit "${CXX_CMD} -Isrc src/compile.cpp ${EXTRAFLAGS} -o $BUILD_DIR/main"
}

case $COMMAND in
    clean|build)
        $COMMAND
        ;;
    *)
        echo "unknown command: $COMMAND"
        exit 1
        ;;
esac

