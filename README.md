# FAMP
FreeBSD + Apache + MySQL (or the like) + PHP (or Perl, Python)

This is a collection of scripts to build and/or configure a FAMP server and other software that runs on this stack.

## The apache-geoip-allow.sh script
The apache-geoip-allow.sh script installs the geoipupdate utility which in combination of an account in MaxMindDB will help setting up a list of allowed geolocations to hit an Apache HTTP web server.
A cronjob is also installed so IPs from MaxMindDB are updated twice a week.

Mind to set up your account correctly in the script. Further details in the following link.

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-manage-site-visitors-based-on-ip-geolocation/

## The apache-geoip-block.sh script
The apache-geoip-block.sh script installs the geoipupdate utility which in combination of an account in MaxMindDB will help setting up a list of blocked geolocations when they hit an Apache HTTP web server.
A cronjob is also installed so IPs from MaxMindDB are updated twice a week.

Mind to set up your account correctly in the script. Further details in the following link.

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-manage-site-visitors-based-on-ip-geolocation/

## The apache_hardening.sh script
The apache_hardening.sh script does what its name indicates, placing a self-signed certificate, protects cookies and headers and a few more things. The full list of tweaks reads as follows:

1.- Remove information provided by your server such as its version
2.- Hide your PHP version
3.- A self-signed certificate will be installed
4.- SSL/TLS connections will be enabled
5.- HTTP headers will be installed and configured
6.- The TRACE method will be disabled
7.- Explicitely and exclusively allow the GET, POST and HEAD methods
8.- Install the Mod_Evasive module in Apache HTTP to help mitigate DoS attacks
9.- Install the Mod_Security module in Apache HTTP as a Web Application Firewall (WAF) setup with the default rules. Adjust to your needs.

Further detail in the following links.

https://www.adminbyaccident.com/security/how-to-harden-apache-http/
https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-modsecurity-2-on-freebsd/
https://httpd.apache.org/docs/2.4/misc/security_tips.html

## The apache_tls_self-signed.sh script
The apache_tls_self-signed.sh script generates a self signed x509 certificate with one year validity. As a plus it also enables the SSL module in Apache HTTP, the rewrite module, the shared object cache and it also sets HTTP security headers and places a redirect from port 80 to 443 for all web server connections on Apache HTTP.

Mind to change the parameters for the certificate, namely the country, state, location, owner, common name and email address in the line 59.

## The drupal-9-self-full-apache-mariadb-php-fpm-tcp-socket.sh script
The drupal-9-self-full-apache-mariadb-php-fpm-tcp-socket.sh script has a long name, but a deserved one. It uses Apache with the event processing module instead of the default pre-fork for enhanced performance. It uses TCP sockets so if eventually PHP is installed somewhere else Apache HTTP can be contacted through the network. As for the database this script makes use of MariaDB. And on top of the FAMP stack, this script install Drupal 9. 

The script makes use of expect for the mysql_secure_installation process and sets up a uniquely different password for each run which can be found in the /root directory. It also uses expect to configure a unique username and password for the Drupal DB settings and stores them in the same /root directory.

A full installation of Drupal 9 is executed (except the GUI part), with a TLS certificate installed, enabled and a 301 redirect for all connections from port 80 to port 443.

Further detail in the following links.

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-drupal-9-on-freebsd-13-0/

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

Mind to manually update any software version in the script if in need (ex:instead of php80, use php83 if needed), specially PHP and MariaDB as well as Drupal.

## The drupal-9-self-full-apache-mysql-php-fpm-tcp-socket.sh script
The drupal-9-self-full-apache-mysql-php-fpm-tcp-socket.sh script is basically the same as the MariaDB one (see above) but uses MySQL 8 instead. It uses Apache with the event processing module instead of the default pre-fork for enhanced performance. It uses TCP sockets so if eventually PHP is installed somewhere else Apache HTTP can be contacted through the network. As for the database this script makes use of MySQL 8. And on top of the FAMP stack, this script install Drupal 9. 

The script makes use of expect for the mysql_secure_installation process and sets up a uniquely different password for each run which can be found in the /root directory. It also uses expect to configure a unique username and password for the Drupal DB settings and stores them in the same /root directory.

A full installation of Drupal 9 is executed (except the GUI part), with a TLS certificate installed, enabled and a 301 redirect for all connections from port 80 to port 443.


Further detail in the following links.

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-drupal-9-on-freebsd-13-0/

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

Mind to manually update any software version in the script if in need (ex:instead of php80, use php83 if needed), specially PHP and MariaDB as well as Drupal.

