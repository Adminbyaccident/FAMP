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
# Apache Pre-fork MPM 
# https://github.com/Adminbyaccident/FAMP/blob/master/stdard-famp.sh
#
# Apache Event MPM + PHP-FPM on TCP socket
# https://github.com/Adminbyaccident/FAMP/blob/master/event-php-fpm-tcp-socket.sh
#
# Apache Event MPM + PHP-FPM on UNIX socket
# https://github.com/Adminbyaccident/FAMP/blob/master/event-php-fpm-unix-socket.sh
#
# To harden this set up use the following security script for the FAMP stack:
# https://github.com/Adminbyaccident/FAMP/blob/master/apache-hardening.sh
#
# At a later time you may want to increase Nextcloud's performance by enhancing
# Apache's HTTP configuration with the Event MPM and enhancing the DB performance
# which is very useful when file count increases by using Redis or similar cache
# programs.
#
# Remember to adapt this script to your needs wether you are using a domain or 
# an ip to access your Nextcloud instance.
####################################################################################

# Update packages sources on the system first
pkg upgrade -y

# Install GNU sed
pkg install -y gsed

# Configure PHP (already installed by the previous FAMP script) to use 512M instead of the default 128M
gsed -i 's/memory_limit = 128M/memory_limit = 512M/g' /usr/local/etc/php.ini

# Install specific PHP dependencies for Nextcloud
pkg install -y php74-zip php74-mbstring php74-gd php74-zlib php74-curl php74-openssl php74-pdo_mysql php74-pecl-imagick php74-intl php74-bcmath php74-gmp php74-fileinfo

# Install Nextcloud
# Fetch Nextcloud
fetch -o /usr/local/www/nextcloud-19.0.3.zip https://download.nextcloud.com/server/releases/nextcloud-19.0.3.zip

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
gsed -i 's/#Include etc\/apache24\/extra\/httpd-vhosts.conf/Include etc\/apache24\/extra\/httpd-vhosts.conf/g' /usr/local/etc/apache24/httpd.conf

# Set a VirtualHost configuration for Nextcloud

echo "
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

## References:
## https://docs.nextcloud.com/server/stable/admin_manual/installation/source_installation.html
## Pending to write article at adminbyaccident.com
