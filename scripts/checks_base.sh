#!/bin/bash

function check_usage() {
    echo
    echo "Description:"
    echo "Run check script, to monitor mysql server" 
    echo
    echo "Usage:"
    echo "$(basename $0) [--run] [--describe] [--help for help]"
    echo

    exit $1    
}


# ---------------------------------------- 
# produce a unique tmp file name
# ---------------------------------------- 
function unique_file_name() {
    local dirname=`dirname $0`
    local basename=`basename $0`
    local full=${dirname}/${basename}
    md5=`execute md5sum ${full} | awk '{ print $1 }'`
    basename=${full##*/}

    echo "/tmp/${md5}_${basename}.tmp"
}

# ---------------------------------------- 
# write log line to file 
# receive log message and log level (info by default)   
# ---------------------------------------- 
function print_to_file {
    local message=$1
    local host=$2
    local date=$(date -u +%s)
    echo "$date" "$host" "$message" >> $CURR_MONITOR_FILE
}

# ---------------------------------------- 
# script arguments
# ---------------------------------------- 
function parse_check_arguments {
    while :; do
        case $1 in
            --help)
                check_usage 0
                ;;

    		--run)
                run
                ;;        

    		--describe)
                describe
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
}