#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: opcache.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 12-09-2020
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs enables OPCache on a PHP server.
#
# REV LIST:
# DATE: 12-12-2021
# BY: ALBERT VALBUENA
# MODIFICATION: 12-12-2021
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

sed -i -e '/opcache.enable/s/;opcache.enable=1/opcache.enable=1/' /usr/local/etc/php.ini

sed -i -e '/opcache.memory_consumption/s/;opcache.memory_consumption=128/opcache.memory_consumption=128/' /usr/local/etc/php.ini

sed -i -e '/opcache.interned_strings_buffer/s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=8/' /usr/local/etc/php.ini

sed -i -e '/opcache.max_accelerated_files/s/;opcache.max_accelerated_files=4000/opcache.max_accelerated_files=4000/' /usr/local/etc/php.ini

sed -i -e '/opcache.revalidate_freq/s/;opcache.revalidate_freq=60/opcache.revalidate_freq=60/' /usr/local/etc/php.ini

sed -i -e '/opcache.fast_shutdown/s/;opcache.fast_shutdown=1/opcache.fast_shutdown=1/' /usr/local/etc/php.ini

sed -i -e '/opcache.enable_cli/s/;opcache.enable_cli=1/opcache.enable_cli=1/' /usr/local/etc/php.ini

service php-fpm restart

echo "Opcache has been configured"

# EOF
# References: 
# https://www.php.net/manual/en/opcache.installation.php
# https://www.php.net/manual/en/opcache.configuration.php
