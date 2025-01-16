#!/usr/bin/env bash
# Switch the current audio output device.
# Without options: Toggle between two sinks.
# This script works for PulseAudio; pactl must be installed.

printUsage() {
    cat <<EOF
usage: $PROGNAME [options]

options:
  -d
     only switch default sink, not for currently playing streams.
  -s SINK_ID
     switch to this sink (instead of toggle sink).
  -i
     interactively select a sink.
  -l
     list all sinks.
  -L
     list all current streams (sink inputs).
  -h
     print help message.
EOF
}

set -o errexit -o pipefail

readonly PROGNAME=${0##*/}

# $1: error message
exitWithError() {
    declare msg=${1:-}
    echo "$msg" >&2
    exit 1
}

# $*: command line arguments = "$@"
parseCommandLine() {

    # declare options globally and readonly
    declare option
    while getopts 'hdlLis:' option; do
        case $option in
            h)
                printUsage
                exit 0
                ;;
            d)
                declare -gr SWITCH_DEFAULT_ONLY=1
                ;;
            s)
                declare -gr SINK_ID=${OPTARG-""}
                ;;
            i)
                declare -gr INTERACTIVE=1
                ;;
            l)
                declare -gr LIST_SINKS=1
                ;;
            L)
                declare -gr LIST_STREAMS=1
                ;;
            *)  printUsage >&2
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))

    if [[ -n ${SINK_ID-""} && -n ${INTERACTIVE-""} ]]; then
        exitWithError "error: you cannot use both -s and -i."
    fi

    if [[ -n ${LIST_SINKS-""} && -n ${LIST_STREAMS-""} ]]; then
        exitWithError "error: you cannot use both -l and -L."
    fi

    if (( $# != 0 )); then
        printUsage
        exit 1
    fi

    return 0
}


main() {
    parseCommandLine "$@"

    if [[ -n ${LIST_SINKS-""} ]]; then
        pactl list short sinks
        exit
    fi

    if [[ -n ${LIST_STREAMS-""} ]]; then
        pactl list short sink-inputs
        exit
    fi


    declare numberOfSinks
    numberOfSinks=$(pactl list short sinks | wc -l)
    if (( numberOfSinks <= 1 )); then
        exitWithError "error: only one or zero audo devices available. no switching possible."
    fi

    declare sinkId
    if [[ -n ${SINK_ID-""} ]]; then
        sinkId=${SINK_ID-""}
    elif [[ -n ${INTERACTIVE-""}  ]]; then
        # interactively select a sink
        # sinkId=$(pactl list short sinks | sed -r 's/alsa_output\.|\.analog-stereo//g' | fzf --delimiter='\t' --with-nth='1,2,5' | awk '{print $1}')
        sinkId=$(pactl list short sinks | sed -r 's/alsa_output\.|\.analog-stereo//g' | fuzzel -d | awk '{print $1}')
    else
        declare currentSinkId
        currentSinkId=$(pactl list short sinks | grep -F RUNNING | awk 'NR==1{print $1}')
        if [[ -z $currentSinkId ]]; then
            exitWithError "error: no currently playing sink. use -i or -s."
        fi
        sinkId=$(pactl list short sinks | grep -v "^$currentSinkId" | awk 'NR==1{print $1}')
        if [[ -z $sinkId ]]; then
            exitWithError "error: no other sink available."
        fi
    fi

    pactl set-default-sink "$sinkId"

    if [[ -z ${SWITCH_DEFAULT_ONLY-""} ]]; then
        declare i
        pactl list short sink-inputs | awk '{print $1}' \
        | while read -r i; do
            pactl move-sink-input "$i" "$sinkId"
        done
    fi
}

main "$@"

