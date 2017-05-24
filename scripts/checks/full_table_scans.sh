#!/bin/bash

# Setup dependencies
source ./utils.sh
source ./checks_base.sh

# ---------------------------------------- 
# Describe all component checks defined by the running check
# ---------------------------------------- 
function describe() {
cat << EOF
Percentage_Of_Full_Table_Scans - The percentage of full table running queries
EOF
}


# ---------------------------------------- 
# Run check
# Percentage_Of_Full_Table_Scans - The percentage of full table running queries
# ---------------------------------------- 
function run() {
	# Tmp file
	local tmp_file=`unique_file_name`

	IFS=' ' read -a hosts <<< "${MYSQL_HOST}"

	log "DEBUG" "runniug full_table_scans checks on hosts: $hosts"

	for host in "${hosts[@]}"
	do
		log "DEBUG" "runniug full_table_scans checks on host: $host"

		mysql -h $host -u $MYSQL_USER -p${MYSQL_PASS} -e "SHOW GLOBAL STATUS LIKE 'Handler_read%'" > $tmp_file 2>> $ERROR_LOG_FILE

		if [ $? -ne 0 ]; then
		    echo "Fail to run query. Please check connection to DB -h $host -u $MYSQL_USER -p****" >> $ERROR_LOG_FILE
		    return 1
		fi

		local handler_read_first=$(cat $tmp_file | grep Handler_read_first | xargs echo -n | awk '{print $2}')
		local handler_read_key=$(cat $tmp_file | grep Handler_read_key | xargs echo -n | awk '{print $2}')
		local handler_read_last=$(cat $tmp_file | grep Handler_read_last | xargs echo -n | awk '{print $2}')
		local handler_read_next=$(cat $tmp_file | grep Handler_read_next | xargs echo -n | awk '{print $2}')
		local handler_read_prev=$(cat $tmp_file | grep Handler_read_prev | xargs echo -n | awk '{print $2}')
		local handler_read_rnd=$(cat $tmp_file | grep Handler_read_rnd | xargs echo -n | awk '{print $2}')
		local handler_read_rnd_next=$(cat $tmp_file | grep Handler_read_rnd_next | xargs echo -n | awk '{print $2}')

		local prec=`calc "($handler_read_rnd_next+$handler_read_rnd)/($handler_read_rnd_next+$handler_read_rnd+$handler_read_first+$handler_read_next+$handler_read_key+$handler_read_prev)*100"`

		print_to_file "Percentage_Of_Full_Table_Scans: $prec" $host
	done
}

parse_check_arguments $@

exit 0