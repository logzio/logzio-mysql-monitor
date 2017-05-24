#!/bin/bash

# Setup dependencies
source ./utils.sh
source ./checks_base.sh

# ---------------------------------------- 
# Describe all component checks defined by the running check
# ---------------------------------------- 
function describe() {
cat << EOF
Connection_Failed_Attempts - Count the The total number of failed attempts to connect to MySQL
EOF
}


# ---------------------------------------- 
# Run check
# Connection_Failed_Attempts - Count the The total number of failed attempts to connect to MySQL 
# ---------------------------------------- 
function run() {
	# Tmp file
	local tmp_file=`unique_file_name`

	IFS=' ' read -a hosts <<< "${MYSQL_HOST}"

	log "DEBUG" "runniug aborted_connects checks on hosts: $hosts"

	for host in "${hosts[@]}"
	do

		log "DEBUG" "runniug aborted_connects on host: $host"
		
		mysql -N -h $host -u $MYSQL_USER -p${MYSQL_PASS} -e "SHOW GLOBAL STATUS LIKE 'aborted_connects';" > $tmp_file 2>> $ERROR_LOG_FILE
		
		if [ $? -ne 0 ]; then
		    echo "Fail to run query. Please check connection to DB -h $host -u $MYSQL_USER -p****" >> $ERROR_LOG_FILE
		    return 1
		fi

		# The total number of failed attempts to connect to MySQL 
		local aborted_connects=$(cat $tmp_file | awk '{print $2}')
		print_to_file "Connection_Failed_Attempts: $aborted_connects" $host

	done
}

parse_check_arguments $@

exit 0