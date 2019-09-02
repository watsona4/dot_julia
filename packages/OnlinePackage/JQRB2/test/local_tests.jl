repo_name = "Test41"
copy_package("JuliennedArrays", repo_name)

username = settings("username")
github_token = settings("github_token")
ssh_keygen_file = settings("ssh_keygen_file")
set_up(username, github_token, ssh_keygen_file = ssh_keygen_file)

github, travis = put_online(repo_name)
delete(github)
