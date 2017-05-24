#!/bin/bash

# Setup dependencies
source ./utils.sh
source ./checks_base.sh

# ---------------------------------------- 
# Describe all component checks defined by the running check
# ---------------------------------------- 
function describe() {
cat << EOF
Slave_IO_Running - Whether the I/O thread for reading the masters binary log is running. Normally, you want this to be Yes unless you have not yet started replication or have explicitly stopped it with STOP SLAVE.
Slave_SQL_Running - Whether the SQL thread for executing events in the relay log is running. As with the I/O thread, this should normally be Yes
Seconds_Behind_Master - The lag from the master
EOF
}


# ---------------------------------------- 
# Run check
# Slave_IO_Running - Whether the I/O thread for reading the master's binary log is running. Normally, you want this to be Yes unless you have not yet started replication or have explicitly stopped it with STOP SLAVE.
# Slave_SQL_Running - Whether the SQL thread for executing events in the relay log is running. As with the I/O thread, this should normally be Yes
# Seconds_Behind_Master - Whether the SQL thread for executing events in the relay log is running. As with the I/O thread, this should normally be Yes
# ---------------------------------------- 
function run() {

	# Tmp file
	local tmp_file=`unique_file_name`
	
	IFS=' ' read -a hosts <<< "${MYSQL_REPLICAS}"

	log "DEBUG" "runniug slave_status checks on hosts: $hosts"

	for host in "${hosts[@]}"
	do
		log "DEBUG" "runniug slave_status checks on host: $host"

		mysql -h $host -u $MYSQL_USER -p${MYSQL_PASS} -e "show slave status \G" > $tmp_file 2>> $ERROR_LOG_FILE

		if [ $? -ne 0 ]; then
		    echo "ERROR" "Fail to run query. Please check connection to DB -h $host -u $MYSQL_USER -p****" >> $ERROR_LOG_FILE
		    return 1
		fi

		# check that master-slave replica is enabled or if we are running aginst to master server.
		local raw_count=$(cat $tmp_file | wc -l)
		local empty_set_raw_count=$(cat $tmp_file | grep "Empty set" | wc -l)

		if [[ $raw_count -eq 0 ]] || [[ $empty_set_raw_count -eq 1 ]]; then
		    echo "ERROR" "Master-Slave Replica is not set or its the master server." >> $ERROR_LOG_FILE
		    exit 1
		fi

		local slave_io_running=$(cat $tmp_file | grep "Slave_IO_Running: Yes" | wc -l)
		#print_to_file "Slave_IO_Running: $slave_io_running" $host

		local slave_sql_running=$(cat $tmp_file | grep "Slave_SQL_Running: Yes" | wc -l)
		#print_to_file "Slave_SQL_Running: $slave_sql_running" $host

		local seconds_behind_master=$(cat $tmp_file | grep "Seconds_Behind_Master" | awk '{ print $2}')

		if [[ $seconds_behind_master =~ ^-?[0-9]+$ ]] ; then
		    # print_to_file "Seconds_Behind_Master: $seconds_behind_master" $host
		    print_to_file "Slave_IO_Running: $slave_io_running Slave_SQL_Running: $slave_sql_running Seconds_Behind_Master: $seconds_behind_master" $host
		else
		    print_to_file "Slave_IO_Running: $slave_io_running Slave_SQL_Running: $slave_sql_running Seconds_Behind_Master: 0" $host
		fi
		
	done
}

parse_check_arguments $@

exit 0