## The enable-tls-self-signed.sh script
The enable-tls-self-signed.sh script creates a self signed x509 certificate valid for 365 days. It also enables the SSL module, the shared object cache module, and the rewrite module in Apache HTTP. It configures Apache HTTP to make use of the certificate and sets up a 301 redirect so any request via HTTP is redirected to HTTPS.

Mind to change the parameters for the certificate, namely the country, state, location, owner, common name and email address in the line 43.

## The event--mariadb-php-fpm-unix-socket.sh script
The event--mariadb-php-fpm-unix-socket.sh script basically sets up a FAMP stack using MariaDB as the database and uses UNIX sockets for the PHP-FPM communication process to happen. UNIX sockets are required for a single box scenario, and accessing disk straight away should be quicker than using the network stack after visiting the disk for the data. It does also configure Apache HTTP to make use of the event processing module instead of the default (in FreeBSD only) pre-fork for enhanced performance.

For further detail visit the follinw linkw

https://httpd.apache.org/docs/current/mod/event.html

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

## The event-php-fpm-tcp-socket.sh script
The event-php-fom-tcp-socket.sh script basically sets up a FAMP stack using MySQL 8 as the database and uses TCP sockets for the PHP-FPM communication process to happen. This script is set for a single box scenario, but having TCP sockets configured will help if a different box holding any piece (PHP, MySQL, web data, whatever) needs to communicate with the Apache HTTP instance. It does also configure Apache HTTP to make use of the event processing module instead of the default (in FreeBSD only) pre-fork for enhanced performance. The script makes use of expect for the mysql_secure_installation process and sets up a uniquely different password for each run which can be found in the /root directory.

For further detail visit the follinw links:

https://httpd.apache.org/docs/current/mod/event.html

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0

https://cwiki.apache.org/confluence/display/HTTPD/PHP-FPM

## The event-php-fpm-unix-socket.sh script
The event-php-fpm-unix-socket.sh script basically sets up a FAMP stack using MySQL 8 as the database and uses UNIX sockets for the PHP-FPM communication process to happen. This script is set for a single box scenario, and accessing disk straight away should be quicker than using the network stack after visiting the disk for the data. It does also configure Apache HTTP to make use of the event processing module instead of the default (in FreeBSD only) pre-fork for enhanced performance. The script makes use of expect for the mysql_secure_installation process and sets up a uniquely different password for each run which can be found in the /root directory.

For further detail visit the follinw links:

https://httpd.apache.org/docs/current/mod/event.html

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0

https://cwiki.apache.org/confluence/display/HTTPD/PHP-FPM

## The froxlor_isp-install.sh script
The froxlor_isp-install.sh script installs the Froxlor server management tool. As the baseline for the FAMP stack it uses the event-php-fpm-unix-socket.sh configuration. For further detail read the following link:

https://www.froxlor.org/

## The install-mariadb10.6-freebsd.sh script
The install-mariadb10.6-freebsd.sh script as its name states installs MariaDB 10.6 (if available in repo and FreeBSD version).

## The install-mysql80-freebsd.sh script
The install-mysql80-freebsd.sh script installs MySQL 8 and configures it. The script makes use of expect for the mysql_secure_installation process and sets up a uniquely different password for each run which can be found in the /root directory.

## The letsencrypt-auto.sh script
The letsencrypt-auto.sh script does install a certificate expelled from the LetsEncrypt CA plus adds security headers and a virtualhost entry for your site. Be aware of using it in combination with the apache_hardening.sh script, since they will collide.
More details on this script from these articles:

https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-freebsd-12-0

https://www.adminbyaccident.com/security/how-to-harden-apache-http/

https://www.digitalocean.com/community/tutorials/recommended-steps-to-harden-apache-http-on-freebsd-12-0

## The mediawiki-full-self-signed-pkg.sh script
The mediawiki-full-self-signed-pkg.sh script installs MediaWiki on top of a FAMP stack. MediaWiki is the software running Wikipedia, so there's plenty of features and power if in need to run a wiki. As the base for the FAMP stack this script is using a configuration very similar to the one in the event-php-fpm-unix-socket.sh script. The script installs MediaWiki using the already existing package in FreeBSD's repository.

Mind to adjust software versions as needed, specially MySQL, PHP and MediaWiki itself.

The script makes use of expect for the mysql_secure_installation process and sets up a uniquely different password for each run which can be found in the /root directory. It also uses expect to configure a unique username and password for the MediaWiki settings and stores them in the same /root directory.

A full installation of MediaWiki is executed, with a TLS certificate installed, enabled and a 301 redirect for all connections from port 80 to port 443.

## The mediawiki-full-self-signed-src.sh script
The mediawiki-full-self-signed-src.sh script installs MediaWiki on top of a FAMP stack. MediaWiki is the software running Wikipedia, so there's plenty of features and power if in need to run a wiki. As the base for the FAMP stack this script is using a configuration very similar to the one in the event-php-fpm-unix-socket.sh script. The script installs MediaWiki pulling from the MediaWiki source.

