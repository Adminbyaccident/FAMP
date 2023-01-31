#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: apache-hardening.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 20-02-2021
# SET FOR: Dev
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This is a hardening script for Apache HTTP
#
# REV LIST:
# DATE: 31-01-2023
# BY: ALBERT VALBUENA
# MODIFICATION: 31-01-2023
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

###########################################################################################################
###########################################  WARNING !!!  #################################################
###########################################################################################################

echo '

###########################################################################################################
###########################################  WARNING !!!  #################################################
###########################################################################################################

THIS SCRIPT WILL EXECUTE FOLLOWING THESE NEXT STEPS IN 30 SECONDS.

YOU HAVE BEEN WARNED!

# Use this script at your own discretion. It modifies important bits of your Apache HTTP configuration
# For example it will:
# 1.- Remove information provided by your server such as its version
# 2.- Hide your PHP version
# 3.- A self-signed certificate will be installed
# 4.- SSL/TLS connections will be enabled
# 5.- HTTP headers will be installed and configured
# 6.- The TRACE method will be disabled
# 7.- Explicitely and exclusively allow the GET, POST and HEAD methods
# 8.- Install the Mod_Evasive module in Apache HTTP to help mitigate DoS attacks
# 9.- Install the Mod_Security module in Apache HTTP as a Web Application Firewall (WAF) setup with the default rules. Adjust to your needs.
'

sleep 30

# 1.- Removing the OS type and modifying version banner 
echo 'ServerTokens Prod' >> /usr/local/etc/apache24/httpd.conf
echo 'ServerSignature Off' >> /usr/local/etc/apache24/httpd.conf

# 2.- Avoid PHP's information (version, etc) being disclosed
sed -i -e '/expose_php/s/expose_php = On/expose_php = Off/' /usr/local/etc/php.ini

# 3.- Fine tunning access to the DocumentRoot directory structure
sed -i '' -e 's/Options Indexes FollowSymLinks/Options -Indexes +FollowSymLinks -Includes/' /usr/local/etc/apache24/httpd.conf

# 4.- Enabling TLS connections with a self signed certificate. 
# 4.1- Key and certificate generation
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /usr/local/etc/apache24/server.key -out /usr/local/etc/apache24/server.crt -subj "/C=ES/ST=Barcelona/L=Terrassa/O=Adminbyaccident.com/CN=example.com/emailAddress=yourmail@gmail.com"

# Because we have generated a certificate + key we will enable SSL/TLS in the server.
# 4.3- Enabling TLS connections in the server.
sed -i -e '/mod_ssl.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 4.4- Enable the server's default TLS configuration to be applied.
sed -i -e '/httpd-ssl.conf/s/#Include/Include/' /usr/local/etc/apache24/httpd.conf

# 4.5- Enable TLS session cache.
sed -i -e '/mod_socache_shmcb.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 4.6- Redirect HTTP connections to HTTPS (port 80 and 443 respectively)
# 4.6.1- Enabling the rewrite module
sed -i -e '/mod_rewrite.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 4.6.2- Adding the redirection rules from HTTP to HTTPS.
echo 'RewriteEngine On' >> /usr/local/etc/apache24/httpd.conf
echo 'RewriteCond %{HTTPS}  !=on' >> /usr/local/etc/apache24/httpd.conf
echo 'RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]' >> /usr/local/etc/apache24/httpd.conf

# 5.- Secure headers
echo "
<IfModule mod_headers.c>
        # Add security and privacy related headers
        Header set Content-Security-Policy \"upgrade-insecure-requests;\"
        Header always edit Set-Cookie (.*) \"\$1; HttpOnly; Secure\"
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

# 6.- Disable the TRACE method.
echo 'TraceEnable off' >> /usr/local/etc/apache24/httpd.conf

# 7.- Allow specific HTTP methods.
sed -i '' -e '272i\
<LimitExcept GET POST HEAD>' /usr/local/etc/apache24/httpd.conf
sed -i '' -e '273i\
deny from all' /usr/local/etc/apache24/httpd.conf
sed -i '' -e '274i\
</LimitExcept>' /usr/local/etc/apache24/httpd.conf

# Restart Apache HTTP so changes take effect.
service apache24 restart

# 8.- Install mod_evasive
pkg install -y ap24-mod_evasive

# 8.1- Enable the mod_evasive module in Apache HTTP
sed -i -e '/mod_evasive20.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 8.2- Configure the mod_evasive module
touch /usr/local/etc/apache24/modules.d/020-mod_evasive.conf

echo "<IfModule mod_evasive20.c>
	DOSHashTableSize 3097
	DOSPageCount 20
	DOSSiteCount 50
	DOSPageInterval 1
	DOSSiteInterval 1
	DOSBlockingPeriod 360
	DOSEmailNotify youremail@address.com
	DOSSystemCommand \"su – root -c /sbin/ipfw add 50000 deny %s to any in\"
	DOSLogDir \"/var/log/mod_evasive\"
</IfModule>" >> /usr/local/etc/apache24/modules.d/020-mod_evasive.conf

# 8.4- Restart Apache for the configuration to take effect
apachectl graceful

# 9.- WAF-like rules enablement for any generic FAMP stack. Applicable to WPress, Drupal, Joomla, Nextcloud and the likes of those.
# Create an empty httpd-security.conf file
touch /usr/local/etc/apache24/extra/httpd-security.conf

