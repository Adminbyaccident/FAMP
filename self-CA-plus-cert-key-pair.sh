#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: self-CA-plus-cert-key-pair.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 02-08-2022
# SET FOR: Dev
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 12/13
#
# PURPOSE: This script generates a self attributed Certificate Authority (CA) plus generates intermediate signing keys and derivative
# certificate and key pair for use in web servers or establish TLS communications between parties in a server/client configuration.
#
# WARNING: For personal, non production, consumption only.
# Use this as a one shot script and operate the CA knowing what your doing. You should already be aware the CA and the intermediate
# certs and keys plus the dervicatives shouldn't be on the same box. For certificate and key paris generation at a scale please don't 
# use this script and use something similar to easy-rsa.
#
# REV LIST:
# DATE: 02-08-2022
# BY: ALBERT VALBUENA
# MODIFICATION: 02-08-2022
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Message for the user before anything is done
echo "Make sure you have set this script with the correct -subj content, such as country, state, city, organization name, common name and email before its first use."

echo "In other words, don't use this script blindly without changing the -subj content first. Press Ctrl C to cancel this operation if in need. You have 10 seconds."

sleep 30

# Create the CA directory
mkdir /usr/local/tls

# Generate the CA primary key
echo "Generating the CA primary key"
openssl genrsa 2048 > /usr/local/tls/ca-key.pem

# Generate the CA certificate from the primary key
echo "Producing the primary certificate with the CA's key."
openssl req -new -x509 -nodes -days 730 -key /usr/local/tls/ca-key.pem -out /usr/local/tls/ca-cert.pem -subj "/C=US/ST=State/L=City/O=Adminbyaccident Ltd/CN=example.com/emailAddress=youremail@anymail.com"

# Generate the server's key and certificate pair
echo "Generating serve's key and certificate pair."

# 1.- Generate a new key for the server plus a certificate request
openssl req -newkey rsa:2048 -days 730 -nodes -keyout /usr/local/tls/server-key.pem -out /usr/local/tls/server-req.pem -subj "/C=US/ST=State/L=City/O=Adminbyaccident Ltd/CN=example.com/emailAddress=youremail@anymail.com"

# 2.- Strip out the passphrase within the key
openssl rsa -in /usr/local/tls/server-key.pem -out /usr/local/tls/server-key.pem

# 3.- Generate the server's certificate via the x509 protocol from the cert request plus the server's key with a serial number.
openssl x509 -req -in /usr/local/tls/server-req.pem -days 730 -CA /usr/local/tls/ca-cert.pem -CAkey /usr/local/tls/ca-key.pem -set_serial 01 -out /usr/local/tls/server-cert.pem

echo "Server's certificate and key pair have been generated."

# Generate the client's certificate and key pairs
echo "Generating client's key and certificate pair."

# 1.- Generate a new key for the client plus a certificate request
openssl req -newkey rsa:2048 -days 730 -nodes -keyout /usr/local/tls/client-key.pem -out /usr/local/tls/client-req.pem -subj "/C=US/ST=State/L=City/O=Adminbyaccident Ltd/CN=example.com/emailAddress=youremail@anymail.com"

# 2.- Strip out the passphrase within the key
openssl rsa -in /usr/local/tls/client-key.pem -out /usr/local/tls/client-key.pem

# 3.- Generate the client's certificate via the x509 protocol from the cert request plus the client's key with a serial number.
openssl x509 -req -in /usr/local/tls/client-req.pem -days 730 -CA /usr/local/tls/ca-cert.pem -CAkey /usr/local/tls/ca-key.pem -set_serial 01 -out /usr/local/tls/client-cert.pem

echo "Client's certificate and key pair have been generated."

# Check the integrity of the final certificate's with the CA's primary certificate
echo "Verifying the final certificates for the client and server are intact derivatives from the CA's certificate"
openssl verify -CAfile /usr/local/tls/ca-cert.pem /usr/local/tls/server-cert.pem /usr/local/tls/client-cert.pem

echo "If the check response was a pair of OKs, you're done. If otherwise check what went wrong and start it all over again."
