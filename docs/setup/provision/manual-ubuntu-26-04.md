---
title: Provision Nodes
layout: scrollspy
description: |
    How to start the client Nodes including Setup for Nodes 
---





### Optimal Setup for Ubuntu 26.04

Base Install Ubuntu 26.04 - then login via root password.

Create a new User to login via ssh:

```bash
apt install vim
update-alternatives --config editor  ## Set Edtior to vim.basic
echo "set mouse=" > ~/.vimrc           ## Disable mouse support for vim
```

#### Create new User and ssh login


```bash
sudo adduser $NEW_USER_NAME
sudo usermod -aG sudo $NEW_USER_NAME
```

Then add `[new_user_name] ALL=(ALL) NOPASSWD:ALL` to `visudo -f /etc/sudoers.d/nopasswd` to allow passwordless `sudo bash`

#### Set the Hostname

Edit /etc/hosts and set the hostname and shortcut than run

```bash
hostnamectl set-hostname <new-fqdn>
```

If you want to server DNS Server on the host, you have to disable the Stub-Listener:

```
# /etc/systemd/resolved.conf
[Resolve]
DNSStubListener=no
```

Danach Netplan Nameserver Updaten in `/etc/netplan/00-installer-config.yaml`. **Achtung: Keine Tabs benutzen!** Config mit `sudo netplan try` testen!


#### Allow SSH Public Key Login for User

Run and login to new maschine from your workstation to set the SSH Key. Make sure login and sudo bash works.

```bash
ssh-copy-id [new_user_name]@host
```

#### Disable root and password ssh login

Edit /etc/ssh/sshd_config

```
[new_user_name] ALL=(ALL) NOPASSWD:ALL
```


#### Disable SSH Root and Password login

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
Banner none
DebianBanner no
EOF'
```



#### Configure Firewall

Using nftables add [nftables.conf](nftables.conf.txt) to `/etc/nftables.conf` and aktivate
the Firewall by running 

```bash
sudo systemctl enable nftables
sudo nft -f /etc/nftables.conf
sudo nft list ruleset
```

#### Configure Cronjobs to cleanup stuff

```bash
echo '0 3 * * * root /usr/bin/docker system prune -af >/var/log/docker-prune.log 2>&1' | sudo tee /etc/cron.d/docker-prune
```


#### Unattended Updates aktivieren

```bash
sudo apt install unattended-upgrades apt-listchanges
sudo dpkg-reconfigure unattended-upgrades
```
Then edit `/etc/apt/apt.conf.d/50unattended-upgrades` and add your e-Mail Address



