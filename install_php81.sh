#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: install_php80.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 14-11-2020
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs PHP 8
#
# REV LIST:
# DATE: 01-08-2022
# BY: ALBERT VALBUENA
# MODIFICATION: 01-08-2022
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

# Install PHP 8.1
pkg install -y php81 php81-extensions

# Configure PHP to production settings
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

# Configure PHP not to run arbitrary code by mistake
sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/etc/php.ini

# Configure PHP-FPM to use a UNIX socket instead of a TCP one
# This configuration is better for standalone boxes
sed -i -e 's/127.0.0.1:9000/\/tmp\/php-fpm.sock/g' /usr/local/etc/php-fpm.d/www.conf
sed -i -e 's/;listen.owner/listen.owner/g' /usr/local/etc/php-fpm.d/www.conf
sed -i -e 's/;listen.group/listen.group/g' /usr/local/etc/php-fpm.d/www.conf

# Enable PHP-FPM to start at boot time
sysrc php_fpm_enable="YES"

# Start up PHP-FPM at the end of its install
service php-fpm start

echo "
PHP 8.1 has been installed
"

## EOF
