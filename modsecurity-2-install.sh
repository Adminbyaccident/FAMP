#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: modsecurity-2-install.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 30-01-2023
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs Mod_Security 2 on a FAMP stack on FreeBSD 12/13
#
# REV LIST:
# DATE: 
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

# Change the default pkg repository from quarterly to latest
# Install ModSecurity
pkg install -y ap24-mod_security

# Install CRS ruleset for ModSecurity
pkg install wget 
wget -O /usr/local/etc/modsecurity/crs-ruleset-3.3.4.zip https://github.com/coreruleset/coreruleset/archive/refs/tags/v3.3.4.zip
pkg install -y unzip
unzip /usr/local/etc/modsecurity/crs-ruleset-3.3.4.zip -d /usr/local/etc/modsecurity/
cp /usr/local/etc/modsecurity/coreruleset-3.3.4/crs-setup.conf.example /usr/local/etc/modsecurity/coreruleset-3.3.4/crs-setup.conf
cp /usr/local/etc/modsecurity/coreruleset-3.3.4/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /usr/local/etc/modsecurity/coreruleset-3.3.4/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
cp /usr/local/etc/modsecurity/coreruleset-3.3.4/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example /usr/local/etc/modsecurity/coreruleset-3.3.4/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
echo '
LoadModule security2_module libexec/apache24/mod_security2.so
Include /usr/local/etc/modsecurity/*.conf
Include /usr/local/etc/modsecurity/coreruleset-3.3.4/crs-setup.conf
Include /usr/local/etc/modsecurity/coreruleset-3.3.4/rules/*.conf
' >> /usr/local/etc/apache24/modules.d/280_mod_security.conf
sed -i -e '/mod_unique_id.so/s/#LoadModule/LoadModule/g' /usr/local/etc/apache24/httpd.conf
sed -i -e 'SecRuleEngine DetectionOnly/s/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /usr/local/etc/modsecurity/modsecurity.conf
echo "
Include /usr/local/etc/apache24/modules.d/280_mod_security.conf
" >> /usr/local/etc/apache24/httpd.conf
service apache24 restart
echo 'ModSecurity version 2 has been installed on the system'
