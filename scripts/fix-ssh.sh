#!/bin/bash
# Script to fix Semaphore SSH authentication issues

echo "=== Semaphore SSH Fix Script ==="

# 1. Find the running Semaphore container
CONTAINER_ID=$(docker ps | grep semaphoreui/semaphore | awk '{print $1}')

if [ -z "$CONTAINER_ID" ]; then
    echo "Error: Semaphore container not found"
    exit 1
fi

echo "Found Semaphore container: $CONTAINER_ID"

# 2. Create SSH directory in container
echo "Creating SSH directory in container..."
docker exec $CONTAINER_ID mkdir -p /home/semaphore/.ssh
docker exec $CONTAINER_ID chown semaphore:semaphore /home/semaphore/.ssh
docker exec $CONTAINER_ID chmod 700 /home/semaphore/.ssh

# 3. Create empty known_hosts file (critical for OCI)
echo "Creating known_hosts file..."
docker exec $CONTAINER_ID touch /home/semaphore/.ssh/known_hosts
docker exec $CONTAINER_ID chown semaphore:semaphore /home/semaphore/.ssh/known_hosts
docker exec $CONTAINER_ID chmod 644 /home/semaphore/.ssh/known_hosts

# 4. Add OCI host keys to known_hosts (replace IPs with your actual OCI instance IPs)
echo "Add your OCI instance IP addresses to known_hosts manually:"
echo "docker exec -it $CONTAINER_ID ssh-keyscan -H YOUR_OCI_INSTANCE_IP >> /home/semaphore/.ssh/known_hosts"

echo "=== SSH Fix Complete ==="
echo "Now manually add your OCI instance IPs using the command above"
