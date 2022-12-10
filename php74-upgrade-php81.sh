#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: php74-upgrade-php81.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 30-07-2022
# SET FOR: Test
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script upgrades PHP 7.4 install to PHP 8.1 on a FAMP stack configured for the use of PHP-FPM.
#
# REV LIST:
# DATE: 30-07-2022
# BY: ALBERT VALBUENA
# MODIFICATION: 30-07-2022
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

# Install PHP 8.1. This will automatically remove any PHP 7.4 packages.

pkg install -y php81\
				php81-bcmath\
				php81-brotli\
				php81-bz2\
				php81-ctype\
				php81-curl\
				php81-dom\
				php81-exif\
				php81-extensions\
				php81-fileinfo\
				php81-filter\
				php81-gd\
				php81-iconv\
				php81-intl\
				php81-mbstring\
				php81-mysqli\
				php81-opcache\
				php81-pdo\
				php81-pdo_mysql\
				php81-pdo_sqlite\
				php81-pecl-imagick\
				php81-pecl-mcrypt\
				php81-pecl-memcache\
				php81-pecl-memcached\
				php81-pecl-redis\
				php81-phar\
				php81-posix\
				php81-readline\
				php81-session\
				php81-simplexml\
				php81-soap\
				php81-sockets\
				php81-sqlite3\
				php81-tidy\
				php81-tokenizer\
				php81-xml\
				php81-xmlreader\
				php81-xmlwriter\
				php81-zip\
				php81-zlib

# Restart PHP-FPM service for these changes to be applied
service php-fpm restart

# Check PHP-FPM service status
service php-fpm status

echo "PHP has been upgraded to version 8.1. Check for any errors on your screen after the service status check."
