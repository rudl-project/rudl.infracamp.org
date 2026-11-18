---
title: Join Nodes
layout: scrollspy
description: |
    How to start the client Nodes including Setup for Nodes 
---

[See: How to provision the Nodes](../provision/index.md)

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


