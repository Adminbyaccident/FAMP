#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: apache_tls_self-signed.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 06-02-2021
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: Self signed TLS certificate generation for Apache HTTP + redirection to HTTPS
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

# This script does:
# Creates a Self Signed certificate using OpenSSL
# Enables TLS on Apache HTTP
# Enables the default TLS configuration found on Apache HTTP for FreeBSD
# Enables the Rewrite module on Apache HTTP
# Applies the redirect from HTTP to HTTPS
# IMPORTANT: Assumes Apache HTTP is installed. If not uncomment the install section.

# Uncomment if the latest packages are needed instead of the quarterly released ones.
# sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf
# pkg upgrade -y

####### Start of the Apache HTTP install section #######

# Check if Apache HTTP (apache24) is already installed
if pkg info -e apache24; then
    echo "Apache HTTP is already installed. Skipping installation."
else
    # Install Apache
    pkg install -y apache24

    # Add service to be fired up at boot time
    sysrc apache24_enable="YES"

    # Start Apache HTTP
    service apache24 start
fi

####### End of the Apache HTTP install section #######

# 1. Key and certificate generation
# Create a self-signed certificate and key for Apache HTTP 
# IMPORTANT: Pleasdo do adapt the fields below like: Organization, Common Name and Email, etc.
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /usr/local/etc/apache24/server.key -out /usr/local/etc/apache24/server.crt -subj "/C=ES/ST=Barcelona/L=Terrassa/O=Adminbyaccident.com/CN=example.com/emailAddress=youremail@gmail.com"

# 2.- Enable TLS connections in the Apache HTTP web server.
sed -i -e '/mod_ssl.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 3.- Enable the server's default TLS configuration to be applied.
sed -i -e '/httpd-ssl.conf/s/#Include/Include/' /usr/local/etc/apache24/httpd.conf

# 4.- Enable TLS session cache.
sed -i -e '/mod_socache_shmcb.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 5.- Enabling the rewrite module
sed -i -e '/mod_rewrite.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 6.- Add security headers
echo "
<IfModule mod_headers.c>
        # Add security and privacy related headers
        Header set Content-Security-Policy \"upgrade-insecure-requests;\"
        Header always edit Set-Cookie (.*) \"$1; HttpOnly; Secure\"
        Header set Strict-Transport-Security \"max-age=31536000; includeSubDomains\"
        Header set X-Content-Type-Options \"nosniff\"
        Header set X-XSS-Protection \"1; mode=block\"
        Header set X-Robots-Tag \"all\"
        Header set X-Download-Options \"noopen\"
        Header set X-Permitted-Cross-Domain-Policies \"none\"
        Header always set Referrer-Policy: \"strict-origin\"
        Header set X-Frame-Options: \"deny\"
        Header set Permissions-Policy: \"accelerometer=(none); ambient-light-sensor=(none); autoplay=(none); battery=(none); display-capture=(none); document-domain=(none); encrypted-media=(self); execution-while-not-rendered=(none); execution-while-out-of-viewport=(none); geolocation=(none); gyroscope=(none); layout-animations=(none); legacy-image-formats=(self); magnometer=(none); midi=(none); camera=(none); notifications=(none); microphone=(none); speaker=(none); oversized-images=(self); payment=(none); picture-in-picture=(none); publickey-credentials-get=(none); sync-xhr=(none); usb=(none); vr=(none); wake-lock=(none); screen-wake-lock=(none); web-share=(none); xr-partial-tracking=(none)\"
        SetEnv modHeadersAvailable true
</IfModule>" >>  /usr/local/etc/apache24/Includes/headers.conf

echo " 
Include /usr/local/etc/apache24/Includes/headers.conf
" >> /usr/local/etc/apache24/httpd.conf

# 7.- Redirect from port 80 to port 443 to get HTTPS

echo "
# 301 Redirection from port 80 to port 443
RewriteEngine On
RewriteCond %{HTTPS} !=on
RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
" >> /usr/local/etc/apache24/httpd.conf

# Restart Apache HTTP to apply changes
service apache24 restart

# EOF
