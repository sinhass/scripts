#!/usr/bin/python3
import os, re


ps aux | awk '{if ($1 == "lisiang") print $2}'


print("This tool will kill all the process of the us")
server_name = input("Type the servername here:")
user_name = input("Type the user name:")
