# FAMP
FreeBSD + Apache + MySQL (or the like) + PHP (or Perl, Python)

This is a collection of scripts to build a FAMP server.

## stdard-famp.sh
The stdard-famp.sh script builds a standard FAMP server with the defaults on. Further detail in the following links.

https://www.adminbyaccident.com/freebsd/how-to-install-famp-stack/

https://www.digitalocean.com/community/tutorials/how-to-install-an-apache-mysql-and-php-famp-stack-on-freebsd-12-0

## event-php-fpm.sh
The event-php-fpm.sh script will install a FAMP stack server but Apache will be using the Event MPM and PHP will make use of the PHP-FPM processor. Further detail in the following links.

https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

## apache_hardening.sh
The apache_hardening.sh script does what its name indicates, placing a self-signed certificate, protects cookies and headers and a few more things. Further detail in the following links.

https://www.adminbyaccident.com/security/how-to-harden-apache-http/

## new-mysqldb.sh
The new-mysqldb.sh is a shell script launching expect in order to automate a database creation.

## wordpress-install.sh
The wordpress-install.sh script installs a Wordpress site, either having used the standard famp script or the event-php-fpm one. Further detail in the following link.

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-wordpress-on-freebsd/

## self-full-wpress.sh
The self-full-wpress.sh script is the sum of several of the above mentioned scripts. It will install a FAMP stack server with Apache using the Event MPM, PHP using PHP-FPM and will have some degree of hardening.
