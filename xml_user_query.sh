#!/bin/sh
#
# Disclaimer: This script is provided as-is and are intended
#             to demonstrate the basic functionality of the XML
#             API. The script does not provide error handling
#             and should not be used in any live systems.
#
# Setup Notes:
# You must create a xml-api-server profile on the controller first, 
# then set it up in the default-xml-api profile and add it to 
# each wireless and wired aaa profile that you wish to control using 
# XML API. Incorrect setup is the major reason for XML API failure,
# specifically "<reason>unknown external agent</reason>" is seen
# after trying to send an XML API command. 
# 
# Monitor the incoming XML requests via "show aaa xml-api statistics"
#
# see setup_config.txt
#

# Configure your controller IP and secret here
# the secret must match the value in the xml-api-server
# profile configured as per above.
CONTROLLER="192.168.1.164"
SECRET="aruba123"

# Query the user info/packets/phy etc. using user_query
ACTION="user_query"

# IP of a valid and connected user, can be ipv4 or ipv6
USERIP="192.168.1.3"

# curl query - if you are using Windows, you can 
# install Cygwin curl to achieve the same function
#
# *NOTE* below we use the 'i' (insecure) flag
# in order to bypass the certificate checks for https
#
/usr/bin/curl -ikd "xml=<aruba command=\"$ACTION\"> \
                        <ipaddr>$USERIP</ipaddr>      \
                        <authentication>cleartext</authentication> \
                        <key>$SECRET</key> \
                        <version>1.0</version> \
                    </aruba>" \
               -H "Content-Type: text/xml" \
     https://$CONTROLLER/auth/command.xml
