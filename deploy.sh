#!/bin/bash

# Here's a fucntion to clean up a mess.
cleanup() {
  echo "======================"
  echo "Cleaning up."
  echo "======================"
  podman stop scim redis
  podman rm scim redis
  podman pod rm -f scim redis
  podman secret rm workspace-credentials 
  podman secret	rm workspace-settings 
  podman secret	rm scimsession
  podman network rm op-scim
  podman rmi 1password/scim:v2.9.5 redis:latest
}

# Here's a function to roll-back and exit.
rollback() {
  echo "============================"
  echo "Deployment failed, rolling back."
  echo "============================"
  cleanup
  echo "===================="
  echo "Rollback complete."
  echo "===================="
  exit 1
}

# A Function to deploy!
deploy() {
  echo "======================"
  echo "Starting deployment."
  echo "======================"

  # Stop and remove existing containers if any exist
  podman stop scim redis
  podman rm scim redis

  # Remove existing pods
  echo "=========================="
  echo "Removing existing pods for you."
  echo "=========================="
  podman pod rm -f scim redis

  # Create network if it doesn't exist!
  podman network exists op-scim || podman network create op-scim

  # Create secrets so this thing works!
  echo "======================"
  echo "Creating secrets."
  echo "======================"
  # podman secret create workspace-credentials ./workspace-credentials.json || return 1
  # podman secret create workspace-settings ./workspace-settings.json || return 1
  podman secret create scimsession ./scimsession || return 1

  # Verify secrets are created.
  echo "=========================="
  echo "Checking on the secrets."
  echo "=========================="
  podman secret ls || return 1

  # Deploying Redis with environment variables.
  podman run -d \
    --name redis \
    --net op-scim \
    --env-file redis.env \
    --restart always \
    redis:latest || return 1

  # Deploy SCIM with secrets and environment variables.
  podman run -d \
    --name scim \
    --net op-scim \
    -p 443:8443 \
    # - 80:8080 \
    # - 3002:3002 \
    --env-file scim.env \
    --restart always \
    # --secret workspace-credentials \
    # --secret workspace-settings \
    --secret scimsession \
    1password/scim:v2.9.5 || return 1

  echo "====================="
  echo "Hazzah! Deployment complete."
  echo "====================="

  # Check container status
  echo "=========================="
  echo "Checking containers..."
  echo "=========================="
  podman ps -a || return 1

  # Fetch logs for SCIM container
  if podman ps -a --filter "name=scim" --format "{{.Names}}" | grep -q "scim"; then
    echo "==============================="
    echo "Viewing SCIM container logs just to make sure:"
    echo "==============================="
    podman logs --tail 50 scim || return 1
  else
    echo "==================================="
    echo "Error: No SCIM container found, backing out!"
    echo "==================================="
    return 1
  fi

  return 0
}

# Try to deploy, if it fails, clean up and try once more
deploy || {
  echo "============================================"
  echo "Deployment #1 failed, cleaning up and retrying."
  echo "============================================"
  cleanup
  deploy || {
    echo "============================================"
    echo "Deployment #2 failed, final cleanup then contact Support!."
    echo "============================================"
    cleanup
    exit 1
  }
}

echo "======================="
echo "Deployment: Great Success!"
echo "======================="
