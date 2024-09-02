#!/usr/local/bin/bash
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: faemp-beta-3.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 30-08-2024
# SET FOR: Beta
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 13/14
#
# PURPOSE: Installs a FAMP stack or a FEMP stack based on user selection.
# FAMP: FreeBSD, Apache HTTP, MariaDB or MySQL, and PHP 
# FEMP: FreeBSD, NGINX HTTP, MariaDB or MySQL, and PHP
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


##########################################################
##################### Disclaimer #########################
##########################################################

echo "This software is in BETA."
echo "The use of this script for other purposes than testing is strongly discouraged."
echo "The software writer nor the distributor shall be liable for any damage or loss."
echo "YOU HAVE BEEN WARNED"
sleep 30

echo "Do you understand this is beta and unstable software?"
echo "1) YES"
echo "2) NO"
read -p "Enter the correspondent number: " beta_choice

beta_question() {
	if [ "$beta_choice" -eq 1 ]; then
		echo "Execution starts now..."
	elif [ "$beta_choice" -eq 2 ]; then
		exit 1
	else
		echo "Wrong answer"
		exit 1
	fi
}

# Step 1: Verify Installed Software

# Funtion to check if the IPFW firewall is enabled
check_ipfw_firewall() {
	if grep 'firewall_enable' /etc/rc.conf; then
		echo "It seems an IPFW firewall is set on this system."
		ipfw_configured=true
	else
		ipfw_configured=false
	fi
}		

# Funtion to check if the PF firewall is enabled
check_pf_firewall() {
	if grep 'pf_enable' /etc/rc.conf; then
		echo "It seems a PF firewall is set on this system."
		pf_configured=true
	else
		pf_configured=false
	fi
}		

# Funtion to check if the IPFilter firewall is enabled
check_ipfilter_firewall() {
	if grep 'ipfilter_enable' /etc/rc.conf; then
		echo "It seems a PF firewall is set on this system."
		ipfilter_configured=true
	else
		ipfilter_configured=false
	fi
}

# Function to check if Apache HTTP is installed
check_apache() {
    if pkg info -e "apache24"; then
        echo "Apache HTTP is already installed on this system."
        apache_installed=true
    else
        apache_installed=false
    fi
}

# Function to check if NGINX is installed
check_nginx() {
    if pkg info -e "nginx"; then
        echo "NGINX is already installed on this system."
        nginx_installed=true
    else
        nginx_installed=false
    fi
}

# Function to check if MySQL is installed
check_mysql() {
    if pkg info -e "mysql*-server"; then
        echo "MySQL is already installed on this system."
        mysql_installed=true
    else
        mysql_installed=false
    fi
}

# Function to check if MariaDB is installed
check_mariadb() {
    if pkg info -e "mariadb*-server"; then
        echo "MariaDB is already installed on this system."
        mariadb_installed=true
    else
        mariadb_installed=false
    fi
}

# Function to check if PHP is installed
check_php() {
    if pkg info | grep -q "^php"; then
        echo "PHP is already installed on this system."
        php_installed=true
    else
        php_installed=false
    fi
}

# Function to check if PHP.ini exists
check_php_ini() {
	if find /usr/local/etc/ -name php.ini >> /dev/null; then
		php_ini_exists=true
	else
		echo "A PHP.ini file does not exist. Please execute any of the following commands as root:"
		echo "cp /usr/local/etc/php.ini-development /usr/local/etc/php.ini"
		echo "cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini"
		php_ini_exists=false
	fi	
}

# Step 2: Ask for User Input

