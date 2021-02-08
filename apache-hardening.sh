#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

###########################################################################################################
###########################################  WARNING !!!  #################################################
###########################################################################################################

# Use this script at your own discretion. It modifies important bits of your Apache HTTP configuration
# For example it changes:
# 1.- Information provided by your server
# 2.- It installs a self-signed certificate (modify this at your own will)
# 3.- If, of course, enables SSL/TLS connections
# 4.- Configures HTTP headers to be secure in a strict fashion. This may break some of your desired features. Adjust accordingly.
# 5.- Disables the TRACE method
# 6.- Explicitely and exclusively allows the GET, POST and HEAD methods
# 7.- It installs the Mod_Evasive module in Apache HTTP to help mitigate DoS attacks
# 8.- It installs the Mod_Security module in Apache HTTP as a Web Application Firewall (WAF) setup with the default rules. Adjust to your needs.

# Install GNU sed to circumvent some of the syntax challenges the BSD sed has
# such as inserting a line of text in a specific location needing a new line, etc.
pkg install -y gsed

# Be aware we are using GNU sed here. 
# When inserting lines do it from bottom to top or inserting new lines can disrupt
# the default order of a file, eventually breaking the configuration.
# Consider using echo instead.

# 1.- Removing the OS type and modifying version banner (no mod_security here). 
# 1.1- ServerTokens will only display the minimal information possible.
gsed -i '227i\ServerTokens Prod' /usr/local/etc/apache24/httpd.conf

# 1.2- ServerSignature will disable the server exposing its type.
gsed -i '228i\ServerSignature Off' /usr/local/etc/apache24/httpd.conf

# Alternatively we can inject the line at the bottom of the file using the echo command.
# This is a safer option if you make heavy changes at the top of the file.
# echo 'ServerTokens Prod' >> /usr/local/etc/apache24/httpd.conf
# echo 'ServerSignature Off' >> /usr/local/etc/apache24/httpd.conf

# 2.- Avoid PHP's information (version, etc) being disclosed
sed -i -e '/expose_php/s/expose_php = On/expose_php = Off/' /usr/local/etc/php.ini

# 3.- Fine tunning access to the DocumentRoot directory structure
sed -i '' -e 's/Options Indexes FollowSymLinks/Options -Indexes +FollowSymLinks -Includes/' /usr/local/etc/apache24/httpd.conf

# 4.- Enabling TLS connections with a self signed certificate. 
# 4.1- Key and certificate generation
# Because this is a process where manual interaction is required let's make use of Expect so no hands are needed.

pkg install -y expect

