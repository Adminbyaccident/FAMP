#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: modsecurity-2.9-wordpress.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 24-04-2023
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script installs ModSecurity 2.9 configured for WordPress on a FAMP stack
#
# REV LIST:
# DATE: 24-04-2023
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
sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages (it will first download the pkg repo from latest)
# secondly it will upgrade any installed packages.
pkg upgrade -y

# Install Modsecurity 3 for Apache HTTP
pkg install -y ap24-mod_security

# Download Git SpiderLab Rules >> OWASP ModSecurity Core Rule Set
pkg install -y git
git clone https://github.com/coreruleset/coreruleset /usr/local/etc/modsecurity/coreruleset/
cp /usr/local/etc/modsecurity/coreruleset/crs-setup.conf.example /usr/local/etc/modsecurity/coreruleset/crs-setup.conf
sed -i -e 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /usr/local/etc/modsecurity/modsecurity.conf

# Set the configuration files for ModSecurity 2 to work
sed -i -e 's/#LoadModule/LoadModule/g' /usr/local/etc/apache24/modules.d/280_mod_security.conf
sed -i -e 's/#Include/Include/g' /usr/local/etc/apache24/modules.d/280_mod_security.conf

# Rename 2 config files
mv /usr/local/etc/modsecurity/coreruleset/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /usr/local/etc/modsecurity/coreruleset/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf

mv /usr/local/etc/modsecurity/coreruleset/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example /usr/local/etc/modsecurity/coreruleset/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

# Add the exclusion file for Wordpress
echo "
SecAction \\
 \"id:900130,\\
  phase:1,\\
  nolog,\\
  pass,\\
  t:none,\\
  setvar:tx.crs_exclusions_wordpress=1\"
" >> /usr/local/etc/modsecurity/coreruleset/crs-setup.conf

# Exclude your domain from the rules (ADJUST THIS FOR YOUR DOMAIN!)
echo "
SecRule REQUEST_HEADERS:Host \"@streq blog.yourdomain.com\" \"id:1000,phase:1,setvar:tx.crs_exclusions_wordpress=1\"
" >> /usr/local/etc/modsecurity/coreruleset/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf

# Restart Apache HTTP
apachectl restart

## References:
## https://github.com/SpiderLabs/owasp-modsecurity-crs
## https://raw.githubusercontent.com/coreruleset/coreruleset/v3.4/dev/INSTALL
