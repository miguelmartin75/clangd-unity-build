#!/bin/bash
set -euo pipefail

error() {
    echo $@
    exit 1
}

SRC_DIR=src
TEST_DIR=tests
BUILD_DIR="build"

VERBOSE=${VERBOSE:-1}
CXX=${CXX:-clang++}
CXX_STD=${CXX_STD:-"-std=c++17"}
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
CONFIG_CXXFLAGS=""
COMMAND=""

ALL_TARGETS=("main" "test_main")
DEFAULT_TARGET="main"

while [[ $# -gt 0 ]]; do
    case "$1" in
        all)
            if [[ $COMMAND != "" && $COMMAND != "build" ]]; then
                error "expected command to be empty or build"
            fi
            COMMAND="build"

            if (( ${#BUILD_TARGETS[@]} != 0 )); then
                echo "[WARN] all & targets provided"
                shift
            else
                BUILD_TARGETS=${ALL_TARGETS[@]}
                shift
            fi
            ;;
        *"${ALL_TARGETS[@]}"*)
            if [[ $COMMAND -eq "" ]]; then
                COMMAND="build"
            fi
            BUILD_TARGETS+=($1)
            shift
            ;;
        -c|--config)
            case $2 in
                debug|Debug)
                    CONFIG_CXXFLAGS="-g"
                    ;;
                release|Release)
                    CONFIG_CXXFLAGS="-O3"
                    ;;
                release-debuginfo|ReleaseWithDebug)
                    CONFIG_CXXFLAGS="-O3 -g"
                    ;;
                *)
                    echo "unknown config: $2"
                    ;;
            esac
            shift 2
            ;;
        -q|--quiet)
            VERBOSE=0
            shift
            ;;
        -r|--run)
            RUN=1
            shift
            RUN_ARGS="$@"
            break
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

((${#BUILD_TARGETS[@]})) || BUILD_TARGETS+=("$DEFAULT_TARGET")
: "${COMMAND:=build}"

CXX_CMD="$CODEGEN_SCRIPT"
if (( $CODEGEN != 1 && $COMPILE_COMMANDS != 1 )); then
    CXX_CMD=$CXX
fi

export CXX
export BUILD_DIR
export SRC_DIR
export CODEGEN
export COMPILE_COMMANDS

# * utils *
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
        "$@"
    fi
}

build-unity() {
    target=$1

    mkdir -p $BUILD_DIR
    log ": building $target"
    timeit "${CXX_CMD} -I${SRC_DIR} ${SRC_DIR}/compile_${target}.cpp ${CONFIG_CXXFLAGS} ${CXX_STD} -o $BUILD_DIR/${target}"
    if [[ $RUN -eq 1 ]]; then
        log "--- ^ compile logs ---"
        log ""
        log "$ $BUILD_DIR/${target} ${RUN_ARGS}"
        $BUILD_DIR/${target} ${RUN_ARGS}
    fi
}

test-unity() {
    target=$1

    CATCH2_CFLAGS=$($PKG_CONFIG --cflags $CATCH2_PC 2>/dev/null)
    CATCH2_LIBS=$($PKG_CONFIG --libs --static $CATCH2_PC 2>/dev/null)

    log ".. building tests/$target"
    out_file=$BUILD_DIR/test_${target}
    timeit "${CXX_CMD} -I./ -I${SRC_DIR} ${CATCH2_CFLAGS} ${CATCH2_LIBS} -DTESTS ${TEST_DIR}/compile_${target}.cpp ${CONFIG_CXXFLAGS} ${CXX_STD} -o $out_file"
    if [[ $RUN -eq 1 ]]; then
        log "--- ^ compile logs ---"
        log ""
        log "$ $out_file ${RUN_ARGS}"
        ${out_file} ${RUN_ARGS}
    fi
}

# * commands *
setup() {
    uv sync
}

clean() {
    rm -rf ${BUILD_DIR}
    rm -f compile_commands.json
}

build() {
    log "build ..."
    local t
    for t in ${BUILD_TARGETS};
    do
        $t
    done
}

# * targets *
test_main() { test-unity main; }
main() { build-unity main; }

case $COMMAND in
    build|tests|setup|clean)
        $COMMAND "$@"
        ;;
    *)
        echo "unknown command: $COMMAND"
        exit 1
        ;;
esac
