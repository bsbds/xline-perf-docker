#!/bin/bash
SERVER_NUM=$1

COLORS="hot"
case "$PERF_MODE" in
    oncpu) PERF_CMD="perf record -a -g --call-graph dwarf";;
    offcpu) 
        COLORS="io"
        PERF_CMD="perf record -e sched:sched_switch -g";;
    memory) 
        COLORS="mem"
        if [ "$SERVER_NUM" = "1" ]; then
            perf probe --del malloc
            perf probe --exec=/usr/lib/x86_64-linux-gnu/libc.so.6 --add malloc
        fi
        PERF_CMD="perf record -e probe_libc:malloc -g";;
    disabled) PERF_CMD="";;
    *) 
        echo "Error: Invalid PERF_MODE '$PERF_MODE'"
        exit 1
        ;;
esac

./xline &

if [ -z "$PERF_CMD" ]; then
    inotifywait -q -e modify,create /perf/notify
else
    $PERF_CMD -o /perf/perf_xline${SERVER_NUM}_${PERF_MODE}.data -p $! -- inotifywait -q -e modify,create /perf/notify && \
    perf script -i /perf/perf_xline${SERVER_NUM}_${PERF_MODE}.data | stackcollapse-perf.pl | flamegraph.pl --colors=$COLORS > /perf/flamegraph_xline${SERVER_NUM}_${PERF_MODE}.svg
fi

if [ "$PERF_MODE" = "memory" ] && [ "$SERVER_NUM" = "1" ]; then
    perf probe --del malloc
fi