select_firewall() {
    if [ "$ipfw_configured" = false ] && [ "$pf_configured" = false ] && [ "$ipfilter_configured" = false ]; then
        echo "It seems there is NO firewall configured on this system."
        echo "Would you like to automatically configure a firewall now?"
        echo "1) YES"
        echo "2) NO"
        read -p "Enter the corresponding number: " wants_firewall
			if [ "$wants_firewall" -eq 1 ]; then
				echo "This script can configure one of two basic firewall options for web server protection:"
				echo "1) IPFW"
				echo "2) PF"
				read -p "Enter the corresponding number: " firewall_type_selection
			elif [ "$wants_firewall" -eq 2 ]; then
				echo "No firewall will be configured for you on this system."
			else
				echo "Invalid selection for firewall configuration"
			fi
    elif [ "$ipfw_configured" = true ]; then
        echo "It seems an IPFW firewall is configured. Make sure web service ports are reachable."
		return 0
    elif [ "$pf_configured" = true ]; then
        echo "It seems a PF firewall is configured. Make sure web service ports are reachable."
		return 0
    elif [ "$ipfilter_configured" = true ]; then
        echo "It seems an IPFilter firewall is configured. Make sure web service ports are reachable."
		return 0
    else
        echo "Failed to discover a firewall install. Make sure you have one configured for web server use."
    fi
}

select_web_server() {
	if [ "$apache_installed" = true ]; then
		echo "Apache HTTP is already installed."
		echo "This script won't install a second web server, nor modify the existing one."
		return 0
	elif [ "$nginx_installed" = true ]; then
		echo "NGINX is already installed."
		echo "This script won't install a second web server, nor modify the existing one."
		return 0
	elif [ "$apache_installed" = false ] && [ "$nginx_installed" = false ]; then
		echo "Select a web server to install:"
		echo "1) Apache HTTP"
		echo "2) NGINX"
		read -p "Enter your choice (1 or 2): " webserver_choice
	else
		echo "Something went wrong with the web server identification process."
	fi
}

select_database_server() {
	if [ "$mysql_installed" = true ]; then
		return 0
	elif [ "$mariadb_installed" = true ]; then
		return 0
	elif [ "$mysql_installed" = false ] && [ "$mariadb_installed" = false ]; then
		echo "Select a database server to install:"
		echo "1) MySQL"
		echo "2) MariaDB"
		read -p "Enter your choice (1 or 2): " db_choice

		if [ "$db_choice" -eq 1 ]; then
			echo "Select the MySQL version to install:"
			echo "0) 8.0"
			echo "1) 8.1"
			echo "2) 8.4"
			read -p "Enter the corresponding number: " mysql_version_choice
		elif [ "$db_choice" -eq 2 ]; then
			echo "Select the MariaDB version to install:"
			echo "0) 10.5"
			echo "1) 10.6"
			echo "2) 10.11"
			echo "3) 10.14"
			read -p "Enter the corresponding number: " mariadb_version_choice
		fi
	else
		echo "Something went wrong with the database server identification process."
	fi
}

select_php_version() {
	if [ "$php_installed" = true ]; then
		echo "PHP is already installed; no new PHP installation will be performed."
		return 0
	elif [ "$php_installed" = false ]; then
		echo "Select the PHP version to install:"
		echo "1) PHP 8.1"
		echo "2) PHP 8.2"
		echo "3) PHP 8.3"
		echo "4) PHP 8.4"
		read -p "Enter your choice (1, 2, 3, or 4): " php_choice
	else
		echo "Something went wrong with the PHP identification process."
	fi
}

select_apache_mpm() {
	if [ "$apache_installed" = true ]; then
		return 0
	elif [ "$nginx_installed" = true ]; then
		return 0
	elif [ "$webserver_choice" -eq 2 ]; then
		return 0
	elif [ "$webserver_choice" -eq 1 ]; then
		echo "Select an Apache HTTP Multi-Processing Module:"
		echo "1) Pre-fork"
		echo "2) Worker"
		echo "3) Event"
		read -p "Enter the corresponding number: " apache_mpm_choice
	else 
		echo "Something went wrong with the web server identification process."
	fi
}

