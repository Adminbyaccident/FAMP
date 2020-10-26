# FAMP
FreeBSD + Apache + MySQL (or the like) + PHP (or Perl, Python)

This is a collection of scripts to build a FAMP server.

## The stdard-famp.sh script
The stdard-famp.sh script builds a standard FAMP server with the defaults on. This installation uses the pre-fork processing module in Apache, which will create a new proces for each new connection to the server. The event configuration is much faster and uses less resources. This is only recommended for legacy applications and severe security restrictions. Further detail in the following links.

https://www.adminbyaccident.com/freebsd/how-to-install-famp-stack/

https://www.digitalocean.com/community/tutorials/how-to-install-an-apache-mysql-and-php-famp-stack-on-freebsd-12-0

## The event-php-fpm-tcp-socket.sh script
The event-php-fpm.sh script will install a FAMP stack server but Apache HTTP will be using the Event MPM and PHP will make use of the PHP-FPM processor. The handler is set to use TCP sockets. Much faster and resource optimized compared to the pre-fork configuration. Further detail in the following links.

https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

https://cwiki.apache.org/confluence/display/HTTPD/PHP-FPM

## The event-php-fpm-unix-socket.sh
The event-php-fpm-unix-socket.sh will have the same FAMP stack installation with Apache HTTP using the Event MPM and PHP making use of the PHP-FPM processor. However the handler will make use of the UNIX sockets. Further detail in the following links.

https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-set-apaches-mpm-event-and-php-fpm-on-freebsd/

https://cwiki.apache.org/confluence/display/HTTPD/PHP-FPM

## The apache_hardening.sh script
The apache_hardening.sh script does what its name indicates, placing a self-signed certificate, protects cookies and headers and a few more things. Further detail in the following links.

https://www.adminbyaccident.com/security/how-to-harden-apache-http/

## The letsencrypt-auto.sh script
The letsencrypt-auto.sh script does install a certificate expelled from the LetsEncrypt CA plus adds security headers and a virtualhost entry for your site. Be aware of using it in combination with the apache_hardening.sh script, since they will collide.
More details on this script from these articles:

https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-freebsd-12-0

https://www.adminbyaccident.com/security/how-to-harden-apache-http/

https://www.digitalocean.com/community/tutorials/recommended-steps-to-harden-apache-http-on-freebsd-12-0

## The install-mysql80-freebsd.sh script
Not difficult to guess, this script does install MySQL version 8 on FreeBSD automatically. Reference:
https://www.adminbyaccident.com/freebsd/how-to-freebsd/install-mariadb-freebsd/

## The new-mysqldb.sh script
The new-mysqldb.sh is a shell script launching expect in order to automate a database creation.

## The wordpress-install.sh script
The wordpress-install.sh script installs a Wordpress site, either having used the standard famp script or the event-php-fpm one. Further detail in the following link.

https://www.adminbyaccident.com/freebsd/how-to-freebsd/how-to-install-wordpress-on-freebsd/

## The self-full-wpress.sh script
The self-full-wpress.sh script is the sum of several of the above mentioned scripts. It will install a FAMP stack server with Apache using the Event MPM, PHP using PHP-FPM and will have some degree of hardening.


## The nexcloud.sh script
The nextcloud.sh script will install a Nextcloud instance so you can have your own cloud services to store your files and browse them through a PC or the dedicated phone app.
An article on 'How to install Nextcloud on FreeBSD' is on the works for adminbyaccident.com.
