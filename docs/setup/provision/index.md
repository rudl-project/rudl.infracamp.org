---
title: Provision Nodes
layout: scrollspy
description: |
    How to start the client Nodes including Setup for Nodes 
---

## Provisioning Nodes

To provision the nodes, we provide a pure Bash provisioning script. The [hard manual way is documented here](manual-ubuntu-26-04).

**Compatibility:** currently only **Ubuntu 26.04** is supported by the provisioning script.

We also keep a [cloud-init.yml](script/cloud-init-ubuntu-26-04.yml) template in this directory, but the recommended setup flow is the Bash script below.

## Use the Provision Script

Use [`rudl-provision-maschine.sh`](script/rudl-provision-maschine.sh) to provision the machine directly on the server without running cloud-init.

### Step-by-Step Instructions

1) Login as `root` to your new server.
2) Go to `/root` and run:

```bash
apt-get update
apt-get install -y curl vim lsb-release
export RUDL_DOWNLOAD_URL=https://raw.githubusercontent.com/rudl-project/rudl.infracamp.org/refs/heads/main/docs/setup/provision/script/
```

**Problem with vim on new Ubuntu 26.04:**

Copy n paste issue with mouse support. Disable mouse support for vim:

```bash
update-alternatives --config editor  ## Set Editor to vim.basic
echo "set mouse=" > ~/.vimrc        ## Disable mouse support for vim
```

3) Create the [`server.env` file](script/server.env.txt) with the required variables.

Download the template:

```bash
curl -fsSL ${RUDL_DOWNLOAD_URL}server.env.txt -o server.env
```

Important variables:

```bash
# Firewall
PROTECTED_PORTS_TCP="22"
PROTECTED_SOURCE_IPS="*" ## Add ipv4 or ipv6 adresses - komma separated list. Leave * for all sources.
OPEN_PORTS_TCP="80,443"
OPEN_PORTS_UDP=""

# DNS
DISABLE_SYSTEMD_RESOLVED_STUB="false"
```

Notes:
- `PROTECTED_PORTS_TCP` contains TCP ports that are only accessible from `PROTECTED_SOURCE_IPS`. The template puts SSH port `22` here.
- `PROTECTED_SOURCE_IPS="*"` (the default) allows all IPv4 and IPv6 sources. To restrict access, use one address or a comma-separated list. IPv4 and IPv6 can be mixed:

  ```bash
  PROTECTED_SOURCE_IPS="203.0.113.10"
  PROTECTED_SOURCE_IPS="203.0.113.10,198.51.100.7"
  PROTECTED_SOURCE_IPS="2001:db8::10"
  PROTECTED_SOURCE_IPS="203.0.113.10,2001:db8::10,2001:db8::20"
  ```

- CIDR networks such as `203.0.113.0/24` and `2001:db8::/64` are also accepted.
- When using a VPN with a fixed IPv4 address in `PROTECTED_SOURCE_IPS`, you may need to invoke SSH with `ssh -4 user@host`. This forces IPv4 and ensures the connection uses the permitted VPN route instead of a direct IPv6 connection.
- Leave `PROTECTED_PORTS_TCP`, `OPEN_PORTS_TCP`, or `OPEN_PORTS_UDP` empty (`""`) if no ports should be opened by that setting.
- If a port list is empty, the corresponding nftables `dport { ... }` rule is not written.
- Public ports in `OPEN_PORTS_TCP` and `OPEN_PORTS_UDP` are reachable from every source address.
- If you want to run your own DNS service on the host, usually open port `53` for both TCP and UDP.
- **Warning:** if you set `DISABLE_SYSTEMD_RESOLVED_STUB="true"`, you must provide working nameservers in your netplan configuration, otherwise DNS resolution may stop working.

4) Download the provisioning script and run it:

```bash
curl -fsSL ${RUDL_DOWNLOAD_URL}rudl-provision-maschine.sh -o rudl-provision-maschine.sh
chmod +x rudl-provision-maschine.sh
./rudl-provision-maschine.sh ./server.env
```

For debugging:

```bash
./rudl-provision-maschine.sh ./server.env --debug
```

What the script does:
- installs required packages
- creates the admin user and SSH authorized key
- disables root SSH login and password SSH login
- configures nftables
- enables unattended upgrades
- optionally enables the Docker prune cron job
- optionally disables the systemd-resolved stub listener

The script does not edit netplan. If you disable the stub listener, configure nameservers manually in your netplan config first.
