#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Change the default pkg repository from quarterly to latest
sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages (it will first download the pkg repo from latest)
# secondly it will upgrade any installed packages.
pkg upgrade -y

# Install Apache
pkg install -y apache24

# Add service to be fired up at boot time
sysrc apache24_enable="YES"

# Install MySQL
pkg install -y mysql80-server

# Add service to be fired up at boot time
sysrc mysql_enable="YES"

# Install PHP 7.4 and its 'funny' dependencies
pkg install -y php74 php74-mysqli php74-extensions

# Install the 'old fashioned' Expect to automate the mysql_secure_installation part
pkg install -y expect

# Set a ServerName directive in Apache HTTP. Place a name to your server.
sed -i -e 's/#ServerName www.example.com:80/ServerName California/g' /usr/local/etc/apache24/httpd.conf

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

# Install GNU Sed
pkg install -y gsed

# Configure PHP-FPM to use a UNIX socket instead of a TCP one
# This configuration is better for standalone boxes
gsed -i 's/127.0.0.1:9000/\/tmp\/php-fpm.sock/g' /usr/local/etc/php-fpm.d/www.conf
gsed -i 's/;listen.owner/listen.owner/g' /usr/local/etc/php-fpm.d/www.conf
gsed -i 's/;listen.group/listen.group/g' /usr/local/etc/php-fpm.d/www.conf


# Fire up the services
service apache24 start
service mysql-server start
service php-fpm start

# Make the hideous 'safe' install for MySQL
pkg install -y pwgen

DB_ROOT_PASSWORD=$(pwgen 32 --secure --numerals --capitalize) && export DB_ROOT_PASSWORD && echo $DB_ROOT_PASSWORD >> /root/db_root_pwd.txt

