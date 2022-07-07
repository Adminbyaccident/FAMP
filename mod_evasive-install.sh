#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: mod_evasive-install.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 30-05-2021
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs mode_evasive in Apache HTTP on FreeBSD using IPFW
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

# Change the default pkg repository from quarterly to latest
sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages (it will first download the pkg repo from latest)
# secondly it will upgrade any installed packages.
pkg upgrade -y

# Install mod_evasive
pkg install -y ap24-mod_evasive

# Enable the mod_evasive module in Apache HTTP
sed -i -e '/mod_evasive20.so/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Configure the mod_evasive module
touch /usr/local/etc/apache24/modules.d/020-mod_evasive.conf

echo "<IfModule mod_evasive20.c>
	DOSHashTableSize 3097
	DOSPageCount 20
	DOSSiteCount 50
	DOSPageInterval 1
	DOSSiteInterval 1
	DOSBlockingPeriod 360
	DOSEmailNotify youremail@address.com
	DOSLogDir "/var/log/mod_evasive"
</IfModule>" >> /usr/local/etc/apache24/modules.d/020-mod_evasive.conf

# Restart Apache for the configuration to take effect
apachectl graceful

## References:
## https://www.adminbyaccident.com/freebsd/how-to-mitigate-dos-attacks-with-mod_evasive-on-freebsd/
