#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Change the default pkg repository from quarterly to latest
sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages (it will first download the pkg repo from latest)
# secondly it will upgrade any installed packages.
pkg upgrade -y

# Install PHP 8.0
pkg install -y php80 php80-extensions

# Configure PHP to production settings
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

# Install GNUsed in order to more easily edit files
pkg install -y gsed

# Configure PHP not to run arbitrary code by mistake
gsed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/etc/php.ini

# Configure PHP-FPM to use a UNIX socket instead of a TCP one
# This configuration is better for standalone boxes
gsed -i 's/127.0.0.1:9000/\/tmp\/php-fpm.sock/g' /usr/local/etc/php-fpm.d/www.conf
gsed -i 's/;listen.owner/listen.owner/g' /usr/local/etc/php-fpm.d/www.conf
gsed -i 's/;listen.group/listen.group/g' /usr/local/etc/php-fpm.d/www.conf

# Enable PHP-FPM to start at boot time
sysrc php_fpm_enable="YES"

# Start up PHP-FPM at the end of its install
service php-fpm start

echo "
PHP 8.0 has been installed
"

## EOF
