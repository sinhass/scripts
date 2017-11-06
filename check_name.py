import re, string


def get_employee_name():

    first_name = str.capitalize((input('Enter First Name(no space allowed):')))
    if re.search(r'[\s]', first_name):
        print("No spaces please.")
        first_name = str.capitalize((input('Enter First Name(no space allowed):')))


    middle_name = str.capitalize(input('Enter middle name(if any or just hit enter:)'))


    last_name = str.capitalize(input('Enter Last Name(no space allowed):'))
    if re.search(r'[\s]', last_name):
        print("No spaces please.")
        last_name = str.capitalize(input('Enter Last Name(no space allowed):'))


    return [first_name, middle_name, last_name]

if __name__ == "__main__":
    first_name, middle_name, last_name = get_employee_name()
#    print('Full Name:{} {} {}'.format(first_name, middle_name, last_name))
    full_name = first_name + ' ' + middle_name + ' ' + last_name












