#!/bin/bash
set -euo pipefail

SRC_DIR=src
TEST_DIR=tests
BUILD_DIR="build"

VERBOSE=${VERBOSE:-1}
CXX=${CXX:-clang++}
CXXSTD=${CXXSTD:-"-std=c++17"}
CXXFLAGS=${CXXFLAGS:-}

PKG_CONFIG=${PKG_CONFIG:-pkg-config}
CATCH2_PC=${CATCH2_PC:-catch2-with-main}

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

function setup() {
    uv sync
}

function clean() {
    rm -rf build
    rm -f compile_commands.json
}

function test() {
    mkdir -p $BUILD_DIR
    log ": tests"
    for target in ${BUILD_TARGETS}; do
        log ".. building $target"
        CATCH2_CFLAGS=$($PKG_CONFIG --cflags $CATCH2_PC 2>/dev/null)
        CATCH2_LIBS=$($PKG_CONFIG --libs --static $CATCH2_PC 2>/dev/null)
        out_file=$BUILD_DIR/test_${target}
        timeit "${CXX_CMD} -I./ -I${SRC_DIR} ${CATCH2_CFLAGS} ${CATCH2_LIBS} -DTESTS ${TEST_DIR}/compile_${target}.cpp ${EXTRAFLAGS} ${CXXSTD} -o $out_file"
        if [[ $RUN -eq 1 ]]; then
            log "--- ^ compile logs ---"
            log ""
            log "$ $out_file"
            ${out_file} $@
        fi
    done
}

function build() {
    mkdir -p $BUILD_DIR
    echo ": build"
    for target in ${BUILD_TARGETS}; do
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