SECURE_APACHE=$(expect -c "
set timeout 10
spawn openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /usr/local/etc/apache24/server.key -out /usr/local/etc/apache24/server.crt
expect \"Country Name (2 letter code) \[AU\]:\"
send \"ES\r\"
expect \"State or Province Name (full name) \[Some-State\]:\"
send \"Barcelona\r\"
expect \"Locality Name (eg, city) \[\]:\"
send \"Terrassa\r\"
expect \"Organization Name (eg, company) \[Internet Widgits Pty Ltd\]:\"
send \"Adminbyaccident.com\r\"
expect \"Organizational Unit Name (eg, section) \[\]:\"
send \"Operations\r\"
expect \"Common Name (e.g. server FQDN or YOUR name) \[\]:\"
send \"Albert Valbuena\r\"
expect \"Email Address \[\]:\"
send \"thewhitereflex@gmail.com\r\"
expect eof
")

echo "$SECURE_APACHE"

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

# 4.6.2- Adding the redirection rules.
# Use the following GNU sed entries if you are using the event-php-fpm.sh script.
gsed -i '181i\RewriteEngine On' /usr/local/etc/apache24/httpd.conf
gsed -i '182i\RewriteCond %{HTTPS}  !=on' /usr/local/etc/apache24/httpd.conf
gsed -i '183i\RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]' /usr/local/etc/apache24/httpd.conf

# Use the following entries (by uncommenting these and commenting the above GNU sed ones) 
# if you are using the stdard-famp.sh script, or things will break.
# echo 'RewriteEngine On' /usr/local/etc/apache24/httpd.conf
# echo 'RewriteCond %{HTTPS}  !=on' /usr/local/etc/apache24/httpd.conf
# echo 'RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]' /usr/local/etc/apache24/httpd.conf

# 5.- Secure headers
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

# 6.- Disable the TRACE method.
echo 'TraceEnable off' >> /usr/local/etc/apache24/httpd.conf

# 7.- Allow specific HTTP methods.
gsed -i '269i\    <LimitExcept GET POST HEAD>' /usr/local/etc/apache24/httpd.conf
gsed -i '270i\       deny from all' /usr/local/etc/apache24/httpd.conf
gsed -i '271i\    </LimitExcept>' /usr/local/etc/apache24/httpd.conf

# 8.- Restart Apache HTTP so changes take effect.
service apache24 restart

# 9.- Install mod_evasive
pkg install -y ap24-mod_evasive

# 9.1- Enable the mod_evasive module in Apache HTTP
sed -i -e '/mod_evasive20.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf

# 9.2- Configure the mod_evasive module
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

# 9.4- Restart Apache for the configuration to take effect
apachectl graceful

# 10.- WAF-like rules enablement for any generic FAMP stack. Applicable to WPress, Drupal, Joomla, Nextcloud and the likes of those.
# Create an empty httpd-security.conf file
touch /usr/local/etc/apache24/extra/httpd-security.conf

echo "
<IfModule mod_rewrite.c>

RewriteEngine on

# Condition to block suspicious request methods.
RewriteCond %{REQUEST_METHOD} ^(HEAD|TRACE|DELETE|TRACK|DEBUG) [NC,OR]

# Condition to block the specified user agents from programs and bots.
RewriteCond %{HTTP_USER_AGENT} (havij|libwww-perl|wget|python|nikto|curl|scan|java|winhttp|clshttp|loader|fetch) [NC,OR]
RewriteCond %{HTTP_USER_AGENT} (%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{HTTP_USER_AGENT} (;|<|>|'|\"|\)|\(|%0A|%0D|%22|%27|%28|%3C|%3E|%00).*(libwww-perl|wget|python|nikto|curl|scan|java|winhttp|HTTrack|clshttp|archiver|loader|email|harvest|extract|grab|miner) [NC,OR]

# Condition to block suspicious header requests.
RewriteCond %{HTTP_ACCEPT} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_COOKIE} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_FORWARDED} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_HOST} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_PROXY_CONNECTION} (localhost|loopback|127\.0\.0\.1) [NC,OR]
RewriteCond %{HTTP_REFERER} (localhost|loopback|127\.0\.0\.1) [NC,OR]

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

# Condition to block requests that incorporate the specified expressions in them. Avoid injection.
RewriteCond %{THE_REQUEST} (\?|\*|%2a)+(%20+|\\s+|%20+\\s+|\\s+%20+|\\s+%20+\\s+)(http|https)(:/|/) [NC,OR]

# Condition to block any request containing the etc/passwd string and avoid system passwords exfiltration.
RewriteCond %{THE_REQUEST} etc/passwd [NC,OR]

# Condition to block the execution of CGI programs.
RewriteCond %{THE_REQUEST} cgi-bin [NC,OR]

# Condition to block requests that jump into the next line. Avoid injection.
RewriteCond %{THE_REQUEST} (%0A|%0D|\\r|\\n) [NC,OR]

# Condition to block any Sharepoint services call.
RewriteCond %{REQUEST_URI} owssvr\.dll [NC,OR]

# Condition to block requests that simulate to come from the specified expressions. Avoid injection.
RewriteCond %{HTTP_REFERER} (%0A|%0D|%27|%3C|%3E|%00) [NC,OR]
RewriteCond %{HTTP_REFERER} \.opendirviewer\. [NC,OR]
RewriteCond %{HTTP_REFERER} users\.skynet\.be.* [NC,OR]

