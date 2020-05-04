#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

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
	DOSSystemCommand "su – root -c /sbin/ipfw add 50000 deny %s to any in"
	DOSLogDir "/var/log/mod_evasive"
</IfModule>" >> /usr/local/etc/apache24/modules.d/020-mod_evasive.conf

# Restart Apache for the configuration to take effect
apachectl graceful

## References:
## https://www.adminbyaccident.com/freebsd/how-to-mitigate-dos-attacks-with-mod_evasive-on-freebsd/
