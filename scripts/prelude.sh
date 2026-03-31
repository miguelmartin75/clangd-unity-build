export PYTHONPATH="scripts/msup:$PYTHONPATH"

timeit() {
    export TIMEFORMAT="${1}: %3Rs"
    if [ ${VERBOSE:-0} == 1 ]; then
        echo "executing for ${1}:\n${@:2}"
    fi
    time "${@:2}"
}
