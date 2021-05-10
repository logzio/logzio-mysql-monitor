This repo will be depreacted soon as it forward metrics to our old metrics solution


logzio-mysql-monitor
=========================

[Docker hub repository](https://hub.docker.com/r/logzio/mysql-monitor/)

This container monitors your MySQL cluster.
The container also provides a Nagios plugin script that uses local caches from the regular monitoring routine, so you won't overload your MySQL with unnecessary queries.
It's can be integrated with Amazon RDS.

The containers monitors these values:
- Connection_Failed_Attempts - Count the The total number of failed attempts to connect to MySQL
- Detected_Deadlock - Value of 1 will note the a deadlock has been detected
- Percentage_Of_Full_Table_Scans - The percentage of full table running queries
- Users_Missing_Password - Count the number of users without a password
- Root_User - Value of 1 indicat the a 'root' user exist
- Open_Users - Count the number the number of users that can be connected from anywere
- Percentage_Of_Allowed_Connections - The percentage of currently used connections
- Slave_IO_Running - Whether the I/O thread for reading the masters binary log is running. Normally, you want this to be Yes unless you have not yet started replication or have explicitly stopped it with STOP SLAVE.
- Slave_SQL_Running - Whether the SQL thread for executing events in the relay log is running. As with the I/O thread, this should normally be Yes
- Seconds_Behind_Master - The lag from the master
- Uptime - The number of seconds the MySQL server has been running.
- Current_Active_Clients - The number of active threads (clients).
- Queries_Since_Startup - The number of questions (queries) from clients since the server was started.
- Slow_queries - The number of queries that have taken more than long_query_time seconds.
- Opens_Tables - The number of tables the server has opened.
- Flush_Tables - The number of flush, refresh, and reload commands the server has executed.
- Current_Open_Tables - Total number of open tables in the database.
- Queries_per_second_avg - The number of tables that currently are open

***
## Required MySql permissions 

```
mysql> SHOW GRANTS FOR 'monitor_user'@'monitor_host';
+-------------------------------------------------------------------------------------------------------------------------------------------+
| Grants for monitor_user@monitor_host                                                                                                      |
+-------------------------------------------------------------------------------------------------------------------------------------------+
| GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'monitor_user'@'%' IDENTIFIED BY PASSWORD 'blabla'                                    |
+-------------------------------------------------------------------------------------------------------------------------------------------+
```

***
## Usage (docker run)

```
docker run -d --name logzio-mysql-monitor -e LOGZIO_TOKEN=VALUE -e MYSQL_HOST=VALUE -e MYSQL_USER=VALUE \
           [-e MYSQL_PASS=VALUE] [-e MYSQL_REPLICAS=VALUE] [-e INTERVAL_SECONDS=VALUE] [-e LOGZIO_LISTENER=VALUE] \
           -v path_to_directory:/var/log/logzio \
           logzio/mysql-monitor:latest
```

### Example
```bash
docker run -d \
  --name logzio-mysql-monitor \
  -e LOGZIO_TOKEN="MYSUPERAWESOMELOGZIOTOKEN" \
  -e MYSQL_HOST="master.sqlserver.hostname slave1.sqlserver.hostname slave2.sqlserver.hostname" \
  -e MYSQL_USER="myuser" \
  -e MYSQL_PASS="secret" \
  -e MYSQL_REPLICAS="slave1.sqlserver.hostname slave2.sqlserver.hostname" \
  -v /path/to/directory:/var/log/logzio \
  --restart=always \
  logzio/mysql-monitor:latest
```

#### Mandatory
**LOGZIO_TOKEN** - Your [Logz.io App](https://app.logz.io) token, where you can find under "settings" in the web app.
**MYSQL_HOST** - List of your mysql hosts to monitor.
**MYSQL_USER** - Your mysql user

#### Optional
**MYSQL_PASS** - Your mysql user. Default: None
**MYSQL_REPLICAS** - List of your mysql replicas to monitor. Default: None
**INTERVAL_SECONDS** - Number of seconds to sleep between each call to monitor. Default: 60
**LOGZIO_LISTENER** - Logzio listener host name. Default: listener.logz.io


***

## Usage (nagios monitor)
Nagios monitoring implements Nagios native plugin interface.
Which means by exit codes:
```bash
exit 0 # Everything is awesome
exit 1 # Warning!
exit 2 # Critical!!
exit 3 # Unknown
```
It will also print a message that both humans and Nagios loves. Expect something like:
```
CRITICAL: Users_Missing_Password is: 1, which is higher or equal to the critical threshold: 0 | Users_Missing_Password: 1
```
The data before the pipeline is for your notifications, and the data after the pipeline is for you to use in nagios performance data.

#### Available monitoring components and usage
```bash
docker exec CONTAINER_NAME /root/nagios.sh MYSQL_HOST COMPONENT -c CRITICAL -w WARNING
```

### Example
```bash
docker exec CONTAINER_NAME /root/nagios.sh "example.sqlserver.com" Seconds_Behind_Master -c 2 -w 1
```

All available are listed above. And you can also list them by running:

```bash
docker exec CONTAINER_NAME /root/nagios.sh
```

***
## Screenshots of dashboard from Logz.io
![alt text](https://images.contentful.com/50k90z6lk1k7/5M1Ayh1HxYuiY8soCgCCMc/fcaf1eb5fa28f98ec24a26fe96b222ac/mysql_monitor_dash.png?h=250& "Logz.io Dashboard")
***
## About Logz.io
[Logz.io](https://logz.io) combines open source log analytics and behavioural learning intelligence to pinpoint what’s actually important
