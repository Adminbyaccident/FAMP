#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Update packages list
pkg update

# Update actually installed packages
pkg upgrade -y

# Install MySQL
pkg install -y mysql80-server mysql80-client

# Add service to be fired up at boot time
sysrc mysql_enable="YES"

# Install the 'old fashioned' Expect to automate the mysql_secure_installation part
pkg install -y expect

# Fire up the MySQL service
service mysql-server start

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Press y|Y for Yes, any other key for No:\"
send \"y\r\"
expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
send \"0\r\"
expect \"New password:\"
send \"albertXP-24\r\"
expect \"Re-enter new password:\"
send \"albertXP-24\r\"
expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
send \"Y\r\"
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

echo "$SECURE_MYSQL"

# Remove the Expect package if not needed anymore
# pkg remove -y expect

echo "MySQL server 8.0 has been safely installed on this box"
