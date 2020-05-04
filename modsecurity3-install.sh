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

# Clonde with Git SpiderLab Rules >> OWASP ModSecurity Core Rule Set
pkg install -y git
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs
cp /usr/local/etc/modsecurity/owasp-modsecurity-crs/crs-setup.conf.example /usr/local/etc/modsecurity/crs-setup.conf
sed -ip 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /usr/local/etc/modsecurity/modsecurity.conf

# Configure ModSecurity3's module
touch /usr/local/etc/apache24/modules.d/280_mod_security.conf
echo '<IfModule security3_module>' >> /usr/local/etc/apache24/modules.d/280_mod_security.conf
echo '	modsecurity on' >> /usr/local/etc/apache24/modules.d/280_mod_security.conf
echo '	modsecurity_rules_file /usr/local/etc/modsecurity/crs-setup.conf' >> /usr/local/etc/apache24/modules.d/280_mod_security.conf
echo '</IfModule>' >> /usr/local/etc/apache24/modules.d/280_mod_security.conf 

# Restart Apache HTTP
apachectl restart

## References:
## https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-modsecurity-on-freebsd/
## https://github.com/SpiderLabs/owasp-modsecurity-crs
