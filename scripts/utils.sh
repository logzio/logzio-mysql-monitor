#!/bin/bash

# ---------------------------------------- 
# debug logs to console on a log level
# ---------------------------------------- 
function log {
    mkdir -p /var/log/logzio

    if [[ $1 == "ERROR" ]]; then
        echo "${*:2}" >> $ERROR_LOG_FILE
    fi

    if [[ $1 == "DEBUG" && $LOG_LEVEL -lt 3 ]]; then
        return 0
    fi

	if [ -z "$LOG_FILE" ]; then
		echo "[$1] ${*:2}"
    else
        echo "[$1] ${*:2}" >> $LOG_FILE
    fi
}

# ---------------------------------------- 
# accept a command as an argument, on error
# exit with status code on error
# ---------------------------------------- 
function execute {
	#log "DEBUG" "Running command: $@"
    "$@" 2>> $ERROR_LOG_FILE
    local status=$?
    if [ $status -ne 0 ]; then
        log "ERROR" "Occurred while executing: $@"
        exit $status
    fi
}


function calc {
    awk "BEGIN { print "$*" }"
}