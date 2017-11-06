#!/usr/local/bin/python3.6
def convert_to_fahrenheit():
    celsius = float(input("Enter temperature is celsius: "))
    fahrenheit = ((9 / 5) * celsius + 32)
    fahrenheit = round(fahrenheit, 2)
    print(celsius, "degree celsius is ", fahrenheit,  "fahrenheit")


def convert_to_celsius():
    fahrenheit = float(input("Enter temperature in fahrenheit:"))
    celsius = ((fahrenheit - 32) * 5) / 9
    celsius = round(celsius, 2)
    print(fahrenheit, "degree fahrenheit is", celsius, "celsius.")


if __name__ == "__main__":

    print("1. Convert to celsius: ")
    print("2. Convert to fahrenheit: ")
    choice = input("Select your choice: ")
    if choice == "1":
        convert_to_celsius()
    elif choice == "2":
        convert_to_fahrenheit()
    else:
        print("You didn't select any of the above.")