select_nginx_php-fpm_socket() {
	if [ "$apache_installed" = true ]; then
		return 0
	elif [ "$nginx_installed" = true ]; then
		return 0
	elif [ "$webserver_choice" -eq 2 ]; then
		    echo "Select an NGINX Socket Connection Type:"
			echo "1) UNIX socket (ideal for standalone servers)"
			echo "2) TCP socket (most flexible, ideal for multiple backend servers)"
			read -p "Enter your choice (1 or 2): " nginx_socket_choice
	else
		echo "Something went wrong in the web server discovery process."
	fi
}

select_php_ini() {
	if [ "$php_installed" = true ]; then
		return 0
	elif [ "$php_installed" = false ]; then
		echo "Select a PHP.ini setting:"
		echo "1) Development"
		echo "2) Production"
		read -p "Enter your choice (1 or 2): " phpini_selection
	else
		echo "Something went wrong with the php.ini identification process."
	fi
}

select_apache_socket() {
	if [ "$apache_installed" = true ]; then
		return 0
	elif [ "$nginx_installed" = true ]; then
		return 0
	elif [ "$webserver_choice" -eq 2 ]; then
		return 0
	elif [ "$webserver_choice" -eq 1 ]; then
		echo "Select an Apache Socket Connection Type:"
		echo "1) UNIX socket (ideal for standalone servers)"
		echo "2) TCP socket (most flexible, ideal for multiple backend servers)"
		read -p "Enter your choice (1 or 2): " apache_socket_choice
	else 
		echo "Something went wrong with the web server identification process."
	fi	
}

select_php_ini_reconf () {
if [ "$php_ini_exists" = true ]; then  
	echo "A PHP.ini file already exists. Do you want to reconfigure it? Options are:"
	echo "1) Do nothing, keep it as it is"
	echo "2) Re-configure it as a development php.ini"
	echo "3) Re-configure it as a production php.ini"
	read -p "Enter your choice (1, 2, or 3): " reconf_php_ini
elif [ "$php_ini_exists" = false ]; then  
	echo "A PHP.ini file does NOT exist. Do you want to configure it? Options are:"
	echo "1) Do nothing, keep the system as is (not recommended)"
	echo "2) Re-configure it as a development php.ini"
	echo "3) Re-configure it as a production php.ini"
	read -p "Enter your choice (1, 2, or 3): " reconf_php_ini
else
	echo "Invalid selection for PHP.ini."
	echo "Manually review the existance of /usr/local/etc/php.ini"
fi
}

# Step 3: Install Software Based on User Input
install_firewall() {
    if [ "$ipfw_configured" = true ] && [ "$pf_configured" = false ] && [ "$ipfilter_configured" = false ]; then
        return 0
    elif [ "$ipfw_configured" = false ] && [ "$pf_configured" = true ] && [ "$ipfilter_configured" = false ]; then
        return 0
    elif [ "$ipfw_configured" = false ] && [ "$pf_configured" = false ] && [ "$ipfilter_configured" = true ]; then
        return 0
	elif [ "$wants_firewall" -eq 2 ]; then
		return 0		
	elif [ "$wants_firewall" -eq 1 ] && [ "$firewall_type_selection" -eq 1 ]; then
			sysrc firewall_enable="YES"
			sysrc firewall_quiet="YES"
			sysrc firewall_type="workstation"
			sysrc firewall_logdeny="YES"
			sysrc firewall_allowservices="any"
			sysrc firewall_myservices="22/tcp 80/tcp 443/tcp"
			echo "An IPFW firewall configuration has been set up."
			echo "Open ports are: 22, 80, 443, all over TCP."
			echo "Do you want to enable the firewall now?"
			echo "1) YES"
			echo "2) NO, I will start the service later"
			read -p "Enter the corresponding number: " ipfw_enable
					if [ "$ipfw_enable" -eq 1 ]; then
							service ipfw start
					elif [ "$ipfw_enable" -eq 2 ]; then
							echo "The firewall won't be started."
					else
							echo "Invalid selection for firewall start-up."
					fi
	elif [ "$wants_firewall" -eq 1 ] && [ "$firewall_type_selection" -eq 2 ]; then
			net_if=$(ifconfig | grep -o '^[^:]*' | head -1)
			echo "
################ Start of PF rules file #####################

# Define network interface
net_if = \"$net_if\"

# Define services to allow
services_tcp = \"{ ssh, http, https }\"

# Allow all traffic on the loopback interface
set skip on lo0

# Default block all traffic
block all

# Anti-spoofing protection
antispoof log quick for \$net_if

# Allow inbound SSH, HTTP, and HTTPS
pass in on \$net_if proto tcp from any to any port \$services_tcp keep state

# Allow outbound SSH, HTTP, and HTTPS
pass out on \$net_if proto tcp to any port \$services_tcp keep state

# Allow DNS queries (optional, if needed)
pass out on \$net_if proto udp to any port domain keep state
pass in on \$net_if proto udp from any to any port domain keep state

################ End of PF rules file #####################
                " >> /etc/pf.conf
                sysrc pf_enable="YES"
                echo "A PF firewall configuration has been set up."
                echo "After this script is almost finished you will be asked to start up the PF firewall or not."
        elif [ "$wants_firewall" -eq 2 ]; then
                return 0

        else
                echo "Invalid firewall selection"
        fi
}

