#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: wordpress-install-mariadb.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 01-08-2022
# SET FOR: Test
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs WordPress and assumes an existing FAMP stack (MariaDB version).
#
# REV LIST:
# DATE: 30-01-2023
# BY: ALBERT VALBUENA
# MODIFICATION: 30-01-2023
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Install Wordpress on FreeBSD after having used the following scripts:
# event-php-fpm.sh
# apache-hardening.sh

# Create the database and user. Mind this is MariaDB
pkg install -y pwgen

touch /root/new_db_name.txt
touch /root/new_db_user_name.txt
touch /root/newdb_pwd.txt

echo "Generating new database, username and passoword for the WordPress install"

NEW_DB_NAME=$(pwgen 8 --secure --numerals --capitalize) && export NEW_DB_NAME && echo $NEW_DB_NAME >> /root/new_db_name.txt

NEW_DB_USER_NAME=$(pwgen 10 --secure --numerals --capitalize) && export NEW_DB_USER_NAME && echo $NEW_DB_USER_NAME >> /root/new_db_user_name.txt

NEW_DB_PASSWORD=$(pwgen 32 --secure --numerals --capitalize) && export NEW_DB_PASSWORD && echo $NEW_DB_PASSWORD >> /root/newdb_pwd.txt

NEW_DATABASE=$(expect -c "
set timeout 10
spawn mysql -u root -p
expect \"Enter password:\"
send \"\r\"
expect \"root@localhost \[(none)\]>\"
send \"CREATE DATABASE $NEW_DB_NAME;\r\"
expect \"root@localhost \[(none)\]>\"
send \"CREATE USER '$NEW_DB_USER_NAME'@'localhost' IDENTIFIED BY '$NEW_DB_PASSWORD';\r\"
expect \"root@localhost \[(none)\]>\"
send \"GRANT ALL PRIVILEGES ON $NEW_DB_NAME.* TO '$NEW_DB_USER_NAME'@'localhost';\r\"
expect \"root@localhost \[(none)\]>\"
send \"FLUSH PRIVILEGES;\r\"
expect \"root@localhost \[(none)\]>\"
send \"exit\r\"
expect eof
")

echo "$NEW_DATABASE"

# Install PHP packages for Wordpress
pkg install -y	php82\
		php82-bcmath\
		php82-bz2\
		php82-ctype\
		php82-curl\
		php82-dom\
		php82-exif\
		php82-extensions\
		php82-fileinfo\
		php82-filter\
		php82-ftp\
		php82-gd\
		php82-iconv\
		php82-intl\
		php82-mbstring\
		php82-mysqli\
		php82-opcache\
		php82-pdo\
		php82-pdo_mysql\
		php82-pdo_sqlite\
		php82-pecl-mcrypt\
		php82-phar\
		php82-posix\
		php82-session\
		php82-simplexml\
		php82-soap\
		php82-sockets\
		php82-sqlite3\
		php82-tokenizer\
		php82-xml\
		php82-xmlreader\
		php82-xmlwriter\
		php82-zip\
		php82-zlib

# Load the new PHP modules
service php-fpm restart

#Final PHP installation announcement
echo "PHP 8.2 is now installed. Moving on."

# Because Wordpress and plugins will make use of an .htaccess file, let's enable it.
sed -i -e "279s/AllowOverride None/AllowOverride All/" /usr/local/etc/apache24/httpd.conf

# Enable the rewrite module in Apache.
sed -i -e '/mod_rewrite.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Restart Apache HTTP so changes take effect
service apache24 restart

# Downloading and configuring WordPress announcement
echo "WordPress is now being downloaded and pre-configured."

# Fetch Wordpress from the official site
fetch -o /root https://wordpress.org/latest.tar.gz

# Unpack Wordpress
tar -zxf /root/latest.tar.gz -C /root

# Create the main config file from the sample
cp /root/wordpress/wp-config-sample.php /root/wordpress/wp-config.php

# Add the database name into the wp-config.php file
NEW_DB=$(cat /root/new_db_name.txt) && export NEW_DB
sed -i -e 's/database_name_here/'"$NEW_DB"'/g' /root/wordpress/wp-config.php

# Add the username into the wp-config.php file
USER_NAME=$(cat /root/new_db_user_name.txt) && export USER_NAME
sed -i -e 's/username_here/'"$USER_NAME"'/g' /root/wordpress/wp-config.php

# Add the db password into the wp-config.php file
PASSWORD=$(cat /root/newdb_pwd.txt) && export PASSWORD
sed -i -e 's/password_here/'"$PASSWORD"'/g' /root/wordpress/wp-config.php

## Add the socket where MariaDB is running
sed -i -e 's/localhost/localhost:\/var\/run\/mysql\/mysql.sock/g' /root/wordpress/wp-config.php

# Move the content of the wordpress file into the DocumentRoot path
cp -r /root/wordpress/* /usr/local/www/apache24/data

# Change the ownership of the DocumentRoot path content from root to the Apache HTTP user (named www)
chown -R www:www /usr/local/www/apache24/data

# No one but root can read these files. Read only permissions.
chmod 400 /root/new_db_name.txt
chmod 400 /root/new_db_user_name.txt
chmod 400 /root/newdb_pwd.txt

# Display the new database, username and password generated on MySQL to accomodate WordPress
echo "Your NEW_DB_NAME is written on this file /root/new_db_name.txt"
echo "Your NEW_DB_USER_NAME is written on this file /root/new_db_user_name.txt"
echo "Your NEW_DB_PASSWORD is written on this file /root/newdb_pwd.txt"

# Actions on the CLI are now finished.
echo 'Actions on the CLI are now finished. Please visit the ip/domain of the site with a browser and proceed with the install'
