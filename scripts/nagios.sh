#!/bin/bash

##############################################
#
# Nagios plugin that monitors the cache that the go.py generated and exit with certin codes as nagios knows and loves.
#
# Exit codes are:
#	0 - Everything is a-ok!
#	1 - Warning
#	2 - Critial
#	3 - Unknown (Should be also conciders as a problem in most cases)
#
# Written by Roi Rav-Hon @ Logz.io
#			 Ofer Velich @ Logz.io
#
# Usage:
#
# docker exec CONTAINER /root/nagios.sh HOST COMPONENT -c CRITICAL -w WARNING
#
#	Components:
#
#		uptime 						(e.g uptime -c 0 -w 0)
#
##############################################


# Usage function
function usage() {
	describe_components

	echo "docker exec CONTAINER /root/nagios.sh HOST COMPONENT -c CRITICAL -w WARNING"
	echo ""
	echo "Components:"
	echo ""
	cat /tmp/describe_components
	echo ""
}


# Describe all component checks defined under the checks folder 
function describe_components() {
    rm -f /tmp/describe_components

    # execute all configured
    for script in $CHECKS_DIR/* ; do
        $script --describe >> /tmp/describe_components
    done
}


# First sanity check
if [ $# -lt 2 ]; then

	echo "You must choose host and a component!"
	usage
	exit 3
fi


# Declare variables
declare critical=""
declare warning=""
declare host=$1 ; shift # Get the host and removes it from param list, so it will be easier to parse
declare component=$1 ; shift # Get the components and removes it from param list, so it will be easier to parse


# And some consts
declare -r LOG_FILE=/monitor.log

# Regular expression to validate that the variables are numbers
re='^[-+]?[0-9]+\.?[0-9]*$'


# Parsing parameters. Expects all params but the component
function parse_params() {

	# Iterateing over getopts
	while getopts ":c:w:" opt; do
		case $opt in
			c)
				# Check for numerical input.
				if [[ $OPTARG =~ $re ]]; then
					
					# Set critical
					critical=$OPTARG
				else
					echo "-c Must get a number argument. $OPTARG is not valid."
					usage
					exit 3
				fi
				;;
			w)
				# Check for numerical input.
				if [[ $OPTARG =~ $re ]]; then
					
					# Set warning
					warning=$OPTARG
				else
					echo "-w Must get a number argument. $OPTARG is not valid."
					usage
					exit 3
				fi
				;;
			:) # No optarg was supplied
				echo "Option -$OPTARG requires a number argument"
				usage
				exit 3
				;;
			*) # Unknown parameter
				echo "Unknown option: -$OPTARG"
				usage
				exit 3
		esac
	done
}


function check_warning() {

	# Is the warning param set?
	if [ "$warning" == "" ]; then

		return 1
	fi
}


function check_critical() {
	
	# Is the critical param set?
	if [ "$critical" == "" ]; then

		return 1
	fi
}


function parse_cache_file() {
	
	# Default file
	local parsing_file="$LOG_FILE"

	# Lets get the number!
	cache=$(cat $parsing_file | grep -i "$host" | tr " " "\n" | grep -i -A 1 $component | tail -n 1 | sed -e 's/^[[:space:]]*//')

	if [ "$cache" == "" ]; then

		echo "Did not find any cache for your component." >&2
		echo "Either that the cache file is in writing now or there is something else bad." >&2
		echo "Is the docker sending correct logs?" >&2
		echo "Anyway, bailing out." >&2
		echo "Unknown"
		return 3
	fi

	# Verify that this is a number
	if ! [[ "$cache" =~ $re ]]; then

		# Cache is not a number.. must be a bug
		echo "Somehow the reading from the cache is there, but its not a number." >&2
		echo "That is what i got: $cache" >&2
		echo "Its probably a bug, please report that." >&2
		echo "Unknown"
		return 3
	fi

	# Print it out so we can catch that
	echo $cache
}


# For the sake of reuse, master function for all numerical values
function process_numerical_values() {
	local res=0
	# Check that both critical and warning supplied
	if ! ( check_critical && check_warning ); then

		echo "You must set both -c and -w to use $component"
		usage
		exit 3
	fi

	# We need to validate that critical is higher then warning, else it doesnt make sense
	res=$(is_le $critical $warning)
	if [ $res == "1" ]; then

		echo "Critical ($critical) cannot be less or equal to warning ($warning) threshold!"
		exit 3
	fi

	# Get the cached result
	local cached_result=$(parse_cache_file)
	
	if [[ "${cached_result}" == "Unknown" ]]; then
		exit 3
	fi

	# Now match it against the warning or the critical ones
	res=$(is_ge $cached_result $critical)

	if [ $res == "1" ]; then

		echo "CRITICAL: $component is: $cached_result, which is higher or equal to the critical threshold: $critical | $component: $cached_result"
		exit 2
	fi

	# And match the warning
	res=$(is_ge $cached_result $warning)
	if [ $res == "1" ]; then

		echo "WARNING: $component is: $cached_result, which is higher or equal to the warning threshold: $warning | $component: $cached_result "
		exit 1
	fi

	echo "OK: $component is $cached_result | $component: $cached_result"
	exit 0
}

function is_ge() {
	local num1=$1
	local num2=$2

	echo $num1'>='$num2 | bc -l
}

function is_le() {
	local num1=$1
	local num2=$2

	echo $num1'<='$num2 | bc -l
}

function main() {
	# Parsing all parameters
	parse_params "$@"
	describe_components
	for option in `cat /tmp/describe_components | awk '{print $1}'`; do
		if [[ $component == $option ]]; then
			# Process the alert
			process_numerical_values
		fi
	done

	echo "Unknown component: $component"
	usage
	exit 3
}

main "$@"