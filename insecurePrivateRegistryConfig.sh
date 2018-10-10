#!/bin/bash

sudo -- sh -c "echo '172.31.5.134 registry' >> /etc/hosts"

sudo -- sh -c "echo '{ \"insecure-registries\" : [ \"registry:443\" ] }' >> /etc/docker/daemon.json"
sudo -- sh -c "systemctl daemon-reload; systemctl restart docker"