# 9.1- Enabling the rewrite module
sed -i -e '/mod_rewrite.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

echo "
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteCond %{HTTP_USER_AGENT} (havij|libwww-perl|wget|python|nikto|curl|scan|java|winhttp|clshttp|loader) [NC,OR]
RewriteCond %{HTTP_USER_AGENT} (%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{HTTP_USER_AGENT} (;|<|>|'|\"|\)|\(|%0A|%0D|%22|%27|%28|%3C|%3E|%00).*(libwww-perl|wget|python|nikto|curl|scan|java|winhttp|HTTrack|clshttp|archiver|loader|email|harvest|extract|grab|miner|fetch) [NC,OR]
RewriteCond %{THE_REQUEST} (\?|\*|%2a)+(%20+|\\\s+|%20+\\\s+|\\\s+%20+|\\\s+%20+\\\s+)(http|https)(:/|/) [NC,OR]
RewriteCond %{THE_REQUEST} etc/passwd [NC,OR]
RewriteCond %{THE_REQUEST} cgi-bin [NC,OR]
RewriteCond %{THE_REQUEST} (%0A|%0D|\\r|\\n) [NC,OR]
RewriteCond %{REQUEST_URI} owssvr\.dll [NC,OR]
RewriteCond %{HTTP_REFERER} (%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{HTTP_REFERER} \.opendirviewer\. [NC,OR]
RewriteCond %{HTTP_REFERER} users\.skynet\.be.* [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(http|https):// [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(\.\.//?)+ [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=/([a-z0-9_.]//?)+ [NC,OR]
RewriteCond %{QUERY_STRING} \=PHP[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} [NC,OR]
RewriteCond %{QUERY_STRING} (\.\./|%2e%2e%2f|%2e%2e/|\.\.%2f|%2e\.%2f|%2e\./|\.%2e%2f|\.%2e/) [NC,OR]
RewriteCond %{QUERY_STRING} ftp\: [NC,OR]
RewriteCond %{QUERY_STRING} (http|https)\: [NC,OR]
RewriteCond %{QUERY_STRING} \=\|w\| [NC,OR]
RewriteCond %{QUERY_STRING} ^(.*)/self/(.*)$ [NC,OR]
RewriteCond %{QUERY_STRING} ^(.*)cPath=(http|https)://(.*)$ [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*script.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^s]*s)+cript.*(>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*embed.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^e]*e)+mbed.*(>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*object.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^o]*o)+bject.*(>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*iframe.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} (<|%3C)([^i]*i)+frame.*(>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} base64_encode.*\(.*\) [NC,OR]
RewriteCond %{QUERY_STRING} base64_(en|de)code[^(]*\([^)]*\) [NC,OR]
RewriteCond %{QUERY_STRING} GLOBALS(=|\[|\%[0-9A-Z]{0,2}) [OR]
RewriteCond %{QUERY_STRING} _REQUEST(=|\[|\%[0-9A-Z]{0,2}) [OR]
RewriteCond %{QUERY_STRING} ^.*(\(|\)|<|>|%3c|%3e).* [NC,OR]
RewriteCond %{QUERY_STRING} ^.*(\x00|\x04|\x08|\x0d|\x1b|\x20|\x3c|\x3e|\x7f).* [NC,OR]
RewriteCond %{QUERY_STRING} (NULL|OUTFILE|LOAD_FILE) [OR]
RewriteCond %{QUERY_STRING} (\.{1,}/)+(motd|etc|bin) [NC,OR]
RewriteCond %{QUERY_STRING} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{QUERY_STRING} (<|>|''|%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{QUERY_STRING} concat[^\(]*\( [NC,OR]
RewriteCond %{QUERY_STRING} union([^s]*s)+elect [NC,OR]
RewriteCond %{QUERY_STRING} union([^a]*a)+ll([^s]*s)+elect [NC,OR]
RewriteCond %{QUERY_STRING} \-[sdcr].*(allow_url_include|allow_url_fopen|safe_mode|disable_functions|auto_prepend_file) [NC,OR]
RewriteCond %{QUERY_STRING} (;|<|>|'|\"|\)|%0A|%0D|%22|%27|%3C|%3E|%00).*(/\*|union|select|insert|drop|delete|update|cast|create|char|convert|alter|declare|order|script|set|md5|benchmark|encode) [NC,OR]
# Condition to block Proxy/LoadBalancer/WAF bypass
RewriteCond %{HTTP:X-Client-IP} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-For} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-Scheme} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Real-IP} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-By} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Originating-IP} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-From} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Forwarded-Host} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP:X-Remote-Addr} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{QUERY_STRING} (sp_executesql) [NC]
RewriteRule ^(.*)$ - [F]
</IfModule>
" >> /usr/local/etc/apache24/extra/httpd-security.conf

echo "
Include /usr/local/etc/apache24/extra/httpd-security.conf
" >> /usr/local/etc/apache24/httpd.conf

# Restart Apache HTTP to load the WAF-like configuration.
service apache24 restart

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

service apache24 restart

## References:
## https://www.adminbyaccident.com/security/how-to-harden-apache-http/
## https://www.digitalocean.com/community/tutorials/recommended-steps-to-harden-apache-http-on-freebsd-12-0
## /usr/local/etc/apache24/modules.d/280_mod_security.conf
