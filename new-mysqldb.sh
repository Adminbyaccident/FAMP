#!/bin/sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Create a database inside MySQL version 8 using Expect

# Install Expect
pkg install -y expect

# As if we were before the keyboard

NEW_DATABASE=$(expect -c "
set timeout 10
spawn mysql -u root -p
expect \"Enter password:\"
send \"albertXP-24\r\"
expect \"root@localhost \[(none)\]>\"
send \"CREATE DATABASE ballanga;\r\"
expect \"root@localhost \[(none)\]>\"
send \"CREATE USER 'xava'@'localhost' IDENTIFIED WITH mysql_native_password BY 'cavallXP-35';\r\"
expect \"root@localhost \[(none)\]>\"
send \"GRANT ALL PRIVILEGES ON ballanga.* TO 'xava'@'localhost';\r\"
expect \"root@localhost \[(none)\]>\"
send \"FLUSH PRIVILEGES;\r\"
expect \"root@localhost \[(none)\]>\"
send \"exit\r\"
expect eof
")

echo "$NEW_DATABASE"

# Remove Expect if it's no longer needed
# pkg remove -y expect tcl86
