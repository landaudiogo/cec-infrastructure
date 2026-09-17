import os
import stat
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

def write_ssh_config(
    dir: str,
    vm_id: int,
    ip: str,
    host: str,
    identity_file: str
):
    def ssh_config(ip: str):
        # if is_group:
        #     host = f"group{vm_id}"
        #     identity_file = f"~/.ssh/group{vm_id}_rsa"
        # else: 
        #     host = f"client{vm_id}"
        #     identity_file = f"~/.ssh/client{vm_id}_rsa"

        return textwrap.dedent(f"""
            Host {host}
              Port 22
              IdentitiesOnly yes
              User ubuntu
              HostName {ip}
              IdentityFile {identity_file}
        """).strip()

    content = ssh_config(ip)
    with open(f"{dir}/ssh_config", "w") as f:
        f.write(content)

def write_rsa(filepath: str, content: str):
    if os.path.exists(filepath):
        os.remove(filepath)

    with open(filepath, "w") as f:
        f.write(content)
    os.chmod(filepath, stat.S_IRUSR)

def parse_group_credentials(credentials_path, creds_dir):
    with open(credentials_path) as f:
        credentials = json.load(f)

    for cred in credentials: 
        print(f'=== {cred["instance_name"]} ===')
        vm = re.match(r"group-(\d+)", cred["instance_name"]).group(1)
        vm = int(vm)
        cec_id = f"group{vm}"
        cred_dir = f"{creds_dir}/groups/{cec_id}"
        if not os.path.isdir(cred_dir):
            continue
        write_readme(cred_dir)
        write_aws(cred_dir, cred["aws_iam_user"], cred["aws_console_password"], cred["instance_name"])
        write_ssh_config(cred_dir, vm, cred["public_ip"], cec_id, f"~/.ssh/{cec_id}_rsa")
        write_rsa(f"{cred_dir}/{cec_id}_rsa", cred["ssh_private_key"])

def parse_student_credentials(credentials_path, creds_dir):
    with open(credentials_path) as f:
        credentials = json.load(f)

    for cred in credentials: 
        print(f'=== {cred["instance_name"]} ===')
        vm = re.match(r"student-(\d+)", cred["instance_name"]).group(1)
        vm = int(vm)
        cec_id = f"client{vm}"
        cred_dir = f"{creds_dir}/clients/{cec_id}"
        if not os.path.isdir(cred_dir):
            continue
        write_readme(cred_dir)
        write_aws(cred_dir, cred["aws_iam_user"], cred["aws_console_password"], cred["instance_name"])
        write_ssh_config(cred_dir, vm, cred["public_ip"], cec_id, f"~/.ssh/{cec_id}_rsa")
        write_rsa(f"{cred_dir}/{cec_id}_rsa", cred["ssh_private_key"])

def main():
    creds_dir = os.getenv("CREDS_DIR")
    if creds_dir is None:
        raise Exception("environment variable CREDS_DIR missing")

    student_credentials_path = os.getenv("STUDENT_CREDENTIALS")
    if student_credentials_path is None:
        raise Exception("environment variable STUDENT_CREDENTIALS missing")

    group_credentials_path = os.getenv("GROUP_CREDENTIALS")
    if group_credentials_path is None:
        raise Exception("environment variable GROUP_CREDENTIALS missing")

    parse_student_credentials(student_credentials_path, creds_dir)
    parse_group_credentials(group_credentials_path, creds_dir)

if __name__ == "__main__":
    main()
