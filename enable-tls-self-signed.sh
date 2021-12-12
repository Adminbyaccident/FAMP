#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: enable-tls-self-signed.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 13-10-2021
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script will enable a self-signed certificate and key pair on an already existing FAMP stack box.
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

# Enable the SSL/TLS module
sed -i -e '/mod_ssl.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Enable the default SSL/TLS configuration
sed -i -e '/httpd-ssl.conf/s/#Include/Include/' /usr/local/etc/apache24/httpd.conf

# Enable the SSL/TLS cache module
sed -i -e '/mod_socache_shmcb.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 5.- Enabling the rewrite module
sed -i -e '/mod_rewrite.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Create a self-signed certificate and key for Apache HTTP (ADAPT Organization, Common Name and Email)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /usr/local/etc/apache24/server.key -out /usr/local/etc/apache24/server.crt -subj "/C=ES/ST=Barcelona/L=Terrassa/O=Adminbyaccident.com/CN=example.com/emailAddress=youremail@gmail.com"

# Restart Apache HTTP to make changes effective
service apache24 restart

# Redirect from port 80 to port 443 to get HTTPS
echo "
# 301 Redirection from port 80 to port 443
RewriteEngine On
RewriteCond %{HTTPS} !=on
RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
" >> /usr/local/etc/apache24/httpd.conf

# Restart Apache HTTP to apply changes
service apache24 restart

# Inform the user SSL/TLS is now enabled on this server.
echo "SSL/TLS has been enabled on this server"

# EOF
