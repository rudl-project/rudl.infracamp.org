---
title: Join Nodes
layout: scrollspy
description: |
    How to start the client Nodes including Setup for Nodes 
---

## Joining Nodes

SSH into the node system and run

```bash
cd /root/
cat <plainPassword> > node_client_secret
docker stack init
cat node_client_secret | docker secret create ingress1_client_secret -

curl -o rudl-node-stack.yml https://raw.githubusercontent.com/rudl-project/rudl.infracamp.org/main/docs/setup/master/rudl-node-stack.yml 
```



## Optimal Setup for Ubuntu 26.04

Base Install Ubuntu 26.04 - then login via root password.

Create a new User to login via ssh:

```bash
apt install vim
update-alternatives --config editor  ## Set Edtior to vim.basic
echo "set mouse=" > ~/.vimrc           ## Disable mouse support for vim
```

### Create new User and ssh login


```bash
sudo adduser $NEW_USER_NAME
sudo usermod -aG sudo $NEW_USER_NAME
```

Then add `[new_user_name] ALL=(ALL) NOPASSWD:ALL` to `visudo -f /etc/sudoers.d/nopasswd` to allow passwordless `sudo bash`

### Set the Hostname

Edit /etc/hosts and set the hostname and shortcut than run

```bash
hostnamectl set-hostname <new-fqdn>
```

### Allow SSH Public Key Login for User

Run and login to new maschine from your workstation to set the SSH Key. Make sure login and sudo bash works.

```bash
ssh-copy-id [new_user_name]@host
```

### Disable root and password ssh login

Edit /etc/ssh/sshd_config

```
[new_user_name] ALL=(ALL) NOPASSWD:ALL
```


### Disable SSH Root and Password login

```
sudo rm /etc/ssh/sshd_config.d/permit_root.conf
sudo bash -c 'cat > /etc/ssh/sshd_config.d/hardened.conf <<EOF
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
PermitEmptyPasswords no
MaxAuthTries 3
PerSourceMaxStartups 3
PerSourcePenalties authfail:300
EOF'
```


