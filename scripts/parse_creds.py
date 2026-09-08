import os
import json
import textwrap
import re

def write_readme(dir: str):
    README = textwrap.dedent("""
        In the previous years, a lot of students used Visual Studio Code to access the VMs. One plugin in it used a lot of resources causing crashes while not adding any functionality they used. Here is an article on how to disable it:
        https://medium.com/good-robot/use-visual-studio-code-remote-ssh-sftp-without-crashing-your-server-a1dc2ef0936d
        [disabling: @builtin TypeScript]

        Different from previous years, you now have access to the AWS console, which allows you to interact with your own virtual machine and perform actions such as [start, stop, reboot and hibernate]. To do so, you will have to log into AWS ([link](https://sue-aws-student-01.signin.aws.amazon.com/console)). You can use the username and password provided in the `aws` file in your client's credentials directory. Upon logging in, you should be able to see all Virtual Machines that have been allocated for the purpose of this course, but you should only be able to interact with your own Virtual Machine. 

        If they don't use the link, they can connect using the following Account Alias: "" [this is the same for everyone, see the screenshot here]. On first log in they will have to replace their password. In case it's needed we can do a reset. 
    """).strip()
    with open(f"{dir}/README.md", "w") as f:
        f.write(README)

def write_aws(dir: str, username: str, password: str, instance: str):
    def aws_template(username: str, password: str, instance: str):
        return textwrap.dedent(f"""
            Account Alias: sue-aws-student-01
            IAM username: {username}
            Password: {password}
            Instance: {instance}
        """).strip()

    content = aws_template(username, password, instance)
    with open(f"{dir}/aws", "w") as f:
        f.write(content)

def write_ssh_config(dir: str, vm_id: int, ip: str, is_group: bool):
    def ssh_config(vm_id: int, ip: str, is_group: bool):
        if is_group:
            host = f"group{vm_id}"
            identity_file = f"~/.ssh/group{vm_id}_rsa"
        else: 
            host = f"client{vm_id}"
            identity_file = f"~/.ssh/client{vm_id}_rsa"

        return textwrap.dedent(f"""
            Host {host}
              Port 22
              IdentitiesOnly yes
              User ubuntu
              HostName {ip}
              IdentityFile {identity_file}
        """).strip()

    content = ssh_config(vm_id, ip, is_group)
    with open(f"{dir}/ssh_config", "w") as f:
        f.write(content)

def write_rsa(filepath: str, content: str):
    with open(filepath, "w") as f:
        f.write(content)

def main(is_group: bool):
    with open("./credentials/students.json") as f:
        credentials = json.load(f)

    for cred in credentials: 
        print(f'=== {cred["instance_name"]} ===')
        vm = re.match(r"student-(\d+)", cred["instance_name"]).group(1)
        vm = int(vm)
        cec_id = f"group{vm}" if is_group else f"client{vm}"
        creds_dir = f"./creds/groups/group{vm}" if is_group else f"./creds/clients/client{vm}"
        if not os.path.isdir(creds_dir):
            continue
        write_readme(creds_dir)
        write_aws(creds_dir, cred["aws_iam_user"], cred["aws_console_password"], cred["instance_name"])
        write_ssh_config(creds_dir, vm, cred["public_ip"], is_group)
        write_rsa(f"{creds_dir}/{cec_id}_rsa", cred["ssh_private_key"])

main(False)