install_web_server() {
	if [ "$apache_installed" = true ]; then
		return 0
	elif [ "$nginx_installed" = true ]; then
		return 0
    elif [ "$webserver_choice" -eq 1 ]; then
		echo "Installing Apache HTTP..."
		pkg install -y apache24
		sysrc apache24_enable="YES"
            if [ "$apache_mpm_choice" -eq 1 ]; then
                echo "Nothing to do, Apache HTTP on FreeBSD defaults to prefork MPM."
            elif [ "$apache_mpm_choice" -eq 2 ]; then
                sed -i -e '/mpm_prefork/s/LoadModule/#LoadModule/' /usr/local/etc/apache24/httpd.conf
                sed -i -e '/mpm_worker/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf
            elif [ "$apache_mpm_choice" -eq 3 ]; then
                sed -i -e '/mpm_prefork/s/LoadModule/#LoadModule/' /usr/local/etc/apache24/httpd.conf
                sed -i -e '/mpm_event/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf
            else
                echo "Invalid MPM choice. Using default prefork MPM."
            fi

        service apache24 start
     
    elif [ "$webserver_choice" -eq 2 ]; then
        echo "Installing NGINX..."
		pkg install -y nginx
		sysrc nginx_enable="YES"
		service nginx start
    else
        echo "Invalid selection. No web server will be installed."
    fi
}

config_nginx_php-fpm() {
	if [ "$apache_installed" = true ]; then
		return 0
	elif [ "$nginx_installed" = true ]; then
		return 0
    elif [ "$webserver_choice" -eq 2 ]; then
		if [ "$nginx_socket_choice" -eq 1 ]; then
			mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.orig
			pkg install -y git
			git clone https://github.com/Adminbyaccident/FEMP.git /tmp/conf
			cp /tmp/conf/base_nginx_unix_socket.conf /usr/local/etc/nginx/nginx.conf
			rm -r /tmp/conf
			mkdir /usr/local/www/sites
			touch /usr/local/www/sites/index.html
			echo "<h1> It works as NGINX! </h1>"
		elif [ "$nginx_socket_choice" -eq 2 ]; then
			mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.orig
			pkg install -y git
			git clone https://github.com/Adminbyaccident/FEMP.git /tmp/conf
			cp /tmp/conf/base_nginx_tcp_socket.conf /usr/local/etc/nginx/nginx.conf
			rm -r /tmp/conf
			mkdir /usr/local/www/sites
			touch /usr/local/www/sites/index.html
			echo "<h1> It works as NGINX! </h1>"
		else
			echo "Something went wrong configuring NGINX."
		fi	
    else
        echo "Invalid selection. No web server will be installed."
    fi
}

