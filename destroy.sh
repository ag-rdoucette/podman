#!/bin/bash

# Shut down the containers
echo "============================="
echo "Trashing containers."
echo "============================="
podman stop scim redis

# Remove the containers
echo "=========================="
echo "Deleting containers."
echo "=========================="
podman rm scim redis

# Remove the pods if they exist
echo "======================="
echo "Deleting pods."
echo "======================="
podman pod rm -f scim redis

# Remove the secrets
echo "=========================="
echo "Deleting secrets."
echo "=========================="
podman secret rm workspace-credentials workspace-settings scimsession

# Remove the network if it exists
echo "==========================="
echo "Deleting op-scim network."
echo "==========================="
podman network rm op-scim

# Remove images
echo "========================="
echo "Deleting images."
echo "========================="
podman rmi 1password/scim:v2.9.5 redis:latest

echo "================="
echo "All done, b'y."
echo "================="
