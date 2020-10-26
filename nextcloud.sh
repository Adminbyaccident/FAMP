#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# This script will install a Nextcloud instance on a FreeBSD box.

################################# WARNING!! ########################################
# This script must be used after having installed Nextcloud dependencies.
# The base ones will be met by installing a FAMP stack server.
# You may use one of the following three scripts for this: 
#
#
# Apache Pre-fork MPM 
# https://github.com/Adminbyaccident/FAMP/blob/master/stdard-famp.sh
#
# Apache Event MPM + PHP-FPM on TCP socket
# https://github.com/Adminbyaccident/FAMP/blob/master/event-php-fpm-tcp-socket.sh
#
# Apache Event MPM + PHP-FPM on UNIX socket
# https://github.com/Adminbyaccident/FAMP/blob/master/event-php-fpm-unix-socket.sh
#
#
# Once the base system, a FAMP stack, has been installed one may use the following 
# security script to enhance the overall security:
#
# https://github.com/Adminbyaccident/FAMP/blob/master/apache-hardening.sh
#
# 
# Apache's HTTP configuration with the Event MPM is more performant than the pre-fork one.
# The DB performance can be improved, which is very useful when file count increases 
# by using Redis or similar cache programs.
#
# Remember to adapt this script to your needs wether you are using a domain or 
# an ip to access your Nextcloud instance.
####################################################################################

# Update packages sources on the system first
pkg upgrade -y

# Configure PHP (already installed by the previous FAMP script) to use 512M instead of the default 128M
sed -i -e '/memory_limit/s/128M/512M/' /usr/local/etc/php.ini

# Install specific PHP dependencies for Nextcloud
pkg install -y php74-zip php74-mbstring php74-gd php74-zlib php74-curl php74-openssl php74-pdo_mysql php74-pecl-imagick php74-intl php74-bcmath php74-gmp php74-fileinfo

# Install Nextcloud
# Fetch Nextcloud
fetch -o /usr/local/www/nextcloud-20.0.1.zip https://download.nextcloud.com/server/releases/nextcloud-20.0.1.zip

# Unzip Nextcloud
unzip -d /usr/local/www/ /usr/local/www/nextcloud-19.0.3.zip

# Change the ownership so the Apache user (www) owns it
chown -R www:www /usr/local/www/nextcloud

# Make a backup copy of the currently working httpd.conf file
cp /usr/local/etc/apache24/httpd.conf /usr/local/etc/apache24/httpd.conf.backup

# Add the configuration needed for Apache to serve Nextcloud
echo "
Alias /nextcloud /usr/local/www/nextcloud
AcceptPathInfo On
<Directory /usr/local/www/nextcloud>
    AllowOverride All
    Require all granted
</Directory>" >> /usr/local/etc/apache24/httpd.conf

# Enable VirtualHost
sed -i -e '/httpd-vhosts.conf/s/#Include/Include/' /usr/local/etc/apache24/httpd.conf

# Make a backup of the current httpd-vhosts (virtual host) configuration file
cp /usr/local/etc/apache24/extra/httpd-vhosts.conf /usr/local/etc/apache24/extra/httpd-vhosts.conf.bckp

# Remove the original virtual host file (we've made a backup to restore from, don't panic)
rm /usr/local/etc/apache24/extra/httpd-vhosts.conf

# Create a new empty virtual host file:

# Set a VirtualHost configuration for Nextcloud

echo "
# Virtual Hosts
#
# Required modules: mod_log_config

# If you want to maintain multiple domains/hostnames on your
# machine you can setup VirtualHost containers for them. Most configurations
# use only name-based virtual hosts so the server doesn't need to worry about
# IP addresses. This is indicated by the asterisks in the directives below.
#

# Please see the documentation at
# <URL:http://httpd.apache.org/docs/2.4/vhosts/>
# for further details before you try to setup virtual hosts.
#
# You may use the command line option '-S' to verify your virtual host
# configuration.

#
# VirtualHost example:
# Almost any Apache directive may go into a VirtualHost container.
# The first VirtualHost section is used for all requests that do not
# match a ServerName or ServerAlias in any <VirtualHost> block.
#

<VirtualHost *:80>
    ServerName Nextcloud
    ServerAlias Nextcloud
    DocumentRoot "/usr/local/www/nextcloud"
    ErrorLog "/var/log/nextcloud-error_log"
    CustomLog "/var/log/nextcloud-access_log" common
    RewriteEngine On
    RewriteCond %{HTTPS}  !=on
    RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]
    Protocols h2 h2c http/1.1
</VirtualHost>

<VirtualHost *:443>
    ServerName Nextcloud
    ServerAlias Nextcloud
    DocumentRoot "/usr/local/www/nextcloud"
    SSLEngine on
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLHonorCipherOrder on
    SSLCipherSuite  ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    Include /usr/local/etc/apache24/Includes/headers.conf
	SSLCertificateFile "/usr/local/etc/apache24/server.crt"
    SSLCertificateKeyFile "/usr/local/etc/apache24/server.key"
    ErrorLog "/var/log/nextcloud-error_log"
    CustomLog "/var/log/nextcloud-access_log" common
    Protocols h2 http/1.1
</VirtualHost>" >> /usr/local/etc/apache24/extra/httpd-vhosts.conf

# Restart Apache service
service apache24 restart

# Create the database for Nextcloud and user. Mind this is MySQL version 8
# Mind we have Expect already installed on the system because of the previous scripts.
NEW_DATABASE=$(expect -c "
set timeout 10
spawn mysql -u root -p
expect \"Enter password:\"
send \"albertXP-24\r\"
expect \"root@localhost \[(none)\]>\"
send \"CREATE DATABASE Nextcloud;\r\"
expect \"root@localhost \[(none)\]>\"
send \"CREATE USER 'barrufeta'@'localhost' IDENTIFIED WITH mysql_native_password BY 'barrufetaXP-64';\r\"
expect \"root@localhost \[(none)\]>\"
send \"GRANT ALL PRIVILEGES ON Nextcloud.* TO 'barrufeta'@'localhost';\r\"
expect \"root@localhost \[(none)\]>\"
send \"FLUSH PRIVILEGES;\r\"
expect \"root@localhost \[(none)\]>\"
send \"exit\r\"
expect eof
")

echo "$NEW_DATABASE"

# Now Visit your server ip and finish the GUI install. 
# Be aware of the default SQLite DB install. Select the MySQL option!!
# https://yourserverip/nextcloud

# If you want to make the install through the script just tune the DB values above and the values just below. 
# Please change the username and password values before issuing this script.
su -m www -c 'php /usr/local/www/nextcloud/occ maintenance:install --database "mysql" --database-name "Nextcloud" --database-user "barrufeta" --database-pass "barrufetaXP-64" --admin-user "admin" --admin-pass "password"'

## References:
## https://docs.nextcloud.com/server/stable/admin_manual/installation/source_installation.html
## Pending to write article at adminbyaccident.com