Mind to adjust software versions as needed, specially MySQL, PHP and MediaWiki itself.

The script makes use of expect for the mysql_secure_installation process and sets up a uniquely different password for each run which can be found in the /root directory. It also uses expect to configure a unique username and password for the MediaWiki settings and stores them in the same /root directory.

A full installation of MediaWiki is executed, with a TLS certificate installed, enabled and a 301 redirect for all connections from port 80 to port 443.

## The mod_evasive-install.sh script
The mod_evasive-install.sh script installs an Apache HTTP module to detect and help mitigate DoS attacks. Further detail in the following link.

https://www.adminbyaccident.com/freebsd/how-to-mitigate-dos-attacks-with-mod_evasive-on-freebsd/

## The modsecurity-2-install.sh script
The modsecurity-2-install.sh script installs the Modsecurity WAF (Web Application Firewall), an Apache HTTP module to help securing a FAMP stack. Its configuration in this set up is very basic, since it's not thought to protect any specific CMS, or software leveraging the FAMP stack. For further detail click on the following link:

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-modsecurity-2-on-freebsd/

Disclaimer: Do not install it on production unless you know what you are doing. Test in a pre-prod or in a separate VM/environment first. Configuring modsecurity requires some dedication.

## The modsecurity-2.9-wordpress.sh script
The modsecurity-2.9-wordpress.sh script installs the Modsecurity WAF (Web Application Firewall), an Apache HTTP module to help securing a FAMP stack. In this case the modsecurity module is already configured to protect a WordPress install sitting on a FAMP stack. For further detail click on the following link:

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-modsecurity-2-on-freebsd/

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-configure-modsecurity-3-for-wordpress-on-freebsd/

Disclaimer: Do not install it on production unless you know what you are doing. Test in a pre-prod or in a separate VM/environment first. Configuring modsecurity requires some dedication.

Disclaimer 2: Modsecurity 3 is no longer available, but version 2 still is available. The script has been changed to accomodate this circumstance. If tunning is required adjust whatever considerations given in the guides above to your needs. Use other resources too.

## The modsecurity3-install.sh script
The modsecurity3-install.sh script installed the Modsecurity WAF (Web Application Firewall) version 3, an Apache HTTP module to help securing a FAMP stack.

Disclaimer: Modsecurity 3 is no longer available, but version 2 still is available. Please make use of the modsecurity-2-install.sh script instead.

## The modsecurity3-wordpress.sh script
The modsecurity3-install.sh script installed the Modsecurity WAF (Web Application Firewall) version 3, an Apache HTTP module to help securing a FAMP stack. In this case the modsecurity module is already configured to protect a WordPress install sitting on a FAMP stack. For further detail click on the following link:

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-modsecurity-2-on-freebsd/

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-configure-modsecurity-3-for-wordpress-on-freebsd/

Disclaimer: Modsecurity 3 is no longer available, but version 2 still is available. Please make use of the modsecurity-2.9-wordpress.sh script instead.

## The monit-install.sh script
The monit-install.sh script installs the monit software which monitores services running on a server. This script configures monitoring for Apache HTTP, MySQL/MariaDB, PHP-FPM, Redis and Fail2ban. 

Disclaimer: I have experienced some funky issues while running this setup with MariaDB. Use it at your own risk.

## The new-mysqldb.sh script
The new-mysqldb.sh script basically does a "simple" thing. It creates a database on an already existing MySQL installation.

Disclaimer: Don't use this. Credentials are hardcoded and it simply doesn't help much using this. Grab the expect section on the event-php-fpm-unix-socket.sh or the event-php-fpm-tcp-socket.sh scripts as a baseline if you need to automate something and work on it to achieve your needs.

## The nexcloud.sh script
The nextcloud.sh script will install a Nextcloud instance so you can have your own cloud services to store your files and browse them through a PC or the dedicated phone app. Further detail on the following link:

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-nextcloud-on-freebsd-12/

Disclaimer: It's been quite a long time since I updated and used this script/setup. Use it at your own risk.

Disclaimer 2: There's no FAMP stack as a base for this script. Choose whatever FAMP stack configuration from the scripts above that suits you. I'd rather recommend to use the event-php-fpm-unix-socket.sh script as a base.

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

## The opcache.sh script 
The opcache.sh script basically configures the OPCache in PHP. Further detail in the following links:

https://www.php.net/manual/en/opcache.installation.php

https://www.php.net/manual/en/opcache.configuration.php

