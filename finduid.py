#!/usr/bin/python3
# Author : Siddhartha S Sinha
import pwd
import random
import os
import string
import datetime
import re

# PUT CLASSES HERE


class color:
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    DARKCYAN = '\033[36m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'


#  GLOBAL VARIABLES

date_to_use = datetime.datetime.now().strftime('%Y%m%d')
admin = 'itsupport@barefootnetworks.com'
admin1 = 'glen@barefootnetworks.com'
p4command = '/tools/perforce/2016.2/p4'
p4admin = 'ssinha'
hr_mail = 'hr@barefootnetworks.com'
radius_server = 'bfrad01.barefoot-int.lan'
vpn_server = 'openvpn.barefoot-int.lan'
radius_path = '/etc/raddb/mods-config/files/authorize'
vpn_group = '/etc/group'
run_from = 'bfsalt01'


if os.path.isfile('/root/scripts/temparea/p4template'):
    os.rename('/root/scripts/temparea/p4template', '/root/scripts/temparea/p4template' + date_to_use)


def generate_auto_pass():

    UPP = random.SystemRandom().choice(string.ascii_uppercase)
    LOW1 = random.SystemRandom().choice(string.ascii_lowercase)
    LOW2 = random.SystemRandom().choice(string.ascii_lowercase)
    LOW3 = random.SystemRandom().choice(string.ascii_lowercase)
    DIG1 = random.SystemRandom().choice(string.digits)
    DIG2 = random.SystemRandom().choice(string.digits)
    DIG3 = random.SystemRandom().choice(string.digits)
    SPEC = random.SystemRandom().choice('!@#$%^&*()')
    PWD = None
    PWD = UPP + LOW1 + LOW2 + LOW3 + DIG1 + DIG2 + DIG3 + SPEC
    PWD = ''.join(random.sample(PWD,len(PWD)))
    return PWD


def get_highest_uid():
    data = []
    all_user_data = pwd.getpwall()
    for u in all_user_data:
        data.append(u.pw_uid)
    data.sort()
    data.pop()
    highest_uid = data.pop() + 1
    return highest_uid


def collect_employee_name():

    first_name = input("Type first name:")
    first_name = first_name.lower()
    while not first_name:

        first_name = input("Type first name:")
        first_name = first_name.lower()

    middle_name = input("Type middle name(if any):")
    last_name = input("Type last name:")
    last_name = last_name.lower()
    while not last_name:
        last_name = input("Type last name:")
        last_name = last_name.lower()
    full_name = (first_name + ' ' + middle_name + ' ' + last_name)
    full_name = string.capwords(' '.join(full_name.split()))
    return full_name, first_name, last_name
    p4template = open('/root/scripts/temparea/p4template', 'w')
    p4template.write('Full Name:\t%s' % full_name)
    p4template.close()


def select_employee_type():

    employee_type = input('Type ft for Full Time employee and ct for contractors:')
    employee_type = employee_type.lower()
    while not (employee_type.lower() == 'ft' or employee_type == 'ct'):
        employee_type = input('Type ft for Full Time employee and ct for contractors:')
        employee_type = employee_type.lower()
    return employee_type


def select_team():
    print('Select the team.')
    team_list = {"Hardware\t\t": "hw", "Software\t\t": "sw",
                 "Customer Engineering\t": "cust",
                 "Sales\t\t\t": "sales", "Other Groups\t\t": "other"
                 }
    while True:
        print(color.RED,"Team Name \t\t Team ID",color.END)
        for c in team_list:
            print("{TeamName}: {team}".format(TeamName=c, team=color.BOLD + (team_list[c] + color.END)))
        try:
            employee_group = input('Type the appropriate team name from the above list:')
            os.system('clear')
        except ValueError:
            continue
        if employee_group in ('hw', 'sw', 'cust', 'sales', 'other'):
            employee_group = employee_group.lower()
        return employee_group


if __name__ == '__main__':
    all_name = collect_employee_name()
    full_name = (all_name[0])
    print(full_name)
    first_name = (all_name[1])
    print(first_name)
    last_name = (all_name[-1])
    print(last_name)
    employee_type = select_employee_type()
    print(employee_type)
    employee_team = select_team()
    print(employee_team)