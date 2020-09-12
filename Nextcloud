#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# This script will install a Nextcloud instance on a FreeBSD box.

################################# WARNING!! ########################################
# This script must be used after having installed Nextcloud dependencies.
# The base ones will be met by installing a FAMP stack server.
# You may use this script for this: 
# https://github.com/Adminbyaccident/FAMP/blob/master/stdard-famp.sh
# To harden this set up use the following security script for the FAMP stack:
# https://github.com/Adminbyaccident/FAMP/blob/master/apache-hardening.sh
# At a later time you may want to increase Nextcloud performance by enhancing
# Apache's HTTP configuration with the Event MPM and enhancing the DB performance
# which is very useful when file count increases by using Redis or similar cache
# programs.
####################################################################################

# Update packages sources on the system first
pkg upgrade -y

# Install specific PHP dependencies for Nextcloud
# pkg install -y php74-zip php74-mbstring php74-gd php74-zlib php74-curl php74-openssl

# Install Nextcloud
# Your PHP version on the FAMP stack must match the one for Nextcloud
pkg install -y nextcloud-php74

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

# Set a VirtualHost configuration for Nextcloud
# Mind there is no configuration for port 80.
echo "
<VirtualHost *:443>
    ServerName Nextcloud
    ServerAlias Nextcloud
    DocumentRoot "/usr/local/www/nextcloud"
    SSLEngine on
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLHonorCipherOrder on
    SSLCipherSuite  ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    SSLCertificateFile "/usr/local/etc/apache24/ssl/cert.crt"
    SSLCertificateKeyFile "/usr/local/etc/apache24/ssl/cert.key"
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
