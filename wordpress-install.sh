#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Install Wordpress on FreeBSD after having used the following scripts:
# event-php-fpm.sh
# apache-hardening.sh

# Create the database and user. Mind this is MySQL version 8

NEW_DB_NAME=$(pwgen 8 --secure --numerals --capitalize) && export NEW_DB_NAME && echo $NEW_DB_NAME >> /root/new_db_name.txt

NEW_DB_USER_NAME=$(pwgen 10 --secure --numerals --capitalize) && export NEW_DB_USER_NAME && echo $NEW_DB_USER_NAME >> /root/new_db_user_name.txt

NEW_DB_PASSWORD=$(pwgen 32 --secure --numerals --capitalize) && export NEW_DB_PASSWORD && echo $NEW_DB_PASSWORD >> /root/newdb_pwd.txt

DB_ROOT_PASSWORD=$(cat /root/db_root_pwd.txt) && export DB_ROOT_PASSWORD

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

# Install PHP packages for Wordpress
pkg install -y	php74\
		php74-bcmath\
		php74-bz2\
		php74-ctype\
		php74-curl\
		php74-dom\
		php74-exif\
		php74-extensions\
		php74-fileinfo\
		php74-filter\
		php74-ftp\
		php74-gd\
		php74-iconv\
		php74-intl\
		php74-json\
		php74-mbstring\
		php74-mysqli\
		php74-opcache\
		php74-openssl\
		php74-pdo\
		php74-pdo_mysql\
		php74-pdo_sqlite\
		php74-pecl-mcrypt\
		php74-phar\
		php74-posix\
		php74-session\
		php74-simplexml\
		php74-soap\
		php74-sockets\
		php74-sqlite3\
		php74-tokenizer\
		php74-xml\
		php74-xmlreader\
		php74-xmlrpc\
		php74-xmlwriter\
		php74-zip\
		php74-zlib

# Load the new PHP modules
service php-fpm restart

# Reload PHP-FPM so it acknowledges the recently installed PHP packages
service php-fpm reload

# Because Wordpress and plugins will make use of an .htaccess file, let's enable it.
sed -i -e "278s/AllowOverride None/AllowOverride All/" /usr/local/etc/apache24/httpd.conf

# Enable the rewrite module in Apache.
sed -i -e '/mod_rewrite.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Restart Apache HTTP so changes take effect
service apache24 restart

# Fetch Wordpress from the official site
fetch https://wordpress.org/latest.tar.gz

# Unpack Wordpress
tar -zxvf latest.tar.gz

# Create the main config file from the sample
cp /root/wordpress/wp-config-sample.php /root/wordpress/wp-config.php

# Add the database name into the wp-config.php file
sed -i -e 's/database_name_here/$NEW_DB_NAME/' /root/wordpress/wp-config.php

# Add the username into the wp-config.php file
sed -i -e 's/username_here/$NEW_DB_USER_NAME/' /root/wordpress/wp-config.php

# Add the db password into the wp-config.php file
sed -i -e 's/password_here/$NEW_DB_PASSWORD/' /root/wordpress/wp-config.php

# Move the content of the wordpress file into the DocumentRoot path
cp -r /root/wordpress/* /usr/local/www/apache24/data

# Change the ownership of the DocumentRoot path content from root to the Apache HTTP user (named www)
chown -R www:www /usr/local/www/apache24/data

# No one but root can read these files. Read only permissions.
chmod 400 /root/db_root_pwd.txt
chmod 400 /root/new_db_name.txt
chmod 400 /root/new_db_user_name.txt
chmod 400 /root/newdb_pwd.txt

# Display the new database, username and password generated on MySQL to accomodate WordPress
echo "Your NEW_DB_NAME is written on this file /root/new_db_name.txt"
echo "Your NEW_DB_USER_NAME is written on this file /root/new_db_user_name.txt"
echo "Your NEW_DB_PASSWORD is written on this file /root/newdb_pwd.txt"

# Actions on the CLI are now finished.
echo 'Actions on the CLI are now finished. Please visit the ip/domain of the site with a browser and proceed with the install'
