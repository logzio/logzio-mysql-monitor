FROM ubuntu:14.04

MAINTAINER Ofer Velich <ofer@logz.io>

RUN apt-get update; apt-get -y install software-properties-common; \
	add-apt-repository -y ppa:adiscon/v8-stable; apt-get update; \
	apt-get install -y rsyslog mysql-client-5.5 curl python-setuptools python-dateutil python-magic bc wget unzip default-jdk

ENV CHECKS_DIR /opt/logzio/mysqlchecks
ENV LOGZIO_LOGS_DIR /var/log/logzio
ENV MYSQL_LOGS_DIR /var/log/mysql

RUN mkdir -p $CHECKS_DIR; mkdir -p $MYSQL_LOGS_DIR; mkdir -p $LOGZIO_LOGS_DIR

ADD scripts/go.bash /root/
ADD scripts/nagios.sh /root/
ADD scripts/utils.sh /root/
ADD scripts/base.sh /root/
ADD scripts/checks_base.sh /root/
ADD scripts/checks/* $CHECKS_DIR/

WORKDIR /root
CMD "/root/go.bash"
