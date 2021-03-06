#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# This script will enable a self-signed certificate and key pair on an already existing FAMP stack box.

# Enable the SSL/TLS module
sed -i -e '/mod_ssl.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Enable the default SSL/TLS configuration
sed -i -e '/httpd-ssl.conf/s/#Include/Include/' /usr/local/etc/apache24/httpd.conf

# Enable the SSL/TLS cache module
sed -i -e '/mod_socache_shmcb.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Create a self-signed certificate and key for Apache HTTP (ADAPT Organization, Common Name and Email)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /usr/local/etc/apache24/server.key -out /usr/local/etc/apache24/server.crt -subj "/C=ES/ST=Barcelona/L=Terrassa/O=Adminbyaccident.com/CN=example.com/emailAddress=youremail@gmail.com"

# Restart Apache HTTP to make changes effective
service apache24 restart

# Inform the user SSL/TLS is now enabled on this server.
echo "SSL/TLS has been enabled on this server"
