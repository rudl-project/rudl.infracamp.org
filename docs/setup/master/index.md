---
title: Setup
layout: scrollspy
description: |
    How to start the master Node 
---

## Setting up the Master Node

To get Rudl up and running, you have to setup the manager cluster
your own. Afterwards, cluster setup will be only one line. But let's start:
  
***Prepare the server***
```bash
apt-get -y install curl pwgen
docker swarm init
```


***Create and register secrets***
```bash
ssh-keygen -f rudldb_ssh_key -t ed25519 -q -N ""
pwgen -s 128 1 > rudldb_vault_secret
cat rudldb_vault_secret | docker secret create rudldb_vault_secret -
cat rudldb_ssh_key | docker secret create rudldb_ssh_key -
curl -o 
```

***Create an empty repository***
Create an empty private repository on gitlab, github, bitbucket or your
own git server. Specify to **create a Readme** (so it will create a main or master
branch as well):

![](github-create-repo.png)

Export your public ssh key:
```
cat rudldb_ssh_key.pub
```

and add it as as deploy key **including write privileges**:

![](github-set-deploy-key.png)

***Copy the ssh clone url***

