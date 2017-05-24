#/bin/bash

# Setup dependencies
source ./utils.sh
source ./checks_base.sh

# ---------------------------------------- 
# Describe all component checks defined by the running check
# ---------------------------------------- 
function describe() {
cat << EOF
Reads_Ops - The number of physical reads of a key block from disk into the MyISAM key cache.
Write_Ops - The number of physical writes of a key block from the MyISAM key cache to disk.
EOF
}

# ---------------------------------------- 
# Run check
# Percentage_Of_Allowed_Connections - The percentage of currently used connections 
# ---------------------------------------- 
function run() {
	# Tmp file
	local tmp_file=`unique_file_name`

	IFS=' ' read -a hosts <<< "${MYSQL_HOST}"

	log "DEBUG" "runniug read_write_ops checks on hosts: $hosts"

	for host in "${hosts[@]}"
	do
		log "DEBUG" "runniug read_write_ops checks on host: $host"

		mysql -h $host -u $MYSQL_USER -p${MYSQL_PASS} -e "SHOW GLOBAL STATUS LIKE 'Key_reads';" > $tmp_file 2>> $ERROR_LOG_FILE
		
		if [ $? -ne 0 ]; then
		    echo "Fail to run query. Please check connection to DB -h $host -u $MYSQL_USER -p****" >> $ERROR_LOG_FILE
		    return 1
		fi

		local key_reads=$(cat $tmp_file | grep -i Key_reads | awk '{print $2}')


		mysql -h $host -u $MYSQL_USER -p${MYSQL_PASS} -e "SHOW GLOBAL STATUS LIKE 'Key_writes';" > $tmp_file
		
		if [ $? -ne 0 ]; then
		    echo "Fail to run query. Please check connection to DB -h $host -u $MYSQL_USER -p****" >> $ERROR_LOG_FILE
		    return 1
		fi

		local key_writes=$(cat $tmp_file | grep -i Key_writes | awk '{print $2}')

		print_to_file "Reads_Ops: $key_reads Write_Ops: $key_writes" $host
	done
}

parse_check_arguments $@

exit 0