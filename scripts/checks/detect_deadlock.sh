#!/bin/bash

# Setup dependencies
source ./utils.sh
source ./checks_base.sh

# ---------------------------------------- 
# Describe all component checks defined by the running check
# ---------------------------------------- 
function describe() {
cat << EOF
Detected_Deadlock - Value of 1 will note the a deadlock has been detected
EOF
}

# ---------------------------------------- 
# Run check
# Detected_Deadlock - Value of 1 will note the a deadlock has been detected
# ---------------------------------------- 
function run() {
	local tmp_file=/tmp/deadlocks_status.tmp

	IFS=' ' read -a hosts <<< "${MYSQL_HOST}"

	log "DEBUG" "runniug detect_deadlock checks on hosts: $hosts"

	for host in "${hosts[@]}"
	do
		log "DEBUG" "runniug detect_deadlock checks on host: $host"

		mysql -Bse "SHOW ENGINE INNODB STATUS\G" -h $host -u $MYSQL_USER -p${MYSQL_PASS} | awk '/LATEST DETECTED DEADLOCK/{f=1} /WE ROLL BACK TRANSACTION /{f=0;print} f' > $tmp_file 2>> $ERROR_LOG_FILE

		if [ $? -ne 0 ]; then
		    echo "Fail to run query. Please check connection to DB -h $host -u $MYSQL_USER -p****" >> $ERROR_LOG_FILE
		    return 1
		fi

		#Checking tmp file for any errors
		local valdump=`cat /tmp/deadlocks_status.tmp |wc -l`
		if [ $valdump = 0 ]; then
			echo "No Issues" > /dev/null
			print_to_file "Detected_Deadlock: 0" $host
		else
			local errors=$(cat /tmp/deadlocks_status.tmp)
			echo "$errors" > /tmp/current-deadlocks_status.tmp

			if [ -e "/tmp/prior-deadlocks_status.tmp" ]; then
				echo "prior-deadlocks_status.tmp Exists" > /dev/null
			else
		    	touch /tmp/prior-deadlocks_status.tmp | echo "" > /tmp/prior-deadlocks_status.tmp
			fi

			local newentries=$(diff --suppress-common-lines -u /tmp/prior-deadlocks_status.tmp /tmp/current-deadlocks_status.tmp | grep '\+[0-9]')

			if [ "$newentries" == "" ] && [ "$errors" != "" ]; then
		    	echo "No New Errors" > /dev/null
				print_to_file "Detected_Deadlock: 0" $host
		    elif [ "$newentries" != "" ]; then
		    	echo "$errors" > /tmp/prior-deadlocks_status.tmp
				print_to_file "Detected_Deadlock: 1" $host
		    fi
		fi
	done
}

parse_check_arguments $@

exit 0