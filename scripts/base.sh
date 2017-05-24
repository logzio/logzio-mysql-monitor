#!/bin/bash


# mysql host creds defaults
: ${MYSQL_HOST:=""}
: ${MYSQL_USER:=""}
: ${MYSQL_PASS:=""}
: ${MYSQL_REPLICAS:=""}

# running checks interval, default to 60 seconds 
: ${INTERVAL_SECONDS:=60}

# logging level (debug, info and error), default to info
export LOG_LEVEL=${LOG_LEVEL:=2}

# "monitor" log file
export CURR_MONITOR_FILE=/curr_monitor.log
export MONITOR_FILE=/monitor.log

# logzio log files
export LOG_FILE=$LOGZIO_LOGS_DIR/logzio-monitor.log
export ERROR_LOG_FILE=$LOGZIO_LOGS_DIR/logzio-monitor-error.log

LOGZIO_LISTENER=${LOGZIO_LISTENER:="listener.logz.io"}

# pid files to prevent overrides
export PID_DIR=/run/logzio
export PID_FILE=$PID_DIR/sql-monitor.pid

# Setup dependencies
source ./utils.sh

# ---------------------------------------- 
# useage
# ----------------------------------------
function usage {
	echo
	echo "Usage:"
	echo docker run -d --name logzio-mysql-monitor -e LOGZIO_TOKEN=VALUE -e MYSQL_HOST=VALUE -e MYSQL_USER=VALUE \
                     [-e MYSQL_PASS=VALUE] [-e MYSQL_REPLICAS=VALUE] [-e INTERVAL_SECONDS=VALUE] [-e LOGZIO_LISTENER=VALUE] \
                     -v path_to_directory:/var/log/logzio \
                     logzio/mysql-monitor:latest
	echo
    echo 
    exit $1
}

# ---------------------------------------- 
# script arguments
# ---------------------------------------- 
function parse_arguments {
    while :; do
        case $1 in
            --help)
                usage 0
                ;;

            -v|--verbose)
                LOG_LEVEL=3
                log "INFO" "Log level is set to debug."
                ;;

            --) # End of all options.
                shift
                break
                ;;
            *)  # Default case: If no more options then break out of the loop.
                break
        esac

        shift
    done

    if [[ $MYSQL_HOST == "" ]]; then
        MYSQL_HOST="localhost"
    fi

    if [[ $MYSQL_USER == "" ]]; then
        MYSQL_USER="root"
    fi
}


# ---------------------------------------- 
# ship the monitored log files to logzio
# ---------------------------------------- 
function ship() {

    if [[ -z $LOGZIO_TOKEN ]]; then
        log "ERROR" "Account Token is not defined, exiting"
        exit 1
    fi

    curl -k -T $CURR_MONITOR_FILE https://${LOGZIO_LISTENER}:8022/file_upload/$LOGZIO_TOKEN/mysql_monitor 2>> $ERROR_LOG_FILE

    if [[ $? -ne 0 ]]; then
        log "ERROR" "Failed to ship logs to listener.logz.io"
        exit 1
    fi
}


# ---------------------------------------- 
# execute all check commands under the check folder
# ---------------------------------------- 
function run() {
    execute rm -rf $PID_DIR
    execute mkdir -p $PID_DIR

    while true; do
        log "DEBUG" "looping .... "
        
        if [[ -f $PID_FILE ]]; then
            log "DEBUG" "PID File exist .... "
        
            sleep $INTERVAL_SECONDS
        else
            log "DEBUG" "Running checks .... "

            # write the current session's PID to file
            echo $$ >> $PID_FILE

            # execute all configured
            for script in $CHECKS_DIR/* ; do
                log "DEBUG" "Running check $script .... "
                execute $script --run
            done
            
            execute cp $CURR_MONITOR_FILE $MONITOR_FILE

            # send metrics to logz.io
            ship

            sleep $INTERVAL_SECONDS

            execute rm -f $CURR_MONITOR_FILE
            execute rm -f $PID_FILE
        fi
    done
}


# ---------------------------------------- 
# Describe all component checks defined under the checks folder 
# ---------------------------------------- 
function describe() {
    rm -f /tmp/describe_components

    # execute all configured
    for script in $CHECKS_DIR/* ; do
        $script --describe >> /tmp/describe_components
    done
}


