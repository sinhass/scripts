from github import Github
import getpass

# First create a Github instance:
user_name = input("Type your github user name:")
password = getpass.getpass("Type your github password:")
g = Github("user_name", "pass_word")

# Then play with your Github objects:
for repo in g.get_user().get_repos():
    print(repo.name)
