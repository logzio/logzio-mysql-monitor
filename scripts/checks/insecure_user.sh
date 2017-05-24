#!/bin/bash

# Setup dependencies
source ./utils.sh
source ./checks_base.sh

# ---------------------------------------- 
# Describe all component checks defined by the running check
# ---------------------------------------- 
function describe() {
cat << EOF
Users_Missing_Password - Count the number of users without a password
Root_User - Value of 1 indicat the a 'root' user exist
Open_Users - Count the number the number of users that can be connected from anywere
EOF
}


# ---------------------------------------- 
# Run check
# Open_Users - Count the number the number of users that can be connected from anywere
# Root_User - Value of 1 indicat the a 'root' user exist
# Users_Missing_Password - Count the number of users without a password
# ---------------------------------------- 
function run() {
	# Tmp file
	local tmp_file=`unique_file_name`

	IFS=' ' read -a hosts <<< "${MYSQL_HOST}"

	log "DEBUG" "runniug insecure_user checks on hosts: $hosts"

	for host in "${hosts[@]}"
	do
		log "DEBUG" "runniug insecure_user checks on host: $host"

		mysql -N -h $host -u $MYSQL_USER -p${MYSQL_PASS} -e "select host, user, password from mysql.user;" > $tmp_file 2>> $ERROR_LOG_FILE

		if [ $? -ne 0 ]; then
		    echo "ERROR" "Fail to run query. Please check connection to DB -h $host -u $MYSQL_USER -p****" >> $ERROR_LOG_FILE
		    return 1
		fi

		# number the number of users that can be connected from anywere 
		local openusers=$(cat $tmp_file | awk '{print $1}' | grep ^%$ | wc -l)
		# print_to_file "Open_Users: $openusers" $host 

		# root user exist ?
		local rootuser=$(cat $tmp_file | awk '{print $2}' | grep ^root$ | wc -l)
		# print_to_file "Root_User: $rootuser" $host

		# number of users without a password
		local nopasswordusers=$(cat $tmp_file | awk '{print $3}' | grep ^$ | wc -l)
		# print_to_file "Users_Missing_Password: $nopasswordusers" $host

		print_to_file "Root_User: $rootuser Open_Users: $openusers Users_Missing_Password: $nopasswordusers" $host
	done
}

parse_check_arguments $@

exit 0