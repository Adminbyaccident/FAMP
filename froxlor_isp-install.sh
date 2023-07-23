#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: froxlor_isp-install.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 23-07-2023
# SET FOR: Alpha
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs Froxlor ISP on top of a full FAMP stack 
# with Apache HTTP configured with MPM as Event + MariaDB + PHP-FPM configured 
# to read from the UNIX socket
#
# REV LIST:
# DATE: 23-07-2023
# BY: ALBERT VALBUENA
# MODIFICATION: 23-07-2023
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

# Install PHP 8.1 and its 'funny' dependencies
pkg install -y 	php81\
				php81-bcmath\
				php81-brotli\
				php81-bz2\
				php81-ctype\
				php81-curl\
				php81-dom\
				php81-exif\
				php81-extensions\
				php81-fileinfo\
				php81-filter\
				php81-gd\
				php81-iconv\
				php81-intl\
				php81-mbstring\
				php81-mysqli\
				php81-opcache\
				php81-pdo\
				php81-pdo_mysql\
				php81-pdo_sqlite\
				php81-pecl-imagick\
				php81-pecl-mcrypt\
				php81-pecl-memcache\
				php81-pecl-memcached\
				php81-pecl-redis\
				php81-phar\
				php81-posix\
				php81-readline\
				php81-session\
				php81-simplexml\
				php81-soap\
				php81-sockets\
				php81-sqlite3\
				php81-tidy\
				php81-tokenizer\
				php81-xml\
				php81-xmlreader\
				php81-xmlwriter\
				php81-zip\
				php81-zlib\
				php81-gmp

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

# Fine tunning access to the DocumentRoot directory structure
sed -i '' -e 's/Options Indexes FollowSymLinks/Options -Indexes +FollowSymLinks -Includes/' /usr/local/etc/apache24/httpd.conf

# Install MariaDB
echo "Installing MariaDB"
pkg install -y mariadb1011-server mariadb1011-client

# Add service to be fired up at boot time
sysrc mysql_enable="YES"
sysrc mysql_args="--bind-address=127.0.0.1"
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

# Install Froxlor
pkg install -y froxlor

# Change ownership of Froxlor files to the "www" user and group
chown -R www:www /usr/local/www/froxlor

# Configure Apache HTTP for Froxlor
sed -i -e '/DocumentRoot/s/\/usr\/local\/www\/apache24\/data/\/usr\/local\/www\/froxlor/' /usr/local/etc/apache24/httpd.conf
sed -i -e '/Directory "\/usr\/local\/www\/apache24\/data"/s/Directory "\/usr\/local\/www\/apache24\/data"/Directory "\/usr\/local\/www\/froxlor"/' /usr/local/etc/apache24/httpd.conf
sed -i -e '/Directory "\/usr\/local\/www\/apache24\/data"/s/AllowOverride None/AllowOverride All"/' /usr/local/etc/apache24/httpd.conf

# Restart Apache HTTP to load the changes
service apache24 restart

# Enabling TLS connections with a self signed certificate. 
# Key and certificate generation
# IMPORTANT: Please do adapt to your needs the fields below like: Organization, Common Name and Email, etc.
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /usr/local/etc/apache24/server.key -out /usr/local/etc/apache24/server.crt -subj "/C=ES/ST=Barcelona/L=Terrassa/O=Adminbyaccident.com/CN=example.com/emailAddress=youremail@gmail.com"

# Because we have generated a certificate + key we will enable SSL/TLS in the server.
# Enabling TLS connections in the server.
sed -i -e '/mod_ssl.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Enable the server's default TLS configuration to be applied.
sed -i -e '/httpd-ssl.conf/s/#Include/Include/' /usr/local/etc/apache24/httpd.conf

# Enable TLS session cache.
sed -i -e '/mod_socache_shmcb.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Redirect HTTP connections to HTTPS (port 80 and 443 respectively)
# Enabling the rewrite module
sed -i -e '/mod_rewrite.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Adding the redirection rules.
# Use the following sed entries if you are using the event-php-fpm.sh script.
sed -i '' -e '181i\
RewriteEngine On' /usr/local/etc/apache24/httpd.conf

sed -i '' -e '182i\
RewriteCond %{HTTPS}  !=on' /usr/local/etc/apache24/httpd.conf

sed -i '' -e '183i\
RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]' /usr/local/etc/apache24/httpd.conf

# Final message installation
echo 'You can now finish the install process in a GUI fashion using your browser by pointing it to the IP address this server sits.'
echo 'Be aware before the end of the GUI install you will be instructed to choose a configuration set among Linux distros and not BSD.'
echo 'Since you will not be able to choose the right configuration, services like Dovecot, Postfix, ProFTPd, will not be properly configured.'
echo 'Due to this, Froxlor will work on FreeBSD but those other services will need manual configuration from you, since there is no support outside Linux.'

## References in the following URLS:

## https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0
## https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/
## https://cwiki.apache.org/confluence/display/HTTPD/PHP-FPM
