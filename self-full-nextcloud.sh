#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: self-full-nextcloud.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 06-02-2021
# SET FOR: Test
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs a FAMP stack with a NextCloud install on top.
#
# REV LIST:
# DATE: 03-08-2022
# BY: ALBERT VALBUENA
# MODIFICATION: 03-08-2022
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Message for the user before anything is done
echo "Make sure you have set this script with the correct -subj content, such as country, state, city, organization name, common name and email before its first use."

echo "In other words, don't use this script blindly without changing the -subj content first. Press Ctrl C to cancel this operation if in need. You have 15 seconds."

sleep 15

# Create the CA directory
mkdir /usr/local/tls

# Generate the CA primary key
echo "Generating the CA primary key"
openssl genrsa 2048 > /usr/local/tls/ca-key.pem

# Generate the CA certificate from the primary key
echo "Producing the primary certificate with the CA's key."
openssl req -new -x509 -nodes -days 730 -key /usr/local/tls/ca-key.pem -out /usr/local/tls/ca-cert.pem -subj "/C=US/ST=State/L=City/O=Adminbyaccident Ltd/CN=example.com/emailAddress=youremail@anymail.com"

# Generate the server's key and certificate pair
echo "Generating serve's key and certificate pair."

# 1.- Generate a new key for the server plus a certificate request
openssl req -newkey rsa:2048 -days 730 -nodes -keyout /usr/local/tls/server-key.pem -out /usr/local/tls/server-req.pem -subj "/C=US/ST=State/L=City/O=Adminbyaccident Ltd/CN=example.com/emailAddress=youremail@anymail.com"

# 2.- Strip out the passphrase within the key
openssl rsa -in /usr/local/tls/server-key.pem -out /usr/local/tls/server-key.pem

# 3.- Generate the server's certificate via the x509 protocol from the cert request plus the server's key with a serial number.
openssl x509 -req -in /usr/local/tls/server-req.pem -days 730 -CA /usr/local/tls/ca-cert.pem -CAkey /usr/local/tls/ca-key.pem -set_serial 01 -out /usr/local/tls/server-cert.pem

echo "Server's certificate and key pair have been generated."

# Generate the client's certificate and key pairs
echo "Generating client's key and certificate pair."

# 1.- Generate a new key for the client plus a certificate request
openssl req -newkey rsa:2048 -days 730 -nodes -keyout /usr/local/tls/client-key.pem -out /usr/local/tls/client-req.pem -subj "/C=US/ST=State/L=City/O=Adminbyaccident Ltd/CN=example.com/emailAddress=youremail@anymail.com"

# 2.- Strip out the passphrase within the key
openssl rsa -in /usr/local/tls/client-key.pem -out /usr/local/tls/client-key.pem

# 3.- Generate the client's certificate via the x509 protocol from the cert request plus the client's key with a serial number.
openssl x509 -req -in /usr/local/tls/client-req.pem -days 730 -CA /usr/local/tls/ca-cert.pem -CAkey /usr/local/tls/ca-key.pem -set_serial 01 -out /usr/local/tls/client-cert.pem

echo "Client's certificate and key pair have been generated."

# Check the integrity of the final certificate's with the CA's primary certificate
echo "Verifying the final certificates for the client and server are intact derivatives from the CA's certificate"
openssl verify -CAfile /usr/local/tls/ca-cert.pem /usr/local/tls/server-cert.pem /usr/local/tls/client-cert.pem

echo "If the check response was a pair of OKs, you're done. If otherwise check what went wrong and start it all over again."

echo "To cancel the operation at this time press Ctrl C. Otherwise wait 15 seconds for the script to resume."

sleep 15

# Message for the user resuming the progress
echo "Nextcloud install starts now"

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

# Install PHP 8.1 and its 'funny' dependencies
pkg install -y php81 php81-mysqli php81-extensions

# Install the 'old fashioned' Expect to automate the mysql_secure_installation part
pkg install -y expect

# Set a ServerName directive in Apache HTTP. Place a name to your server.
sed -i -e 's/#ServerName www.example.com:80/ServerName California/g' /usr/local/etc/apache24/httpd.conf

# Configure Apache HTTP to use MPM Event instead of the Prefork default
# Disable the Prefork MPM
sed -i -e '/prefork/s/LoadModule/#LoadModule/' /usr/local/etc/apache24/httpd.conf

# Enable the Event MPM
sed -i -e '/event/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Enable the proxy module for PHP-FPM to use it
sed -i -e '/mod_proxy.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Enable the FastCGI module for PHP-FPM to use it
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
        SetHandler proxy:unix:/var/run/php-fpm.sock|fcgi://localhost/
    </FilesMatch>