install_database_server() {
    mysql_versions=("80" "81" "84")
    mariadb_versions=("105" "106" "1011" "1014")

	if [ "$mysql_installed" = true ]; then
		return 0
	elif [ "$mariadb_installed" = true ]; then
		return 0
    elif [ "$db_choice" -eq 1 ]; then
        if [ "$mariadb_installed" = true ]; then
            echo "MariaDB is already installed; cannot install MySQL."
        elif [ "$mysql_installed" = false ]; then
            selected_mysql_version=${mysql_versions[$mysql_version_choice]}
            echo "Installing MySQL version $selected_mysql_version..."
            pkg install -y mysql${selected_mysql_version}-server
			sysrc mysql_enable="YES"
			service mysql-server start
        else
            echo "MySQL is already installed."
        fi
    elif [ "$db_choice" -eq 2 ]; then
        if [ "$mysql_installed" = true ]; then
            echo "MySQL is already installed; cannot install MariaDB."
        elif [ "$mariadb_installed" = false ]; then
            selected_mariadb_version=${mariadb_versions[$mariadb_version_choice]}
            echo "Installing MariaDB version $selected_mariadb_version..."
            pkg install -y mariadb${selected_mariadb_version}-server
			sysrc mysql_enable="YES"
			service mysql-server start
        else
            echo "MariaDB is already installed."
        fi
    else
        echo "Invalid selection. No database server will be installed."
    fi
}

database_secure_install() {
if [ "$mysql_installed" = true ]; then
	return 0
elif [ "$mariadb_installed" = true ]; then
	return 0
elif [ "$db_choice" -eq 1 ]; then
	# Install the 'old fashioned' Expect to automate the mysql_secure_installation part
	pkg install -y expect
	# Install pwgen to generate random username and password
	pkg install -y pwgen
	# Generate database root password
	DB_ROOT_PASSWORD=$(pwgen 32 --secure --numerals --capitalize) && export DB_ROOT_PASSWORD && echo $DB_ROOT_PASSWORD >> /root/db_root_pwd.txt
	# MySQL service restart
	service mysql-server restart
	# Execution of mysql_secure_installation
	SECURE_MYSQL=$(expect -c "
	set timeout 10
	set DB_ROOT_PASSWORD "$DB_ROOT_PASSWORD"
	spawn mysql_secure_installation
	expect \"Press y|Y for Yes, any other key for No:\"
	send \"y\r\"
	expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
	send \"0\r\"
	expect \"New password:\"
	send \"$DB_ROOT_PASSWORD\r\"
	expect \"Re-enter new password:\"
	send \"$DB_ROOT_PASSWORD\r\"
	expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
	send \"Y\r\"
	expect \"Remove anonymous users?\"
	send \"y\r\"
	expect \"Disallow root login remotely?\"
	send \"y\r\"
	expect \"Remove test database and access to it?\"
	send \"y\r\"
	expect \"Reload privilege tables now?\"
	send \"y\r\"
	expect eof
	")
	echo "$SECURE_MYSQL"
	# Display the location of the generated root password for MySQL
	echo "Your DB_ROOT_PASSWORD is written on this file /root/db_root_pwd.txt"
	# No one but root can read this file. Read only permission.
	chmod 400 /root/db_root_pwd.txt
elif [ "$db_choice" -eq 2 ]; then
	# Install the 'old fashioned' Expect to automate the mysql_secure_installation part
	pkg install -y expect
	# Make the 'safe' install for MariaDB
	echo "Performing MariaDB secure install"
	# MariaDB service restart
	service mysql-server restart
	#Execution of mysql_secure_installation
	SECURE_MARIADB=$(expect -c "
	set timeout 10
	spawn mysql_secure_installation
	expect \"Switch to unix_socket authentication\"
	send \"n\r\"
	expect \"Change the root password?\"
	send \"n\r\"
	expect \"Remove anonymous users?\"
	send \"y\r\"
	expect \"Disallow root login remotely?\"
	send \"y\r\"
	expect \"Remove test database and access to it?\"
	send \"y\r\"
	expect \"Reload privilege tables now?\"
	send \"y\r\"
	expect eof
	")
	echo "$SECURE_MARIADB"
else
	echo "Something went wrong with the database secure installation process"
	echo "Manually run \"mysql_secure_installation\" to correctly execute the process"

fi
}

install_php_version() {
    if [ "$php_installed" = true ]; then
		return 0
    elif [ "$php_installed" = false ]; then
        case $php_choice in
            1)
                php_version="81"
                ;;
            2)
                php_version="82"
                ;;
			3)
				php_version="83"
				;;
			4)
				php_version="84"
				;;
            *)
                echo "Invalid selection. No PHP will be installed."
                return
                ;;
        esac

        echo "Installing PHP $php_version..."
        pkg install -y php${php_version}
    
	else
		echo "Something went wrong installing PHP on this system."
	fi
}

