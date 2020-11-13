#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Change the default pkg repository from quarterly to latest
sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages (it will first download the pkg repo from latest)
# secondly it will upgrade any installed packages.
pkg upgrade -y

# Install Modsecurity 3 for Apache HTTP
pkg install -y modsecurity3-apache

# Download Git SpiderLab Rules >> OWASP ModSecurity Core Rule Set
pkg install -y git
git clone https://github.com/coreruleset/coreruleset /usr/local/etc/modsecurity/coreruleset/
cp /usr/local/etc/modsecurity/coreruleset/crs-setup.conf.example /usr/local/etc/modsecurity/coreruleset/crs-setup.conf
sed -ip 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /usr/local/etc/modsecurity/modsecurity.conf

# Set the configuration files for ModSecurity 3 to work
touch /usr/local/etc/apache24/modsecurity-rules.conf

echo "
Include /usr/local/etc/modsecurity/modsecurity.conf
Include /usr/local/etc/modsecurity/coreruleset/crs-setup.conf
Include /usr/local/etc/modsecurity/coreruleset/rules/*.conf
" >> /usr/local/etc/apache24/modsecurity-rules.conf

# Enable ModSecurity's 3 module
echo "
modsecurity on
modsecurity_rules_file /usr/local/etc/apache24/modsecurity-rules.conf
" >> /usr/local/etc/apache24/httpd.conf

# Rename 2 config files
mv /usr/local/etc/modsecurity/coreruleset/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /usr/local/etc/modsecurity/coreruleset/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf

mv /usr/local/etc/modsecurity/coreruleset/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example /usr/local/etc/modsecurity/coreruleset/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

# Restart Apache HTTP
apachectl restart

## References:
## https://github.com/SpiderLabs/owasp-modsecurity-crs
## https://raw.githubusercontent.com/coreruleset/coreruleset/v3.2/dev/INSTALL