SECURE_MYSQL=$(expect -c "
set timeout 10
set DB_ROOT_PASSWORD "$DB_ROOT_PASSWORD"
spawn mysql_secure_installation
expect \"Press y|Y for Yes, any other key for No:\"
send \"y\r\"
expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
send \"0\r\"
expect \"New password:\"
send \"$DB_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$DB_ROOT_PASSWORD\r\"
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

# Enable the SSL/TLS module
sed -i -e '/mod_ssl.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Enable the default SSL/TLS configuration
sed -i -e '/httpd-ssl.conf/s/#Include/Include/' /usr/local/etc/apache24/httpd.conf

# Enable the SSL/TLS cache module
sed -i -e '/mod_socache_shmcb.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Enable the rewrite module
sed -i -e '/mod_rewrite.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Create a self-signed certificate and key for Apache HTTP (ADAPT Organization, Common Name and Email)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /usr/local/etc/apache24/server.key -out /usr/local/etc/apache24/server.crt -subj "/C=ES/ST=Barcelona/L=Terrassa/O=Adminbyaccident.com/CN=example.com/emailAddress=youremail@gmail.com"

# Restart Apache HTTP to make changes effective
service apache24 restart

# Enable VirtualHosts
sed -i -e '/httpd-vhosts/s/#Include/Include/' /usr/local/etc/apache24/httpd.conf

# Restart Apache HTTP to make changes effective
service apache24 restart

# Inform the user SSL/TLS and VirtualHosts are now enabled on this server.
echo "SSL/TLS and VirtualHosts have been enabled on this server"

# Remove the existing VirtualHosts configuration file
rm /usr/local/etc/apache24/extra/httpd-vhosts.conf

# Create an empty VirtualHosts configuration file
touch /usr/local/etc/apache24/extra/httpd-vhosts.conf

# Add the configuration bits for MediaWiki
echo "
<VirtualHost *:80>
   Alias /mediawiki /usr/local/www/mediawiki
    AcceptPathInfo On
    DocumentRoot /usr/local/www/mediawiki/
    ServerAdmin admin@your-domain.com
    ServerName mediawiki
    RewriteEngine On
    RewriteCond %{HTTPS}  !=on
    RewriteRule ^/?(.*) https://%{SERVER_NAME}/\$1 [R,L]
    Protocols h2 h2c http/1.1
</VirtualHost>

<VirtualHost *:443>
    ServerAdmin admin@your-domain.com
    ServerName mediawiki
    Alias /mediawiki /usr/local/www/mediawiki
    AcceptPathInfo On
    DocumentRoot /usr/local/www/mediawiki/
    <Directory /usr/local/www/mediawiki>
        AllowOverride None
        # Serve HTML as plaintext, don't execute SHTML
        AddType text/plain .html .htm .shtml .phtml
        Require all granted
    </Directory>
    Options FollowSymLinks
    SSLCertificateFile /usr/local/etc/apache24/server.crt
    SSLCertificateKeyFile /usr/local/etc/apache24/server.key
    ErrorLog /var/log/mediawiki_error
    CustomLog /var/log/mediawiki_access common
</VirtualHost>
" >> /usr/local/etc/apache24/extra/httpd-vhosts.conf

# Restart Apache HTTP to enable the changes
service apache24 restart

# Create the database and user. Mind this is MySQL version 8
NEW_DB_NAME=$(pwgen 8 --secure --numerals --capitalize) && export NEW_DB_NAME && echo $NEW_DB_NAME >> /root/new_db_name.txt

NEW_DB_USER_NAME=$(pwgen 10 --secure --numerals --capitalize) && export NEW_DB_USER_NAME && echo $NEW_DB_USER_NAME >> /root/new_db_user_name.txt

NEW_DB_PASSWORD=$(pwgen 32 --secure --numerals --capitalize) && export NEW_DB_PASSWORD && echo $NEW_DB_PASSWORD >> /root/newdb_pwd.txt

NEW_DATABASE=$(expect -c "
set timeout 10
spawn mysql -u root -p
expect \"Enter password:\"
send \"$DB_ROOT_PASSWORD\r\"
expect \"root@localhost \[(none)\]>\"
send \"CREATE DATABASE $NEW_DB_NAME;\r\"
expect \"root@localhost \[(none)\]>\"
send \"CREATE USER '$NEW_DB_USER_NAME'@'localhost' IDENTIFIED WITH mysql_native_password BY '$NEW_DB_PASSWORD';\r\"
expect \"root@localhost \[(none)\]>\"
send \"GRANT ALL PRIVILEGES ON $NEW_DB_NAME.* TO '$NEW_DB_USER_NAME'@'localhost';\r\"
expect \"root@localhost \[(none)\]>\"
send \"FLUSH PRIVILEGES;\r\"
expect \"root@localhost \[(none)\]>\"
send \"exit\r\"
expect eof
")

echo "$NEW_DATABASE"

# Install the missing PHP packages for MediaWiki
pkg install -y php74-mbstring php74-curl php74-intl php74-gd php74-fileinfo texlive-base imagemagick7

# Restart the PHP-FPM service to reload with the recenyly installed PHP packages
service php-fpm restart

# Download MediaWiki
fetch -o /tmp https://releases.wikimedia.org/mediawiki/1.35/mediawiki-1.35.1.tar.gz 

# Unpack the tarball
tar -zxf /tmp/mediawiki-1.35.1.tar.gz -C /tmp

# Take the MediaWiki files to its new location
mv /tmp/mediawiki-1.35.1 /usr/local/www/

# Change the mediawiki directory name
mv /usr/local/www/mediawiki-1.35.1 /usr/local/www/mediawiki

# Change ownership of the MediaWiki directory
chown -R www:www /usr/local/www/mediawiki

# No one but root can read these files. Read only permissions.
chmod 400 /root/db_root_pwd.txt
chmod 400 /root/new_db_name.txt
chmod 400 /root/new_db_user_name.txt
chmod 400 /root/newdb_pwd.txt

# Display the new database, username and password generated on MySQL
echo "Your DB_ROOT_PASSWORD is written on this file /root/db_root_pwd.txt"
echo "Your NEW_DB_NAME is written on this file /root/new_db_name.txt"
echo "Your NEW_DB_USER_NAME is written on this file /root/new_db_user_name.txt"
echo "Your NEW_DB_PASSWORD is written on this file /root/newdb_pwd.txt"

# Final message
echo"
MediaWiki has been installed on this server. Please visit the URL of this server with your browser and finish the install there"

## References in the following URLS:

## https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0
## https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/
## https://cwiki.apache.org/confluence/display/HTTPD/PHP-FPM