</IfModule>" >> /usr/local/etc/apache24/modules.d/003_php-fpm.conf

# Set the PHP's default configuration
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

# Configure PHP-FPM to use a UNIX socket instead of a TCP one
# This configuration is better for standalone boxes
sed -i -e 's/127.0.0.1:9000/\/var\/run\/php-fpm.sock/g' /usr/local/etc/php-fpm.d/www.conf
sed -i -e 's/;listen.owner/listen.owner/g' /usr/local/etc/php-fpm.d/www.conf
sed -i -e 's/;listen.group/listen.group/g' /usr/local/etc/php-fpm.d/www.conf

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

# Enable TLS connections with a self signed certificate previosly generated. 

# Because we have generated a certificate + key we will enable SSL/TLS in the server.
# Enable TLS connections in the server.
sed -i -e '/mod_ssl.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Enable the server's default TLS configuration to be applied.
sed -i -e '/httpd-ssl.conf/s/#Include/Include/' /usr/local/etc/apache24/httpd.conf

# Enable TLS session cache.
sed -i -e '/mod_socache_shmcb.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Copy the certificate and key for Apache's use
cp /usr/local/tls/server-key.pem /usr/local/etc/apache24/server.key
cp /usr/local/tls/server-cert.pem /usr/local/etc/apache24/server.crt

# Enable the rewrite module
sed -i -e '/mod_rewrite.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Restart Apache HTTP to apply changes
service apache24 restart

# Configure PHP (already installed by the previous FAMP script) to use 512M instead of the default 128M
sed -i -e 's/memory_limit = 128M/memory_limit = 512M/g' /usr/local/etc/php.ini

# Install specific PHP dependencies for Nextcloud
pkg install -y php81-zip php81-mbstring php81-gd php81-zlib php81-curl php81-pdo_mysql php81-pecl-imagick php81-intl php81-bcmath php81-gmp php81-fileinfo

# Configure OPCache for PHP
sed -i -e '/opcache.enable/s/;opcache.enable=1/opcache.enable=1/' /usr/local/etc/php.ini

sed -i -e '/opcache.memory_consumption/s/;opcache.memory_consumption=128/opcache.memory_consumption=128/' /usr/local/etc/php.ini

sed -i -e '/opcache.interned_strings_buffer/s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=8/' /usr/local/etc/php.ini

sed -i -e '/opcache.max_accelerated_files/s/;opcache.max_accelerated_files=4000/opcache.max_accelerated_files=4000/' /usr/local/etc/php.ini

sed -i -e '/opcache.revalidate_freq/s/;opcache.revalidate_freq=60/opcache.revalidate_freq=60/' /usr/local/etc/php.ini

sed -i -e '/opcache.fast_shutdown/s/;opcache.fast_shutdown=1/opcache.fast_shutdown=1/' /usr/local/etc/php.ini

sed -i -e '/opcache.enable_cli/s/;opcache.enable_cli=1/opcache.enable_cli=1/' /usr/local/etc/php.ini

echo "Opcache has been configured"

# Restart the PHP-FPM service so it acknowledges the recently installed PHP packages
service php-fpm restart

# Install Nextcloud
# Fetch Nextcloud
fetch -o /usr/local/www https://download.nextcloud.com/server/releases/nextcloud-24.0.3.zip

# Unzip Nextcloud
unzip -d /usr/local/www/ /usr/local/www/nextcloud-24.0.3.zip

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
sed -i -e 's/#Include etc\/apache24\/extra\/httpd-vhosts.conf/Include etc\/apache24\/extra\/httpd-vhosts.conf/g' /usr/local/etc/apache24/httpd.conf

# Remove the old existing VirtualHost configuration (there's always a sample available)
rm /usr/local/etc/apache24/extra/httpd-vhosts.conf

# Create an empty VirtualHost configuration file

touch /usr/local/etc/apache24/extra/httpd-vhosts.conf

# Set a VirtualHost configuration for Nextcloud
# Mind there is no configuration for port 80.
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
    RewriteCond %{HTTPS} !=on
    RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
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
    Include /usr/local/etc/apache24/extra/nextcloud-security.conf
</VirtualHost>" >> /usr/local/etc/apache24/extra/httpd-vhosts.conf

# Create empty file to place the Security Rules later

touch /usr/local/etc/apache24/extra/nextcloud-security.conf

# Add Security Rules to protect Nextcloud

