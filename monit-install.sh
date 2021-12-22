#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: monit-install.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 22-12-2021
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs the monit monitoring software on a FreeBSD system with Apache HTTP, MariaDB, PHP-FPM, Redis and Fail2ban monitorization on.
#
# REV LIST:
# DATE: 22-12-2021
# BY: ALBERT VALBUENA
# MODIFICATION: 22-12-2021
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Change the default pkg repository from quarterly to latest 
sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages (it will first download the pkg repo from latest)
# secondly it will upgrade any installed packages.
pkg upgrade -y

# Install monit
pkg install -y monit

# Get the service declared in /etc/rc.conf so it can be started at boot time
sysrc monit_enable="YES"

# Copy the sample configuration file into the main directory
cp /usr/local/etc/monitrc.sample /usr/local/etc/monitrc

# Configure monit processes
sed -i -e '/\/var\/run\/monit.pid/s/# set/set/' /usr/local/etc/monitrc

sed -i -e '/\/var\/.monit.id/s/# set/set/' /usr/local/etc/monitrc

sed -i -e '/\/var\/.monit.state/s/# set/set/' /usr/local/etc/monitrc

# Configure TLS
mkdir /usr/local/etc/monit.d

pkg install -y pwgen 

MONIT_PWD=$(pwgen 32 --secure --numerals --capitalize) && export MONIT_PWD && echo $MONIT_PWD >> /root/monit_pwd.txt

chmod 400 /root/monit_pwd.txt

echo '
set ssl {
      verify     : enable, # verify SSL certificates (disabled by default but STRONGLY RECOMMENDED)
      selfsigned : allow   # allow self signed SSL certificates (reject by default)
}' >> /usr/local/etc/monitrc

sed -i -e '/enable SSL\/TLS and set path/s/#with/with/' /usr/local/etc/monitrc
sed -i -e '/pemfile/s/#    pemfile: \/etc\/ssl\/certs\/monit.pem/pemfile: \/usr\/local\/etc\/monit.d\/server.pem }/' /usr/local/etc/monitrc

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /usr/local/etc/monit.d/server.key -out /usr/local/etc/monit.d/server.crt -subj "/C=ES/ST=StateName/L=CityName/O=OrganizationName/CN=example.com/emailAddress=youremail@gmail.com"

cat /usr/local/etc/monit.d/server.crt /usr/local/etc/monit.d/server.key > /usr/local/etc/monit.d/server.pem

chmod 400 /usr/local/etc/monit.d/server.pem

# Configure email for alerts:
sed -i -e '/receive all alerts/s/# set alert sysadm@foo.bar/set alert youremail@gmail.com/' /usr/local/etc/monitrc

# Configure services monitoring

# Monitor Apache HTTP
echo '
check process apache with pidfile /var/run/httpd.pid
        start program = "/usr/local/etc/rc.d/apache24 start" with timeout 60 seconds
        stop program = "/usr/local/etc/rc.d/apache24 stop"
        if cpu > 60% for 2 cycles then alert
        if cpu > 80% for 5 cycles then restart
        if totalmem > 700.0 MB for 5 cycles then alert
        if children > 500 then alert
        if disk read > 500 kb/s for 10 cycles then alert
        if disk write > 500 kb/s for 10 cycles then alert
        if 3 restarts within 5 cycles then unmonitor
        group server
' >> /usr/local/etc/monit.d/monit.httpd

echo '
include /usr/local/etc/monit.d/monit.httpd
' >> /usr/local/etc/monitrc

# Monitor MySQL/MariaDB
echo '
check process mysqld with pidfile /var/run/mysql/mysqld.pid
	start program = "/usr/local/etc/rc.d/mysql-server start" with timeout 60 seconds
	stop program = "/usr/local/etc/rc.d/mysql-server stop"
	if cpu > 60% for 2 cycles then alert
	if cpu > 80% for 5 cycles then restart
	if totalmem > 300.0 MB for 5 cycles then alert
	if children > 150 then alert
	if disk read > 500 kb/s for 10 cycles then alert
	if disk write > 500 kb/s for 10 cycles then alert
	if 3 restarts within 5 cycles then unmonitor
	group server
' >> /usr/local/etc/monit.d/monit.mysqld	

echo '
include /usr/local/etc/monit.d/monit.mysqld
' >> /usr/local/etc/monitrc	

# Monitor PHP-FPM
echo '
check process php-fpm with pidfile /var/run/php-fpm.pid
	start program = "/usr/local/etc/rc.d/php-fpm start" with timeout 60 seconds
	stop program = "/usr/local/etc/rc.d/php-fpm stop"
	if cpu > 60% for 2 cycles then alert
	if cpu > 80% for 5 cycles then restart
	if totalmem > 450.0 MB for 5 cycles then alert
	if children > 175 then alert
	if disk read > 500 kb/s for 10 cycles then alert
	if disk write > 500 kb/s for 10 cycles then alert
	if 3 restarts within 5 cycles then unmonitor
	group server
' >> /usr/local/etc/monit.d/monit.php-fpm

echo '
include /usr/local/etc/monit.d/monit.php-fpm
' >> /usr/local/etc/monitrc	

# Monitor Redis
echo '	
check process redis with pidfile /var/run/redis/redis.pid
	start program = "/usr/local/etc/rc.d/redis start" with timeout 60 seconds
	stop program = "/usr/local/etc/rc.d/redis stop"
	if cpu > 60% for 2 cycles then alert
	if cpu > 80% for 5 cycles then restart
	if totalmem > 300.0 MB for 5 cycles then alert
	if children > 150 then alert
	if disk read > 500 kb/s for 10 cycles then alert
	if disk write > 500 kb/s for 10 cycles then alert
	if 3 restarts within 5 cycles then unmonitor
	group server
' >> /usr/local/etc/monit.d/monit.redis	

echo '
include /usr/local/etc/monit.d/monit.redis
' >> /usr/local/etc/monitrc	

# Monitor Fail2ban
echo '
check process fail2ban with pidfile /var/run/fail2ban/fail2ban.pid
	start program = "/usr/local/etc/rc.d/fail2ban start" with timeout 60 seconds
	stop program = "/usr/local/etc/rc.d/fail2ban stop" 
	if cpu > 60% for 2 cycles then alert
	if cpu > 80% for 5 cycles then restart
	if totalmem > 70.0 MB for 5 cycles then alert
	if children > 35 then alert
	if disk read > 500 kb/s for 10 cycles then alert
	if disk write > 500 kb/s for 10 cycles then alert
	if 3 restarts within 5 cycles then unmonitor
	group server
' >> /usr/local/etc/monit.d/monit.fail2ban

echo '
include /usr/local/etc/monit.d/monit.fail2ban
' >> /usr/local/etc/monitrc	

if monit -t = OK
then service monit start
else echo 'The monit configuration in /usr/local/etc/monitrc is wrong.'
fi

# Display the location of the generated root password for MySQL
echo "Your MONIT_PASSWORD has been written on this file /root/monit_pwd.txt"

# Final install message
echo '
Monit has just been installed in your system. 
Configure the services and your options at will. 
Read more in the main configuration file located in: /usr/local/etc/monitrc.'
