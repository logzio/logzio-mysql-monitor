#!/bin/bash

function cleanup() {
	kill -9 $(</run/sqlmonitor.pid)

	echo "Exiting ..."
}

# Trap and do manual cleanup
trap cleanup HUP INT QUIT KILL TERM

# Setup dependencies
source ./base.sh

# get script arguments
parse_arguments $@

if [[ -z $LOGZIO_TOKEN ]]; then
    log "ERROR" "logz.io user token is required, exiting ..."
    echo "logz.io user token is required, exiting ..."
    exit 1
fi

# print the env vars
env 

# run checks and monitor MySQL
run

# stop service
cleanup

