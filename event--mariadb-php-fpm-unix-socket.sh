#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: event-mariadb-php-fpm-unix-socket.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 17-11-2021
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs a full FAMP stack with Apache HTTP configured with MPM as Event + MariaDB + PHP-FPM configured to read from the UNIX socket
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
sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages (it will first download the pkg repo from latest)
# secondly it will upgrade any installed packages.
pkg upgrade -y

# Install Apache
pkg install -y apache24

# Add service to be fired up at boot time
sysrc apache24_enable="YES"

# Install PHP 7.4 and its 'funny' dependencies
pkg install -y php81 php81-mysqli php81-extensions

# Set a ServerName directive in Apache HTTP. Place a name to your server.
sed -i -e 's/#ServerName www.example.com:80/ServerName Famptest/g' /usr/local/etc/apache24/httpd.conf

# Configure Apache HTTP to use MPM Event instead of the Prefork default
# 1.- Disable the Prefork MPM
sed -i -e '/prefork/s/LoadModule/#LoadModule/' /usr/local/etc/apache24/httpd.conf

# 2.- Enable the Event MPM
sed -i -e '/event/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 3.- Enable the proxy module for PHP-FPM to use it
sed -i -e '/mod_proxy.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 4.- Enable the FastCGI module for PHP-FPM to use it
sed -i -e '/mod_proxy_fcgi.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Enable PHP to use the FPM process manager
sysrc php_fpm_enable="YES"

# Create configuration file for Apache HTTP to 'speak' PHP
touch /usr/local/etc/apache24/modules.d/003_php-fpm.conf

# Add the configuration into the file
echo "
<IfModule proxy_fcgi_module>
    <IfModule dir_module>
        DirectoryIndex index.php
    </IfModule>
    <FilesMatch \"\.(php)$\">
        SetHandler proxy:unix:/tmp/php-fpm.sock|fcgi://localhost/
    </FilesMatch>
</IfModule>" >> /usr/local/etc/apache24/modules.d/003_php-fpm.conf

# Set the PHP's default configuration
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

# Configure PHP-FPM to use a UNIX socket instead of a TCP one
# This configuration is better for standalone boxes
sed -i -e 's/127.0.0.1:9000/\/tmp\/php-fpm.sock/g' /usr/local/etc/php-fpm.d/www.conf
sed -i -e 's/;listen.owner/listen.owner/g' /usr/local/etc/php-fpm.d/www.conf
sed -i -e 's/;listen.group/listen.group/g' /usr/local/etc/php-fpm.d/www.conf

# Install MariaDB
echo "Installing MariaDB"
pkg install -y mariadb105-server mariadb105-client

# Add service to be fired up at boot time
sysrc mysql_enable="YES"
service mysql-server start

# Install the 'old fashioned' Expect to automate the mysql_secure_installation part
pkg install -y expect

# Make the 'safe' install for MariaDB
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

# Fire up the services
service apache24 start
service mysql-server start
service php-fpm start

## References in the following URLS:

## https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0
## https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/
## https://cwiki.apache.org/confluence/display/HTTPD/PHP-FPM
