#/bin/bash

# Setup dependencies
source ./utils.sh
source ./checks_base.sh

# ---------------------------------------- 
# Describe all component checks defined by the running check
# ---------------------------------------- 
function describe() {
cat << EOF
Percentage_Of_Allowed_Connections - The percentage of currently used connections
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

	log "DEBUG" "runniug max_allowed_connections checks on hosts: $hosts"

	for host in "${hosts[@]}"
	do
		log "DEBUG" "runniug max_allowed_connections checks on host: $host"

		mysql -h $host -u $MYSQL_USER -p${MYSQL_PASS} -e "SHOW GLOBAL VARIABLES LIKE 'max_connections';" > $tmp_file 2>> $ERROR_LOG_FILE
		mysql -h $host -u $MYSQL_USER -p${MYSQL_PASS} -e "SHOW GLOBAL STATUS LIKE 'max_used_connections';" >> $tmp_file 2>> $ERROR_LOG_FILE

		if [ $? -ne 0 ]; then
		    echo "Fail to run query. Please check connection to DB -h $host -u $MYSQL_USER -p****" >> $ERROR_LOG_FILE
		    return 1
		fi

		local max_connections=$(cat $tmp_file | grep -i max_connections | awk '{print $2}')
		local max_used_connections=$(cat $tmp_file | grep -i max_used_connections | awk '{print $2}')

		if [[ -z $max_used_connections ]]; then
		    max_used_connections=0
		fi

		local div=$(execute echo $max_used_connections/$max_connections | bc -l)
		local prec=$(execute echo "$div * 100" | bc)

		print_to_file "Percentage_Of_Allowed_Connections: $prec" $host
	done
}

parse_check_arguments $@

exit 0