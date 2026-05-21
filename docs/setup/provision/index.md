---
title: Provision Nodes
layout: scrollspy
description: |
    How to start the client Nodes including Setup for Nodes 
---

## Provisioning Nodes

To provision the nodes, we provide a cloud-init script. The [hard manual way is documented here](manual-ubuntu-26-04).

### Cloud-Init

1) Login as root to your new server
2) Go to /root and run:

```bash
apt-get update
apt-get install -y curl cloud-init vim gettext-base
export RUDL_DOWNLOAD_URL=https://raw.githubusercontent.com/rudl-project/rudl.infracamp.org/main/docs/setup/provision/script/


curl -fsSL ${RUDL_DOWNLOAD_URL}server.env -o server.env
```

3) Edit the server.env file and set the following variables
4) Run the cloud-init script:

```bash
curl -fsSL ${RUDL_DOWNLOAD_URL}cloud-init-ubuntu-26-04.yml -o cloud-init.yml
envsubst < cloud-init.yml | cloud-init -d init -f -
```
