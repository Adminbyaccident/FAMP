#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: apache_tls_self-signed-interactive.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 20-08-2024
# SET FOR: Test
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 13/14
#
# PURPOSE: Self signed TLS certificate generation for Apache HTTP + redirection to HTTPS
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

# This script does:
# Verifies if Apache HTTP is installed, if not it executes an install and service start up
# Asks for the needed parameters for the certificate creation
# Creates a Self Signed certificate using OpenSSL
# Enables TLS on Apache HTTP
# Enables the default TLS configuration found on Apache HTTP for FreeBSD
# Enables the Rewrite module on Apache HTTP
# Applies the redirect from HTTP to HTTPS
# Starts Apache HTTP

# Uncomment if the latest packages are needed instead of the quarterly released ones.
# sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf
# pkg upgrade -y

# Message to users for questions
echo "After this message you will be prompted for a few questions in order to issue the self signed certificate."
sleep 15

# Prompt the user for input
read -p "Enter the number of days for the certificate validity (e.g., 365): " days
read -p "Enter the RSA key size (between 1024 and 4096): " rsa_value
read -p "Enter the path for the output key file (e.g., /usr/local/etc/apache24/server.key): " keyout_path
read -p "Enter the path for the output certificate file (e.g., /usr/local/etc/apache24/server.crt): " crtout_path
read -p "Enter the country code (C) (e.g., ES): " country
read -p "Enter the state or province (ST) (e.g., Barcelona): " state
read -p "Enter the locality (L) (e.g., Terrassa): " locality
read -p "Enter the organization name (O) (e.g., Adminbyaccident.com): " organization
read -p "Enter the common name (CN) (e.g., example.com): " common_name
read -p "Enter the email address (e.g., youremail@gmail.com): " email_address

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
# Construct the openssl command  to issue a self-signed certificate and key for Apache HTTPwith the user inputs
openssl req -x509 -nodes -days "$days" -newkey rsa:"$rsa_value" \
  -keyout "$keyout_path" -out "$crtout_path" \
  -subj "/C=$country/ST=$state/L=$locality/O=$organization/CN=$common_name/emailAddress=$email_address"

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
        Header always set Referrer-Policy \"strict-origin\"
        Header set X-Frame-Options \"deny\"
        Header set Permissions-Policy \"accelerometer=(); ambient-light-sensor=(); autoplay=(); battery=(); camera=(); clipboard-read=(); clipboard-write=(); cross-origin-isolated=(); display-capture=(); document-domain=(); encrypted-media='self'; execution-while-not-rendered=(); execution-while-out-of-viewport=(); fullscreen=(); geolocation=(); gyroscope=(); hid=(); idle-detection=(); interest-cohort=(); layout-animations=(); legacy-image-formats='self'; magnetometer=(); microphone=(); midi=(); navigation-override=(); notifications=(); oversized-images='self'; payment=(); picture-in-picture=(); publickey-credentials-get=(); screen-wake-lock=(); serial=(); speaker=(); sync-xhr=(); usb=(); vr=(); wake-lock=(); web-share=(); xr-spatial-tracking=()\"
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
