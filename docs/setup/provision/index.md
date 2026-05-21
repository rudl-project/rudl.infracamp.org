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
export RUDL_DOWNLOAD_URL=https://raw.githubusercontent.com/rudl-project/rudl.infracamp.org/refs/heads/main/docs/setup/provision/script/
```

**Problem with vim on new Ubuntu 26.04:**

Copy n past issue with mouse support. Disable mouse support for vim:

```bash
update-alternatives --config editor  ## Set Edtior to vim.basic
echo "set mouse=" > ~/.vimrc           ## Disable mouse support for vim
```

3) Erstelle die [`server.env` Datei](script/server.env.txt) mit den notwendigen Umgebungsvariablen:

Entweder direkt datei erstellen oder mit curl herunterladen:

```bash
curl -fsSL ${RUDL_DOWNLOAD_URL}server.env.txt -o server.env
```

4) Run the cloud-init script:

```bash
curl -fsSL ${RUDL_DOWNLOAD_URL}cloud-init-ubuntu-26-04.yml -o cloud-init-tpl.yml
set -a && source server.env && set +a && envsubst < cloud-init-tpl.yml > cloud-init.yml

cloud-init clean --logs
cloud-init modules --file cloud-init.yml --mode=config
cloud-init modules --file cloud-init.yml --mode=final
cloud-init status
```
