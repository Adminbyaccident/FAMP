#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# This is a full Wordpress install on:
# FreeBSD 12 + Apache 2.4 latest pkg + MySQL 8 + PHP 7.4
# Apache HTTP is set on MPM Event and PHP-FPM
# Certificate is self signed
# Change ServerName, DB name, usernames, etc to your needs.

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
    <FilesMatch \"\.(php|phtml|inc)$\">
        SetHandler "proxy:fcgi://127.0.0.1:9000"
    </FilesMatch>
</IfModule>" >> /usr/local/etc/apache24/modules.d/003_php-fpm.conf

# Set the PHP's default configuration
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

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

# Install GNU sed to circumvent some of the syntax challenges the BSD sed has
# such as inserting a line of text in a specific location needing a new line, etc.
pkg install -y gsed

# Be aware we are using GNU sed here. 
# When inserting lines do it from bottom to top or inserting new lines can disrupt
# the default order of a file, eventually breaking the configuration.
# Consider using echo instead.

# 1.- Removing the OS type and modifying version banner (no mod_security here). 
# 1.1- ServerTokens will only display the minimal information possible.
gsed -i '227i\ServerTokens Prod' /usr/local/etc/apache24/httpd.conf

# 1.2- ServerSignature will disable the server exposing its type.
gsed -i '228i\ServerSignature Off' /usr/local/etc/apache24/httpd.conf

# Alternatively we can inject the line at the bottom of the file using the echo command.
# This is a safer option if you make heavy changes at the top of the file.
# echo 'ServerTokens Prod' >> /usr/local/etc/apache24/httpd.conf
# echo 'ServerSignature Off' >> /usr/local/etc/apache24/httpd.conf

# 2.- Avoid PHP's information (version, etc) being disclosed
sed -i -e '/expose_php/s/expose_php = On/expose_php = Off/' /usr/local/etc/php.ini

# 3.- Fine tunning access to the DocumentRoot directory structure
sed -i '' -e 's/Options Indexes FollowSymLinks/Options -Indexes +FollowSymLinks -Includes/' /usr/local/etc/apache24/httpd.conf

# 4.- Enabling TLS connections with a self signed certificate. 
# 4.1- Key and certificate generation
# Because this is a process where manual interaction is required let's make use of Expect so no hands are needed.

