#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: apache-geoip-block.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 28-12-2021
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs and configures Apache HTTP to block connections from a specific country/countries on a FreeBSD system. 
# 		     Notice all countries are allowed but the specified ones aren't!
#
# IMPORTANT: Create an account for MaxMind geolocation databases in order to use this script.
# The URL to create the account is: https://dev.maxmind.com/geoip/geolite2-free-geolocation-data?lang=en
# Remember to fill the values for the variables below with the ones of your MaxMind account ID and key.
#
# REV LIST:
# DATE: 28-12-2021
# BY: ALBERT VALBUENA
# MODIFICATION: 28-12-2021
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!


# Declare variables:
# MaxMind variables
AccountID='write_your_maxmind_account_id_here'
LicenseKey='write_your_maxmind_key_here'

# Countries to block. 
# Full country codes list: https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes
# Example: China='SetEnvIf MM_COUNTRY_CODE ^(CN) BlockCountry'
# Country_1='SetEnvIf MM_COUNTRY_CODE ^(CN) BlockCountry'
# Country_2='SetEnvIf MM_COUNTRY_CODE ^(XX) BlockCountry'
# Add as many countries as needed here and in the 200_mod_maxmindb.conf file directives.

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################


# Uncomment if the latest packages are needed instead of the quarterly released ones.
# sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages
pkg upgrade -y

# Install the geoip database
pkg install -y geoipupdate

sed -i -e "s/YOUR_ACCOUNT_ID_HERE/$AccountID/" /usr/local/etc/GeoIP.conf
sed -i -e "s/YOUR_LICENSE_KEY_HERE/$LicenseKey/" /usr/local/etc/GeoIP.conf

# Populate the databases
/usr/local/bin/geoipupdate

# Wait 20 seconds for the geoipupdate to finish
sleep 20

# Install the Apache HTTP module for MaxMind databases
pkg install -y ap24-mod_maxminddb

# Create the configuration file for the module
touch /usr/local/etc/apache24/modules.d/200_mod_maxmindb.conf

# Configure Apache HTTP to use the MaxMindDB module
echo "
LoadModule maxminddb_module /usr/local/libexec/apache24/mod_maxminddb.so

<IfModule mod_maxminddb.c>
        MaxMindDBEnable On
        MaxMindDBFile COUNTRY_DB /usr/local/share/GeoIP/GeoLite2-Country.mmdb
        MaxMindDBEnv MM_COUNTRY_CODE COUNTRY_DB/country/iso_code
        <Location />
                $Country_1
				$Country_2
                Deny from env=BlockCountry
        </Location>
</IfModule>
" >> /usr/local/etc/apache24/modules.d/200_mod_maxmindb.conf

# Restart Apache HTTP so the new module is loaded.
service apache24 restart

# Install a cron job so the geolocation database from MaxMind is regularly updated.
crontab -l > /root/cronjob.txt
echo '
# Uncomment the SHELL and PATH variables if there's no cron job already in place. 
# Use crontab -l to check if there's any cron job.
# SHELL=/bin/sh
# PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin
# Order of crontab fields
# minute    hour    mday    month   wday    command
  1         0       *      *        1,3     /usr/local/bin/geoipupdate
' >> /root/cronjob.txt
crontab /root/cronjob.txt
rm /root/cronjob.txt

echo "
Geolocation block has been installed and configured for $Country_1 , $Country_2"

# EOF
