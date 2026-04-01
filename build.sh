#!/bin/bash
set -euo pipefail

log() {
    if (( $VERBOSE == 1 )); then
        echo "$@"
    fi
}

timeit() {
    export TIMEFORMAT='took: %3Rs'
    if (( $VERBOSE == 1 )); then
        echo "exec: $@"
        time bash -c "$@"
    else
        bash -c "$@"
    fi
}

SRC_DIR=src
BUILD_DIR="build"

VERBOSE=${VERBOSE:-1}
CXXFLAGS=${CXXFLAGS:-}
CXXSTD=${CXXSTD="-std=c++17"}
CXX=${CXX:-clang++}

# flags
CODEGEN_SCRIPT="./scripts/compile.py"
COMPILE_COMMANDS=0
BUILD_TESTS=0
CODEGEN=0
RUN=0
BUILD_TARGETS=()
EXTRAFLAGS=""
COMMAND=""

ALL_TARGETS=("main")
DEFAULT_TARGET="main"

while [[ $# -gt 0 ]]; do
    case "$1" in
        all)
            if (( ${#BUILD_TARGETS[@]} != 0 )); then
                echo "[WARN] all & targets provided"
                shift
            else
                BUILD_TARGETS=${ALL_TARGETS}
                shift
            fi
            ;;
        ${ALL_TARGETS})
            BUILD_TARGETS+=($1)
            shift
            ;;
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
        -q|--quiet)
            VERBOSE=0
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

if (( ${#BUILD_TARGETS[@]} == 0 )); then
    BUILD_TARGETS+=($DEFAULT_TARGET)
fi

if [[ $COMMAND == "" ]]; then
    COMMAND="build"
fi


CXX_CMD="$CODEGEN_SCRIPT"
if (( $CODEGEN != 1 && $COMPILE_COMMANDS != 1 )); then
    CXX_CMD=$CXX
fi

export CXX
export BUILD_DIR
export SRC_DIR
export CODEGEN
export COMPILE_COMMANDS

function setup() {
    uv sync
}

function clean() {
    rm -rf build
    rm -f compile_commands.json
}

function test() {
    mkdir -p $BUILD_DIR
    log "test"
    log "BUILD_TARGETS=${BUILD_TARGETS}"
    # timeit "${CXX_CMD} -Isrc src/compile.cpp ${EXTRAFLAGS} ${CXXSTD} -o $BUILD_DIR/main"
}

function build() {
    mkdir -p $BUILD_DIR
    for target in ${BUILD_TARGETS}; do
        # TODO: if not silent?
        log ".. building $target"
        timeit "${CXX_CMD} -I${SRC_DIR} ${SRC_DIR}/compile_${target}.cpp ${EXTRAFLAGS} ${CXXSTD} -o $BUILD_DIR/${target}"
        if [[ $RUN -eq 1 ]]; then
            log "--- ^ compile logs ---"
            log ""
            log "$ $BUILD_DIR/${target} $@"
            $BUILD_DIR/${target} $@
        fi
    done
}

case $COMMAND in
    test|setup|clean|build)
        $COMMAND "$@"
        ;;
    *)
        echo "unknown command: $COMMAND"
        exit 1
        ;;
esac
