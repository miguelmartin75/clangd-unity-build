#!/bin/bash
set -euo pipefail

timeit() {
    export TIMEFORMAT='took: %3Rs'
    echo "exec: $@"
    time bash -c "$@"
}

BUILD_DIR=${BUILD_DIR:-build}
NO_PYTHON=${NO_PYTHON:-0}
COMMAND=${COMMAND:-"build"}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-python)
            NO_PYTHON=1
            shift 1
            ;;
        -o|--build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [command] [-o|--build-dir <arg>] [--no-python] [-h|--help]"
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
    timeit 'clang++ -Isrc src/compile.cpp -o build/main'
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

