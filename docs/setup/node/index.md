---
title: Join Nodes
layout: scrollspy
description: |
    How to start the master Node 
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