config_php_ini() {
	if [ "$reconf_php_ini" -eq 1 ]; then
		return 0
	elif [ "$reconf_php_ini" -eq 2 ]; then
		return 0
	elif [ "$reconf_php_ini" -eq 3 ]; then
		return 0
	elif [ "$phpini_selection" -eq 1 ]; then
		cp /usr/local/etc/php.ini-development /usr/local/etc/php.ini
		echo "PHP.ini for development has been configured."
	elif [ "$phpini_selection" -eq 2 ]; then
		cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
		echo "PHP.ini for production has been configured."
	else
		echo "Invalid selection. No PHP.ini will be configured."
	fi
}

config_apache_http_plus_php() {
	if [ "$apache_installed" = true ]; then
		return 0
	elif [ "$nginx_installed" = true ]; then
		return 0
	elif [ "$webserver_choice" -eq 2 ]; then
		return 0
	elif [ "$apache_mpm_choice" -eq 1 ]; then
		pkg install -y mod_php${php_version} php${php_version}-extensions
		echo "mod_php${php_version} has been installed."
		#Configure Apache HTTP to speak PHP
		touch /usr/local/etc/apache24/modules.d/001_mod-php.conf
		echo "
		<IfModule dir_module>
			DirectoryIndex index.php index.html
			<FilesMatch \"\.php$\"> 
				SetHandler application/x-httpd-php
			</FilesMatch>
			<FilesMatch \"\.phps$\">
				SetHandler application/x-httpd-php-source
			</FilesMatch>
		</IfModule>" >> /usr/local/etc/apache24/modules.d/001_mod-php.conf
		# Start services
		service apache24 start
	elif [ "$apache_mpm_choice" -eq 2 ]; then
		#Install PHP extensions
		pkg install -y php${php_version}-extensions
		# Configure Apache Proxy Modules for socket use
		sed -i -e '/mod_proxy.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf
		sed -i -e '/mod_proxy_fcgi.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf
		sysrc php_fpm_enable="YES"
		touch /usr/local/etc/apache24/modules.d/003_php-fpm.conf
			if [ "$apache_socket_choice" -eq 1 ]; then
				#Configure Apache HTTP to interact with PHP-FPM using UNIX socket
				echo "
				<IfModule proxy_fcgi_module>
					<IfModule dir_module>
						DirectoryIndex index.php
					</IfModule>
					<FilesMatch \"\.(php)$\">
						SetHandler proxy:unix:/var/run/php-fpm.sock|fcgi://localhost/
					</FilesMatch>
				</IfModule>" >> /usr/local/etc/apache24/modules.d/003_php-fpm.conf
				#Configure PHP-FPM to use UNIX socket for interaction with Apache HTTP
				sed -i -e 's/127.0.0.1:9000/\/var\/run\/php-fpm.sock/g' /usr/local/etc/php-fpm.d/www.conf
				sed -i -e 's/;listen.owner/listen.owner/g' /usr/local/etc/php-fpm.d/www.conf
				sed -i -e 's/;listen.group/listen.group/g' /usr/local/etc/php-fpm.d/www.conf
				# Start services
				service apache24 restart
				service php-fpm start
					
			elif [ "$apache_socket_choice" -eq 2 ]; then
				# Configure Apache HTTP to interact with PHP-FPM using a TCP socket
				echo "
				<IfModule proxy_fcgi_module>
					<IfModule dir_module>
						DirectoryIndex index.php
					</IfModule>
					<FilesMatch \"\.(php)$\">
						SetHandler proxy:fcgi://127.0.0.1:9000
					</FilesMatch>
				</IfModule>" >> /usr/local/etc/apache24/modules.d/003_php-fpm.conf
				# Start services
				service apache24 restart
				service php-fpm start
			else
				echo "Invalid Apache HTTP socket selection."
				echo "Manually review the content of the /usr/local/etc/apache24/modules.d/003_php-fpm.conf file."
			fi
		
		
	elif [ "$apache_mpm_choice" -eq 3 ]; then
		#Install PHP extensions
		pkg install -y php${php_version}-extensions
		# Configure Apache Proxy Modules for socket use
		sed -i -e '/mod_proxy.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf
		sed -i -e '/mod_proxy_fcgi.so/s/#LoadModule/LoadModule/' /usr/local/etc/apache24/httpd.conf
		sysrc php_fpm_enable="YES"
		touch /usr/local/etc/apache24/modules.d/003_php-fpm.conf
			if [ "$apache_socket_choice" -eq 1 ]; then
				#Configure Apache HTTP to interact with PHP-FPM using UNIX socket
				echo "
				<IfModule proxy_fcgi_module>
					<IfModule dir_module>
						DirectoryIndex index.php
					</IfModule>
					<FilesMatch \"\.(php)$\">
						SetHandler proxy:unix:/var/run/php-fpm.sock|fcgi://localhost/
					</FilesMatch>
				</IfModule>" >> /usr/local/etc/apache24/modules.d/003_php-fpm.conf
				#Configure PHP-FPM to use UNIX socket for interaction with Apache HTTP
				sed -i -e 's/127.0.0.1:9000/\/var\/run\/php-fpm.sock/g' /usr/local/etc/php-fpm.d/www.conf
				sed -i -e 's/;listen.owner/listen.owner/g' /usr/local/etc/php-fpm.d/www.conf
				sed -i -e 's/;listen.group/listen.group/g' /usr/local/etc/php-fpm.d/www.conf
				# Start services
				service apache24 restart
				service php-fpm start
					
			elif [ "$apache_socket_choice" -eq 2 ]; then
				# Configure Apache HTTP to interact with PHP-FPM using a TCP socket
				echo "
				<IfModule proxy_fcgi_module>
					<IfModule dir_module>
						DirectoryIndex index.php
					</IfModule>
					<FilesMatch \"\.(php)$\">
						SetHandler proxy:fcgi://127.0.0.1:9000
					</FilesMatch>
				</IfModule>" >> /usr/local/etc/apache24/modules.d/003_php-fpm.conf
				# Start services
				service apache24 restart
				service php-fpm start
			else
				echo "Invalid Apache HTTP socket selection."
			fi
	else
		echo "Invalid Apache HTTP MPM and socket selection. Apache HTTP has NOT been correctly configured to run PHP nor an MPM."
		echo "Please, manually review the MPM configuration in httpd.conf and verify any existing configuration in the modules.d directory."
	fi
}

