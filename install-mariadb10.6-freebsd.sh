#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: install-mariadb10.5-freebsd.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 05-06-2021
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs MariaDB 10.6
#
# REV LIST:
# DATE: 01-08-2022
# BY: ALBERT VALBUENA
# MODIFICATION: 01-08-2022
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Change the default pkg repository from quarterly to latest
echo "Configuring PKG"
sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages (it will first download the pkg repo from latest)
# secondly it will upgrade any installed packages.
echo "Upgradng PKG"
pkg upgrade -y

# Install MySQL
echo "Installing MariaDB"
pkg install -y mariadb106-server mariadb106-client

# Add service to be fired up at boot time
sysrc mysql_enable="YES"
service mysql-server start

# Install the 'old fashioned' Expect to automate the mysql_secure_installation part
pkg install -y expect

# Uncomment the line below if you prefer to have a password protected access to MariaDB
# instead of just using privileges inherited from using the system's root account.
# Do also uncomment the second expect script and comment out the first one when enabling this below.
# More details here: https://mariadb.com/kb/en/authentication-plugin-unix-socket/

#pkg install -y pwgen
#DB_ROOT_PASSWORD=$(pwgen 32 --secure --numerals --capitalize) && export DB_ROOT_PASSWORD && echo $DB_ROOT_PASSWORD >> /root/db_root_pwd.txt

# Make the hideous 'safe' install for MySQL
echo "Performing MariaDB secure install"

SECURE_MARIADB=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Switch to unix_socket authentication\"
send \"n\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MARIADB"

#SECURE_MARIADB=$(expect -c "
#set timeout 2
#spawn mysql_secure_installation
#expect \"Switch to unix_socket authentication\"
#send \"y\r\"
#expect \"Change the root password?\"
#send \"y\r\"
#expect \"New password\r\"
#send \"$DB_ROOT_PASSWORD\r\"
#expect \"Re-enter new password:\r\"
#send \"$DB_ROOT_PASSWORD\r\"
#expect \"Remove anonymous users?\"
#send \"y\r\"
#expect \"Disallow root login remotely?\"
#send \"y\r\"
#expect \"Remove test database and access to it?\"
#send \"y\r\"
#expect \"Reload privilege tables now?\"
#send \"y\r\"
#expect eof
#")

#echo "$SECURE_MARIADB"

# No one but root can read this file. Read only permission. Uncomment if pwgen is used for the DB password generation.
# chmod 400 /root/db_root_pwd.txt

# EOF