echo "
<IfModule mod_rewrite.c>
RewriteEngine on
# Condition to block suspicious request methods.
RewriteCond %{REQUEST_METHOD} ^(HEAD|TRACE|DELETE|TRACK|DEBUG) [NC,OR]
# Condition to block the specified user agents from programs and bots.
RewriteCond %{HTTP_USER_AGENT} (havij|libwww-perl|wget|python|nikto|curl|scan|java|winhttp|clshttp|loader|fetch) [NC,OR]
RewriteCond %{HTTP_USER_AGENT} (%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{HTTP_USER_AGENT} (;|<|>|'|\"|\)|\(|%0A|%0D|%22|%27|%28|%3C|%3E|%00).*(libwww-perl|wget|python|nikto|curl|scan|java|winhttp|HTTrack|clshttp|archiver|loader|email|harvest|extract|grab|miner) [NC,OR]
# Condition to block suspicious header requests.
RewriteCond %{HTTP_ACCEPT} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_COOKIE} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_FORWARDED} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_HOST} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_PROXY_CONNECTION} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_REFERER} (localhost|loopback|127\.0\.0\.1) [NC,OR]
# Condition to block Proxy/LoadBalancer/WAF bypass
RewriteCond %{HTTP:X-Client-IP} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-For} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-Scheme} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Real-IP} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-By} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Originating-IP} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-From} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-Host} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Remote-Addr} (localhost|loopback|127\.0\.0\.1) [NC,OR]
# Condition to block requests that incorporate the specified expressions in them. Avoid injection.
RewriteCond %{THE_REQUEST} (\?|\*|%2a)+(%20+|\\s+|%20+\\s+|\\s+%20+|\\s+%20+\\s+)(http|https)(:/|/) [NC,OR]
# Condition to block any request containing the etc/passwd string and avoid system passwords exfiltration.
RewriteCond %{THE_REQUEST} etc/passwd [NC,OR]
# Condition to block the execution of CGI programs.
RewriteCond %{THE_REQUEST} cgi-bin [NC,OR]
# Condition to block requests that jump into the next line. Avoid injection.
RewriteCond %{THE_REQUEST} (%0A|%0D|\\r|\\n) [NC,OR]
# Condition to block any Sharepoint services call.
RewriteCond %{REQUEST_URI} owssvr\.dll [NC,OR]
# Condition to block requests that simulate to come from the specified expressions. Avoid injection.
RewriteCond %{HTTP_REFERER} (%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{HTTP_REFERER} \.opendirviewer\. [NC,OR]
RewriteCond %{HTTP_REFERER} users\.skynet\.be.* [NC,OR]
# Condition to block requests that incorporate the specified expressions in them.
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(http|https):// [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(\.\.//?)+ [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=/([a-z0-9_.]//?)+ [NC,OR]
# Condition to block any PHP execution. Avoid injection.
RewriteCond %{QUERY_STRING} \=PHP[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} [NC,OR]
RewriteCond %{QUERY_STRING} (\.\./|%2e%2e%2f|%2e%2e/|\.\.%2f|%2e\.%2f|%2e\./|\.%2e%2f|\.%2e/) [NC,OR]
# Condition to block FTP usage. Avoid uploads.
RewriteCond %{QUERY_STRING} ftp\: [NC,OR]
# Condition to block any requests jumping over paths or injecting/retrieving objects.
RewriteCond %{QUERY_STRING} (http|https)\: [NC,OR]
RewriteCond %{QUERY_STRING} \=\|w\| [NC,OR]
RewriteCond %{QUERY_STRING} ^(.*)/self/(.*)$ [NC,OR]
RewriteCond %{QUERY_STRING} ^(.*)cPath=(http|https)://(.*)$ [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*script.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^s]*s)+cript.*(>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*embed.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^e]*e)+mbed.*(>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*object.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^o]*o)+bject.*(>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*iframe.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^i]*i)+frame.*(>|%3E) [NC,OR]
# Condition to block with the intention to en/de-code strings in base64
RewriteCond %{QUERY_STRING} base64_encode.*\(.*\) [NC,OR]
RewriteCond %{QUERY_STRING} base64_(en|de)code[^(]*\([^)]*\) [NC,OR]
# Condition to block
RewriteCond %{QUERY_STRING} GLOBALS(=|\[|\%[0-9A-Z]{0,2}) [OR]
RewriteCond %{QUERY_STRING} _REQUEST(=|\[|\%[0-9A-Z]{0,2}) [OR]
# Condition to block requests that incorporate the specified expressions in them. Avoid injection.
RewriteCond %{QUERY_STRING} ^.*(\(|\)|<|>|%3c|%3e).* [NC,OR]
RewriteCond %{QUERY_STRING} ^.*(\x00|\x04|\x08|\x0d|\x1b|\x20|\x3c|\x3e|\x7f).* [NC,OR]
# Condition to block requests which declare the specified values in the string query. Avoid injection.
RewriteCond %{QUERY_STRING} (NULL|OUTFILE|LOAD_FILE) [OR]
# Condition to block requests intending to retrieve or inject content in the motd file or /etc and /bin directories.
RewriteCond %{QUERY_STRING} (\.{1,}/)+(motd|etc|bin) [NC,OR]
# Condition to block any string referencing to the host or loopback interface.
RewriteCond %{QUERY_STRING} (localhost|loopback|127\.0\.0\.1) [NC,OR]
# Condition to block requests that incorporate the specified expressions in them. Avoid injection.
RewriteCond %{QUERY_STRING} (<|>|'|%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
# Condition to block SQL injection attacks 
RewriteCond %{QUERY_STRING} concat[^\(]*\( [NC,OR]
RewriteCond %{QUERY_STRING} union([^s]*s)+elect [NC,OR]
RewriteCond %{QUERY_STRING} union([^a]*a)+ll([^s]*s)+elect [NC,OR]
RewriteCond %{QUERY_STRING} \-[sdcr].*(allow_url_include|allow_url_fopen|safe_mode|disable_functions|auto_prepend_file) [NC,OR]
RewriteCond %{QUERY_STRING} (;|<|>|'|\"|\)|%0A|%0D|%22|%27|%3C|%3E|%00).*(/\*|union|select|insert|drop|delete|update|cast|create|char|convert|alter|declare|order|script|set|md5|benchmark|encode) [NC,OR]
RewriteCond %{QUERY_STRING} (sp_executesql) [NC]
# The rewrite rule itself. Any match gets blocked.
RewriteRule ^(.*)$ - [F]
</IfModule>
" >> /usr/local/etc/apache24/extra/nextcloud-security.conf

# Restart Apache service
service apache24 restart

# Create the database for Nextcloud and user. Mind this is MySQL version 8
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

# Now Visit your server ip and finish the GUI install. 
# Be aware of the default SQLite DB install. Select the MySQL option!!
# https://yourserverip/nextcloud

# Automatic NextCloud install using MySQL instead of the default SQLite

NEXTCLOUD_USER=$(pwgen 10 --secure --numerals --capitalize) && export NEXTCLOUD_USER && echo $NEXTCLOUD_USER >> /root/nextcloud_user.txt

NEXTCLOUD_PWD=$(pwgen 32 --secure --numerals --capitalize) && export NEXTCLOUD_PWD && echo $NEXTCLOUD_PWD >> /root/nextcloud_pwd.txt

su -m www -c 'php /usr/local/www/nextcloud/occ maintenance:install --database "mysql" --database-name "$NEW_DB_NAME" --database-user "$NEW_DB_USER_NAME" --database-pass "$NEW_DB_PASSWORD" --admin-user "$NEXTCLOUD_USER" --admin-pass "$NEXTCLOUD_PWD"'

# Add your ip or domain name as a trusted domain for Nextcloud. Remember to adapt this to your needs. Otherwise a warning message will appear in your screen.
# This setup doesn't use a domain name, it's ready to be used with an IP. Adjust the NIC name with 'em0' or similar here if it's convenient.

TRUSTED_DOMAIN=$(ifconfig | grep "inet " | awk '{ print $2; exit }') && export TRUSTED_DOMAIN && echo $TRUSTED_DOMAIN >> /root/trusted_domain.txt

su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set trusted_domains 1 --value="$TRUSTED_DOMAIN"'

# No one but root can read these files. Read only permissions.
chmod 400 /root/db_root_pwd.txt
chmod 400 /root/new_db_name.txt
chmod 400 /root/new_db_user_name.txt
chmod 400 /root/newdb_pwd.txt
chmod 400 /root/nextcloud_user.txt
chmod 400 /root/nextcloud_pwd.txt
chmod 400 /root/trusted_domain.txt

# Display the new database, username and password generated on MySQL
echo "Display DB name, username and password location"
echo "Your DB_ROOT_PASSWORD is written on this file /root/db_root_pwd.txt"
echo "Your NEW_DB_NAME is written on this file /root/new_db_name.txt"
echo "Your NEW_DB_USER_NAME is written on this file /root/new_db_user_name.txt"
echo "Your NEW_DB_PASSWORD is written on this file /root/newdb_pwd.txt"

# Display the automatically generated username and password for Nextcloud
echo "Your Nextcloud username is written on this file /root/nextcloud_user.txt"
echo "Your Nextcloud password is written on this file /root/nextcloud_pwd.txt"

# Browser usage message
echo "If visiting your new Nextcloud server with your browser you see a certificate error please try with another browser and see if it works there."

## References:
## https://docs.nextcloud.com/server/stable/admin_manual/installation/source_installation.html
## https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-nextcloud-on-freebsd-12/