config_php-fpm_for_nginx_socket () {
	if [ "$apache_installed" = true ]; then
		return 0
	elif [ "$nginx_installed" = true ]; then
		return 0
    elif [ "$webserver_choice" -eq 2 ]; then
		if [ "$nginx_socket_choice" -eq 1 ]; then
			pkg install -y php${php_version}-extensions
			sed -i -e '/9000/s/127.0.0.1:9000/\/var\/run\/php-fpm.sock/' /usr/local/etc/php-fpm.d/www.conf
			sed -i -e '/listen.owner/s/;listen.owner/listen.owner/' /usr/local/etc/php-fpm.d/www.conf
			sed -i -e '/listen.group/s/;listen.group/listen.group/' /usr/local/etc/php-fpm.d/www.conf
			sed -i -e '/listen.mode/s/;listen.mode/listen.mode/' /usr/local/etc/php-fpm.d/www.conf
			sysrc php_fpm_enable="YES"
			service php_fpm start
		elif [ "$nginx_socket_choice" -eq 2 ]; then
			pkg install -y php${php_version}-extensions 
			sysrc php_fpm_enable="YES"
			service php_fpm start
		else
			echo "Something went wrong configuring PHP-FPM"
		fi
	else
		echo "Something went wrong configuring PHP-FPM on NGINX"
	fi

}