SECURE_APACHE=$(expect -c "
set timeout 10
spawn openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /usr/local/etc/apache24/server.key -out /usr/local/etc/apache24/server.crt
expect \"Country Name (2 letter code) \[AU\]:\"
send \"ES\r\"
expect \"State or Province Name (full name) \[Some-State\]:\"
send \"Barcelona\r\"
expect \"Locality Name (eg, city) \[\]:\"
send \"Terrassa\r\"
expect \"Organization Name (eg, company) \[Internet Widgits Pty Ltd\]:\"
send \"Adminbyaccident.com\r\"
expect \"Organizational Unit Name (eg, section) \[\]:\"
send \"Operations\r\"
expect \"Common Name (e.g. server FQDN or YOUR name) \[\]:\"
send \"Albert Valbuena\r\"
expect \"Email Address \[\]:\"
send \"thewhitereflex@gmail.com\r\"
expect eof
")

echo "$SECURE_APACHE"

# Because we have generated a certificate + key we will enable SSL/TLS in the server.
# 4.3- Enabling TLS connections in the server.
sed -i -e '/mod_ssl.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 4.4- Enable the server's default TLS configuration to be applied.
sed -i -e '/httpd-ssl.conf/s/#Include/Include/' /usr/local/etc/apache24/httpd.conf

# 4.5- Enable TLS session cache.
sed -i -e '/mod_socache_shmcb.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 4.6- Redirect HTTP connections to HTTPS (port 80 and 443 respectively)
# 4.6.1- Enabling the rewrite module
sed -i -e '/mod_rewrite.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 4.6.2- Adding the redirection rules.
# Use the following GNU sed entries if you are using the event-php-fpm.sh script.
gsed -i '181i\RewriteEngine On' /usr/local/etc/apache24/httpd.conf
gsed -i '182i\RewriteCond %{HTTPS}  !=on' /usr/local/etc/apache24/httpd.conf
gsed -i '183i\RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]' /usr/local/etc/apache24/httpd.conf

# Use the following entries (by uncommenting these and commenting the above GNU sed ones) 
# if you are using the stdard-famp.sh script, or things will break.
# echo 'RewriteEngine On' /usr/local/etc/apache24/httpd.conf
# echo 'RewriteCond %{HTTPS}  !=on' /usr/local/etc/apache24/httpd.conf
# echo 'RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]' /usr/local/etc/apache24/httpd.conf

# 5.- Secure headers
echo "
<IfModule mod_headers.c>
    Header set Content-Security-Policy \"upgrade-insecure-requests;\"
    Header set Strict-Transport-Security \"max-age=31536000; includeSubDomains\"
    Header always edit Set-Cookie (.*) \"\$1; HttpOnly; Secure\"
    Header set X-Content-Type-Options \"nosniff\"
    Header set X-XSS-Protection \"1; mode=block\"
    Header set Referrer-Policy \"strict-origin\"
    Header set X-Frame-Options: \"deny\"
    SetEnv modHeadersAvailable true
</IfModule>" >>  /usr/local/etc/apache24/httpd.conf

# 6.- Disable the TRACE method.
echo 'TraceEnable off' >> /usr/local/etc/apache24/httpd.conf

# 7.- Allow specific HTTP methods.
gsed -i '269i\    <LimitExcept GET POST HEAD>' /usr/local/etc/apache24/httpd.conf
gsed -i '270i\       deny from all' /usr/local/etc/apache24/httpd.conf
gsed -i '271i\    </LimitExcept>' /usr/local/etc/apache24/httpd.conf

# 8.- Restart Apache HTTP so changes take effect.
service apache24 restart


# Install Wordpress on FreeBSD after having used the following scripts:
# event-php-fpm.sh
# apache-hardening.sh

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

# Install the missing PHP packages
pkg install -y php74-bz2 php74-curl php74-gd php74-mbstring php74-pecl-mcrypt php74-openssl php74-pdo_mysql php74-zip php74-zlib

# Because Wordpress and plugins will make use of an .htaccess file, let's enable it.
sed -i -e "278s/AllowOverride None/AllowOverride All/" /usr/local/etc/apache24/httpd.conf

# Restart Apache HTTP so changes take effect
service apache24 restart

# Fetch Wordpress from the official site
fetch https://wordpress.org/latest.tar.gz

# Unpack Wordpress
tar -zxvf latest.tar.gz

# Create the main config file from the sample
cp /root/wordpress/wp-config-sample.php /root/wordpress/wp-config.php

# Add the database name into the wp-config.php file
NEW_DB=$(cat  /root/new_db_name.txt) && export NEW_DB
sed -i -e 's/database_name_here/'"$NEW_DB"'/g' /root/wordpress/wp-config.php


# Add the username into the wp-config.php file
USER_NAME=$(cat /root/new_db_user_name.txt) && export USER_NAME
sed -i -e 's/username_here/'"$USER_NAME"'/g' /root/wordpress/wp-config.php

# Add the db password into the wp-config.php file
PASSWORD=$(cat /root/newdb_pwd.txt) && export PASSWORD
sed -i -e 's/password_here/'"$PASSWORD"'/g' /root/wordpress/wp-config.php

# Move the content of the wordpress file into the DocumentRoot path
cp -r /root/wordpress/* /usr/local/www/apache24/data

# Change the ownership of the DocumentRoot path content from root to the Apache HTTP user (named www)
chown -R www:www /usr/local/www/apache24/data

# Preventive services restart
service apache24 restart
service php-fpm restart
service mysql-server restart

# No one but root can read these files. Read only permissions.
chmod 400 /root/db_root_pwd.txt
chmod 400 /root/new_db_name.txt
chmod 400 /root/new_db_user_name.txt
chmod 400 /root/newdb_pwd.txt

# Display the new database, username and password generated on MySQL to accomodate WordPress
echo "Your DB_ROOT_PASSWORD is written on this file /root/db_root_pwd.txt"
echo "Your NEW_DB_NAME is written on this file /root/new_db_name.txt"
echo "Your NEW_DB_USER_NAME is written on this file /root/new_db_user_name.txt"
echo "Your NEW_DB_PASSWORD is written on this file /root/newdb_pwd.txt"

# Actions on the CLI are now finished.
echo 'Actions on the CLI are now finished. Please visit the ip/domain of the site with a browser and proceed with the install'

## Reference articles:

## https://www.digitalocean.com/community/tutorials/how-to-install-an-apache-mysql-and-php-famp-stack-on-freebsd-12-0
## https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0
## https://www.adminbyaccident.com/freebsd/how-to-install-famp-stack/
## https://www.adminbyaccident.com/security/how-to-harden-apache-http/
## https://www.digitalocean.com/community/tutorials/recommended-steps-to-harden-apache-http-on-freebsd-12-0
## https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

## EOF
