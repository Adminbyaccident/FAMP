#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

## This script will only work on a FreeBSD + Apache HTTP install.
## Adjust your-domain.com to your real one.

# Change the default pkg repository from quarterly to latest
sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages (it will first download the pkg repo from latest)
# secondly it will upgrade any installed packages.
pkg upgrade -y

# Install the Certbot utility for Apache HTTP
pkg install -y py37-certbot py37-certbot-apache

# Enable SSL/TLS in Apache HTTP
sed -i -e '/mod_ssl.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# Enable Virtual Hosts
sed -i -e '/httpd-vhosts.conf/s/#Include/Include/' /usr/local/etc/apache24/httpd.conf
 
# Make a backup of the original httpd-vhosts.conf file
cp /usr/local/etc/apache24/extra/httpd-vhosts.conf /usr/local/etc/apache24/extra/httpd-vhosts.conf.backup

# Remove the original httpd-vhosts file
rm /usr/local/etc/apache24/extra/httpd-vhosts.conf

# Create an empty httpd-vhosts file
touch /usr/local/etc/apache24/extra/httpd-vhosts.conf

# Add our configuration in the httpd-vhosts file
echo "
<VirtualHost *:80>
    ServerAdmin your_email@your_domain.com
    DocumentRoot "/usr/local/www/apache24/data/your_domain.com"
    ServerName your_domain.com
    ServerAlias www.your_domain.com
    ErrorLog "/var/log/your_domain.com-error_log"
    CustomLog "/var/log/your_domain.com-access_log" common
</VirtualHost>" >> /usr/local/etc/apache24/extra/httpd-vhosts.conf

# Create the DocumentRoot for your site
mkdir /usr/local/www/apache24/data/your_domain.com

# Place an index.html file to test your site
touch /usr/local/www/apache24/data/your-domain.com/index.html

# Put the minimal content in index.html
echo "
<html><body><h1>It works!</h1></body></html>" >> /usr/local/www/apache24/data/your-domain.com/index.html

# Certbot will configure Apache HTTP's virtual hosts configuration file with a redirect
# or not depending on your needs. In this script a redirect from HTTP to HTTPS is chosen.
# If you don't want a redirect as such, replace the "2" for a "1" in the send part of the expect script.

# Install the 'old fashioned' Expect to automate the certbot part
pkg install -y expect

# Launch the certbot utility for Apache HTTP
LETENCRYPT_APACHE=$(expect -c "
set timeout 10
spawn certbot --apache -d your-domain -d www.your-domain
expect \"Select\"
send \2\r\"
expect eof
")

# Let's add some security to the site
# 1.- Create a block for your site's security headers.
touch /usr/local/etc/apache24/Includes/headers.conf

# Populate the security headers file
echo "
<IfModule mod_headers.c>
        # Add security and privacy related headers
        Header set Content-Security-Policy "upgrade-insecure-requests;"
        Header always edit Set-Cookie (.*) "$1; HttpOnly; Secure"
        Header set Strict-Transport-Security "max-age=31536000; includeSubDomains"
        Header set X-Content-Type-Options "nosniff"
        Header set X-XSS-Protection "1; mode=block"
        Header set X-Robots-Tag "all"
        Header set X-Download-Options "noopen"
        Header set X-Permitted-Cross-Domain-Policies "none"
        Header always set Referrer-Policy: "strict-origin"
        Header set X-Frame-Options: "deny"
        Header set Permissions-Policy: "geolocation=(none); midi=(none); camera=(none); notifications=(none); microphone=(none); speaker=(none); payment=(none)"
        SetEnv modHeadersAvailable true
</IfModule>" >> /usr/local/etc/apache24/Includes/headers.conf

# 2.- Edit your virtualhosts file to include the following:

echo "
<VirtualHost *:443>
    ServerName your-domain.com
    ServerAlias www.your-domain.com
    ServerSignature Off
    DocumentRoot "/usr/local/www/apache24/data/your-domain.com"
    ErrorLog "/var/log/your-domain.com-error_log"
    CustomLog "/var/log/your-domain.com-access_log"common
    Options -Indexes +FollowSymLinks -Includes
    Protocols h2 h2c http/1.1
    Include /usr/local/etc/letsencrypt/options-ssl-apache.conf
    Include /usr/local/etc/apache24/Includes/headers.conf
    SSLCertificateFile /usr/local/etc/letsencrypt/live/your-domain.com/fullchain.pem
    SSLCertificateKeyFile /usr/local/etc/letsencrypt/live/your.com/privkey.pem
</VirtualHost> >> /usr/local/etc/apache24/extra/httpd-vhosts.conf

echo "
Visit your site with your browser http://your-domain.com and you should see the redirect to HTTPS and the index.html page rendering It works!
"

## References:
## https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-freebsd-12-0
## https://www.adminbyaccident.com/security/how-to-harden-apache-http/
## https://www.digitalocean.com/community/tutorials/recommended-steps-to-harden-apache-http-on-freebsd-12-0
