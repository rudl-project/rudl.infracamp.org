---
title: Join Nodes
layout: scrollspy
description: |
    How to start the client Nodes including Setup for Nodes 
---

[See: How to provision the Nodes](../provision/index.md)

For a node that does not expose public services itself, use the following firewall settings in `server.env`:

```bash
PROTECTED_PORTS_TCP="22"
PROTECTED_SOURCE_IPS="*" # Replace with one or more trusted IPv4/IPv6 addresses
OPEN_PORTS_TCP=""
OPEN_PORTS_UDP=""
```

For example, restrict SSH to multiple trusted IPv4 and IPv6 addresses with:

```bash
PROTECTED_SOURCE_IPS="203.0.113.10,198.51.100.7,2001:db8::10"
```

## Joining Nodes

SSH into the node system and run

```bash
cd /root/
cat <plainPassword> > node_client_secret
docker swarm init
cat node_client_secret | docker secret create node_client_secret -

curl -o rudl-node-stack.yml https://raw.githubusercontent.com/rudl-project/rudl.infracamp.org/main/docs/setup/node/rudl-node-stack.yml 
```

Edit the rudl-node-stack.yml file

Then run the stack

```bash
docker stack deploy -c rudl-node-stack.yml rudl
```


