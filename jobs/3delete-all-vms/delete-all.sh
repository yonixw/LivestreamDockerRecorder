#!/bin/bash

# Get a list of all servers
servers=$(hcloud server list -o noheader -o columns=name)

# Loop through the servers and delete them
for server in $servers; do
  echo "Deleting server: $server"
  hcloud server delete --confirm $server
done

echo "All servers deleted."

# Get a list of all volumes
volumes=$(hcloud volume list -o noheader -o columns=name)

# Loop through the volumes and delete them
for volume in $volumes; do
  echo "Deleting volume: $volume"
  hcloud volume delete --confirm $volume
done

echo "All volumes deleted."

# Get a list of all SSH keys
ssh_keys=$(hcloud ssh-key list -o noheader -o columns=name)

# Loop through the SSH keys and delete them
for ssh_key in $ssh_keys; do
  echo "Deleting SSH key: $ssh_key"
  hcloud ssh-key delete --confirm $ssh_key
done

echo "All SSH keys deleted."
