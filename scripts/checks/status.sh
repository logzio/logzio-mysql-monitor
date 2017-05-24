#!/bin/bash

# Setup dependencies
source ./utils.sh
source ./checks_base.sh

# ---------------------------------------- 
# Describe all component checks defined by the running check
# ---------------------------------------- 
function describe() {
cat << EOF
Uptime - The number of seconds the MySQL server has been running.
Current_Active_Clients - The number of active threads (clients).
Queries_Since_Startup - The number of questions (queries) from clients since the server was started.
Slow_queries - The number of queries that have taken more than long_query_time seconds.
Opens_Tables - The number of tables the server has opened.
Flush_Tables - The number of flush, refresh, and reload commands the server has executed.
Current_Open_Tables - Total number of open tables in the database.
Queries_per_second_avg - The number of tables that currently are open
EOF
}


# ---------------------------------------- 
# Run check
# Uptime: The number of seconds the MySQL server has been running.
# Current_Active_Clients:The number of active threads (clients).
# Queries_Since_Startup: The number of questions (queries) from clients since the server was started.
# Slow_queries: The number of queries that have taken more than long_query_time seconds.
# Opens_Tables: The number of tables the server has opened.
# Flush_Tables: The number of flush, refresh, and reload commands the server has executed.
# Queries_per_second_avg: The number of tables that currently are open
# ---------------------------------------- 
function run() {

	# Tmp file
	local tmp_file=`unique_file_name`

	IFS=' ' read -a hosts <<< "${MYSQL_HOST}"

	log "DEBUG" "runniug status checks on hosts: $hosts"

	for host in "${hosts[@]}"
	do
		log "DEBUG" "runniug status checks on host: $host"

		mysqladmin -h $host -u $MYSQL_USER -p${MYSQL_PASS} status > $tmp_file 2>> $ERROR_LOG_FILE

		# a valid output whold be:
		# Uptime: 5447554 Threads: 5 Questions: 4420862 Slow queries: 2 Opens: 386091 Flush tables: 1 Open tables: 949 Queries per second avg: 0.811

		if [ $? -ne 0 ]; then
		    echo "Fail to run query. Please check connection to DB -h $host -u $MYSQL_USER -p****" >> $ERROR_LOG_FILE
		    print_to_file "Uptime: 0" "$host"
		    return 1
		fi

		status_uptime=$(cat $tmp_file | awk '{print $2}')
		status_active_clients=$(cat $tmp_file | awk '{print $4}')
		status_queries=$(cat $tmp_file | awk '{print $6}')
		status_slow_queries=$(cat $tmp_file | awk '{print $9}')
		status_opens_tables=$(cat $tmp_file | awk '{print $11}')
		status_flush_tables=$(cat $tmp_file | awk '{print $14}')
		status_current_open_tables=$(cat $tmp_file | awk '{print $17}')
		status_queries_per_second_avg=$(cat $tmp_file | awk '{print $22}')

		print_to_file "Uptime: $status_uptime Current_Active_Clients: $status_active_clients Queries_Since_Startup: $status_queries Slow_queries: $status_slow_queries Opens_Tables: $status_opens_tables Flush_Tables: $status_flush_tables Current_Open_Tables: $status_current_open_tables Queries_per_second_avg: $status_queries_per_second_avg" "$host"

	done
}

parse_check_arguments $@

exit 0