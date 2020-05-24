#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Update packages list
pkg update

# Update actually installed packages
pkg upgrade -y

# Install Apache
pkg install -y apache24

# Add service to be fired up at boot time
sysrc apache24_enable="YES"

# Install MySQL
pkg install -y mysql80-server

# Add service to be fired up at boot time
sysrc mysql_enable="YES"

# Install PHP 7.3 and its 'funny' dependencies
pkg install -y php73 php73-mysqli mod_php73 php73-extensions

# Install the 'old fashioned' Expect to automate the mysql_secure_installation part
pkg install -y expect

# Create configuration file for Apache HTTP to 'speak' PHP
touch /usr/local/etc/apache24/modules.d/001_mod-php.conf

# Add the configuration into the file
echo "
<IfModule dir_module>
   DirectoryIndex index.php index.html
   <FilesMatch \"\.php$\"> 
        SetHandler application/x-httpd-php
    </FilesMatch>
    <FilesMatch \"\.phps$\">
        SetHandler application/x-httpd-php-source
    </FilesMatch>
</IfModule>" >> /usr/local/etc/apache24/modules.d/001_mod-php.conf

# Set the PHP's default configuration
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

# Fire up the services
service apache24 start
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

## References in the following URLs:

## https://www.adminbyaccident.com/freebsd/how-to-install-famp-stack/
## https://www.digitalocean.com/community/tutorials/how-to-install-an-apache-mysql-and-php-famp-stack-on-freebsd-12-0