## The php74-upgrade-php81.sh script
The php74-upgrade-php81.sh script does what it claims, it updates a PHP 7.4 FAMP stack to a PHP 8.1 equipped one. Adapt the script to other versions if needed but mind some packages on version 7.4 are no longer available in 8.x and some naming convention may have changed.

## The proxy_apache-self-signed file
The proxy_apache-self-signed file is not finished and it's been left without care for years. Don't use this for anything.

## The self-CA-plus-cert-key-pair.sh script
The self-CA-plus-cert-key-pair.sh script is an atempt to use openssl for sel signing certificate issuing for local consumption. Nothing pretentious. 

Disclaimer: If you really want to use a self signed CA, don't use this. Instead make use of Easy-RSA. 

https://www.freshports.org/security/easy-rsa/

https://easy-rsa.readthedocs.io/en/latest/

## The self-full-nextcloud.sh script
The self-full-nextcloud.sh script installs a Nextcloud instance as well as a base FAMP stack. It uses Apache with the event processing module instead of the default pre-fork for enhanced performance. It uses TCP sockets so if eventually PHP is installed somewhere else Apache HTTP can be contacted through the network. As for the database this script makes use of MySQL 8. 

The script makes use of expect for the mysql_secure_installation process and sets up a uniquely different password for each run which can be found in the /root directory. It also uses expect to configure a unique username and password for the Nextcloud settings and stores them in the same /root directory.

A full installation of Nextcloud is executed (except the GUI part), with a TLS certificate installed, enabled and a 301 redirect for all connections from port 80 to port 443. It does also contain some hardening making use of the waf-like-rules.conf file preventing some attacks.

Further detail in the following link.

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-nextcloud-on-freebsd-12/

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/


## The self-full-wpress-mariadb.sh script
The self-full-wpress-mariadb.sh script installs a full FAMP stack with WordPress on top using MariaDB for the database. It also configures a self-signed certificate. 

Mind to change the parameters of the certificate and do not use the ones in the script. Therefore, adjust the country, state, location, owner, common name and email address between the lines 194 and 207.

The script makes use of expect for the mysql_secure_installation process and sets up a uniquely different password for each run which can be found in the /root directory. It also uses expect to configure a unique username and password for the WordPress database settings and stores them in the same /root directory.

Further detail in the following links:

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-wordpress-on-freebsd/

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

## The self-full-wpress.sh script
The self-full-wpress-mariadb.sh script installs a full FAMP stack with WordPress on top using MySQL 8 for the database. It also configures a self-signed certificate.

Mind to change the parameters of the certificate and do not use the ones in the script. Therefore, adjust the country, state, location, owner, common name and email address between the lines 194 and 207.

The script makes use of expect for the mysql_secure_installation process and sets up a uniquely different password for each run which can be found in the /root directory. It also uses expect to configure a unique username and password for the WordPress database settings and stores them in the same /root directory.

Further detail in the following links:

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-wordpress-on-freebsd/

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

## The wordpress-install.sh script
The wordpress-install.sh script installs a Wordpress site, either having used the standard famp script or the event-php-fpm one. Further detail in the following links.

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-wordpress-on-freebsd/

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

## The stdard-famp.sh script
The stdard-famp.sh script builds a standard FAMP server with the defaults on. This installation uses the pre-fork processing module in Apache, which will create a new proces for each new connection to the server. The event configuration is much faster and uses less resources. This is only recommended for legacy applications and severe security restrictions. Further detail in the following links.

https://www.adminbyaccident.com/freebsd/how-to-install-famp-stack/

https://www.digitalocean.com/community/tutorials/how-to-install-an-apache-mysql-and-php-famp-stack-on-freebsd-12-0

## The waf-like-rules.conf file
The waf-like-rules.conf file is a useful configuration file to be used with Apache HTTP. It prevents a few different attacks to be carried on. Not as powerful as a modsecurity configuration, but useful nevertheless, specially when not having a well tuned modsecurity in place but needing to be publicly available. 

## The wordpress-install-mariadb.sh script
The wordpress-install-mariadb.sh script imagines a FreeBSD box with Apache installed but nothing else. The script will install PHP and MariaDB.
The script makes use of expect for the mysql_secure_installation process and sets up a uniquely different password for each run which can be found in the /root directory. It also uses expect to configure a unique username and password for the WordPress database settings and stores them in the same /root directory.

Disclaimer: I don't recommned the use of this very script. This script does not issue a self signed certificate, nor it configures any redirect or HTTPS. If you need those use the self-full-wpress-mariadb.sh script.

## The wordpress-install.sh script
The wordpress-install.sh script installs a Wordpress site, either having used the standard FAMP script or the event-php-fpm ones. Further detail in the following links.

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-wordpress-on-freebsd/

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/