# Condition to block requests that incorporate the specified expressions in them.
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(http|https):// [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=(\.\.//?)+ [NC,OR]
RewriteCond %{QUERY_STRING} [a-zA-Z0-9_]=/([a-z0-9_.]//?)+ [NC,OR]

# Condition to block any PHP execution. Avoid injection.
RewriteCond %{QUERY_STRING} \=PHP[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} [NC,OR]
RewriteCond %{QUERY_STRING} (\.\./|%2e%2e%2f|%2e%2e/|\.\.%2f|%2e\.%2f|%2e\./|\.%2e%2f|\.%2e/) [NC,OR]

# Condition to block FTP usage. Avoid uploads.
RewriteCond %{QUERY_STRING} ftp\: [NC,OR]

# Condition to block any requests jumping over paths or injecting/retrieving objects.
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

# Condition to block with the intention to en/de-code strings in base64
RewriteCond %{QUERY_STRING} base64_encode.*\(.*\) [NC,OR]
RewriteCond %{QUERY_STRING} base64_(en|de)code[^(]*\([^)]*\) [NC,OR]

# Condition to block
RewriteCond %{QUERY_STRING} GLOBALS(=|\[|\%[0-9A-Z]{0,2}) [OR]
RewriteCond %{QUERY_STRING} _REQUEST(=|\[|\%[0-9A-Z]{0,2}) [OR]

# Condition to block requests that incorporate the specified expressions in them. Avoid injection.
RewriteCond %{QUERY_STRING} ^.*(\(|\)|<|>|%3c|%3e).* [NC,OR]
RewriteCond %{QUERY_STRING} ^.*(\x00|\x04|\x08|\x0d|\x1b|\x20|\x3c|\x3e|\x7f).* [NC,OR]

# Condition to block requests which declare the specified values in the string query. Avoid injection.
RewriteCond %{QUERY_STRING} (NULL|OUTFILE|LOAD_FILE) [OR]

# Condition to block requests intending to retrieve or inject content in the motd file or /etc and /bin directories.
RewriteCond %{QUERY_STRING} (\.{1,}/)+(motd|etc|bin) [NC,OR]

# Condition to block any string referencing to the host or loopback interface.
RewriteCond %{QUERY_STRING} (localhost|loopback|127\.0\.0\.1) [NC,OR]

# Condition to block requests that incorporate the specified expressions in them. Avoid injection.
RewriteCond %{QUERY_STRING} (<|>|'|%0A|%0D|%27|%3C|%3E|%00) [NC,OR]

# Condition to block SQL injection attacks 
RewriteCond %{QUERY_STRING} concat[^\(]*\( [NC,OR]
RewriteCond %{QUERY_STRING} union([^s]*s)+elect [NC,OR]
RewriteCond %{QUERY_STRING} union([^a]*a)+ll([^s]*s)+elect [NC,OR]
RewriteCond %{QUERY_STRING} \-[sdcr].*(allow_url_include|allow_url_fopen|safe_mode|disable_functions|auto_prepend_file) [NC,OR]
RewriteCond %{QUERY_STRING} (;|<|>|'|\"|\)|%0A|%0D|%22|%27|%3C|%3E|%00).*(/\*|union|select|insert|drop|delete|update|cast|create|char|convert|alter|declare|order|script|set|md5|benchmark|encode) [NC,OR]
RewriteCond %{QUERY_STRING} (sp_executesql) [NC]

# The rewrite rule itself. Any match gets blocked.
RewriteRule ^(.*)$ - [F]

</IfModule>
" >> /usr/local/etc/apache24/extra/nextcloud-security.conf

echo "
Include /usr/local/etc/apache24/extra/httpd-security.conf
" >> /usr/local/etc/apache24/httpd.conf

# Restart Apache HTTP to load the WAF-like configuration.
service apache24 restart

# 11.- Install Modsecurity 3 for Apache HTTP. 
# If you apply step 10 there's no much need of ModSecurity unless you really need it.
# pkg install -y modsecurity3-apache

# Download Git SpiderLab Rules >> OWASP ModSecurity Core Rule Set
# pkg install -y git
# git clone https://github.com/coreruleset/coreruleset /usr/local/etc/modsecurity/coreruleset/
# cp /usr/local/etc/modsecurity/coreruleset/crs-setup.conf.example /usr/local/etc/modsecurity/coreruleset/crs-setup.conf
# sed -ip 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /usr/local/etc/modsecurity/modsecurity.conf

# Set the configuration files for ModSecurity 3 to work
# touch /usr/local/etc/apache24/modsecurity-rules.conf

# echo "
# Include /usr/local/etc/modsecurity/modsecurity.conf
# Include /usr/local/etc/modsecurity/coreruleset/crs-setup.conf
# Include /usr/local/etc/modsecurity/coreruleset/rules/*.conf
# " >> /usr/local/etc/apache24/modsecurity-rules.conf

# Enable ModSecurity's 3 module
# echo "
# modsecurity on
# modsecurity_rules_file /usr/local/etc/apache24/modsecurity-rules.conf
# " >> /usr/local/etc/apache24/httpd.conf

# Rename 2 config files
# mv /usr/local/etc/modsecurity/coreruleset/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /usr/local/etc/modsecurity/coreruleset/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf

# mv /usr/local/etc/modsecurity/coreruleset/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example /usr/local/etc/modsecurity/coreruleset/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

# Restart Apache HTTP
# apachectl restart

## References:
## https://www.adminbyaccident.com/security/how-to-harden-apache-http/
## https://www.digitalocean.com/community/tutorials/recommended-steps-to-harden-apache-http-on-freebsd-12-0