reconfigure_php_ini () {
if [ "$reconf_php_ini" -eq 1 ]; then
	echo "Nothing to do with php.ini"
elif [ "$reconf_php_ini" -eq 2 ]; then
	cp /usr/local/etc/php.ini-development /usr/local/etc/php.ini
	echo "PHP.ini for development has been configured."
elif [ "$reconf_php_ini" -eq 3 ]; then
	cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
	echo "PHP.ini for production has been configured."
else
	echo "Invalid selection for PHP.ini configuration."
	echo "Manually review the existance of /usr/local/etc/php.ini"
fi
}

enable_pf_firewall() {

    if [ "$ipfw_configured" = true ] && [ "$pf_configured" = false ] && [ "$ipfilter_configured" = false ]; then
        return 0
    elif [ "$ipfw_configured" = false ] && [ "$pf_configured" = true ] && [ "$ipfilter_configured" = false ]; then
        return 0
    elif [ "$ipfw_configured" = false ] && [ "$pf_configured" = false ] && [ "$ipfilter_configured" = true ]; then
        return 0
	elif [ "$wants_firewall" -eq 2 ]; then
		return 0
	elif [ "$pf_configured" = false ] && [ "$firewall_type_selection" -eq 2 ]; then
		echo "Since the PF firewall was selected, it needs service activation."
		echo "Be aware SSH connections will be momentarily interrupted, logging users out."
		echo "Choose to start the PF firewall now or do it manually later"
		echo "1) YES, start the PF firewall right now"
		echo "2) NO, do NOT start the PF firewall now, I will enable it later by issuing the command \"service pf start\"."
		read -p "Enter the corresponding number: " pf_start
			if [ "$pf_start" -eq 1 ]; then
					service pf start
			elif [ "$pf_start" -eq 2 ]; then
					echo "PF won't be started as selected. Mind to do it manually when appropiate."
			else
					echo "Invalid pf service start selection."
			fi
	else
		return 0
	fi

}

# Main execution logic

beta_question

# Step 1: Verify Installed Software
check_ipfw_firewall
check_pf_firewall
check_ipfilter_firewall
check_apache
check_nginx
check_mysql
check_mariadb
check_php
check_php_ini

# Step 2: Ask for User Input
select_firewall
select_web_server
select_apache_mpm
select_nginx_php-fpm_socket
select_database_server
select_php_version
select_php_ini
select_apache_socket
select_php_ini_reconf

# Step 3: Install Software Based on User Input
install_firewall
install_web_server
config_nginx_php-fpm
install_database_server
database_secure_install
install_php_version
config_php_ini
config_apache_http_plus_php
config_php-fpm_for_nginx_socket
reconfigure_php_ini

echo "Installation process completed."
enable_pf_firewall
