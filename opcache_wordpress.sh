#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: opcache_wordpress.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 26-10-2024
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 13/14
#
# PURPOSE: This script installs enables OPCache configured for WordPress in a PHP enabled server.
#
# REV LIST:
# DATE: 26-10-2024
# BY: ALBERT VALBUENA
# MODIFICATION: 
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

sed -i -e '/opcache.enable/s/;opcache.enable=1/opcache.enable=1/' /usr/local/etc/php.ini

sed -i -e '/opcache.enable_cli/s/;opcache.enable_cli=1/opcache.enable_cli=1/' /usr/local/etc/php.ini

sed -i -e '/opcache.memory_consumption/s/;opcache.memory_consumption=128/opcache.memory_consumption=256/' /usr/local/etc/php.ini

sed -i -e '/opcache.interned_strings_buffer/s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=8/' /usr/local/etc/php.ini

sed -i -e '/opcache.max_accelerated_files/s/;opcache.max_accelerated_files=4000/opcache.max_accelerated_files=10000/' /usr/local/etc/php.ini

sed -i -e '/opcache.use_cwd/s/;opcache.use_cwd=1/opcache.use_cwd=1/' /usr/local/etc/php.ini

sed -i -e '/opcache.validate_timepstatmps/s/;opcache.validate_timepstatmps=1/opcache.validate_timepstatmps=1/' /usr/local/etc/php.ini

sed -i -e '/opcache.revalidate_freq/s/;opcache.revalidate_freq=60/opcache.revalidate_freq=60/' /usr/local/etc/php.ini

sed -i -e '/opcache.revalidate_path/s/;opcache.revalidate_path=0/opcache.revalidate_path=0/' /usr/local/etc/php.ini

sed -i -e '/opcache.save_comments/s/;opcache.save_comments=0/opcache.save_comments=0/' /usr/local/etc/php.ini

sed -i -e '/opcache.fast_shutdown/s/;opcache.fast_shutdown=1/opcache.fast_shutdown=1/' /usr/local/etc/php.ini

sed -i -e '/opcache.enable_file_override/s/;opcache.enable_file_override=1/opcache.enable_file_override=1/' /usr/local/etc/php.ini

sed -i -e '/opcache.max_file_size/s/;opcache.max_file_size=0/opcache.max_file_size=0/' /usr/local/etc/php.ini

sed -i -e '/opcache.consistency_checks/s/;opcache.consistency_checks=0/opcache.consistency_checks=0/' /usr/local/etc/php.ini

sed -i -e '/opcache.protect_memory/s/;opcache.protect_memory=0/opcache.protect_memory=0/' /usr/local/etc/php.ini

sed -i -e '/opcache.huge_code_pages/s/;opcache.huge_code_pages=0/opcache.huge_code_pages=0/' /usr/local/etc/php.ini



service php_fpm restart

echo "Opcache has been configured for WordPress"

# EOF
# References: 
# https://www.php.net/manual/en/opcache.installation.php
# https://www.php.net/manual/en/opcache.configuration.php