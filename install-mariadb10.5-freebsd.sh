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
# PURPOSE: This script installs MariaDB 10.5
#
# REV LIST:
# DATE: 12-12-2021
# BY: ALBERT VALBUENA
# MODIFICATION: 12-12-2021
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
pkg install -y mariadb105-server mariadb105-client

# Add service to be fired up at boot time
sysrc mysql_enable="YES"
service mysql-server start

# Install the 'old fashioned' Expect to automate the mysql_secure_installation part
pkg install -y expect

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

# EOF
