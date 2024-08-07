#!/bin/bash

# Get a list of all servers
servers=$(./hcloud server list -o noheader -o columns=name)

# Loop through the servers and delete them
for server in $servers; do
  echo "Deleting server: $server"
  ./hcloud server delete $server
done

echo "All servers deleted."

# Get a list of all volumes
volumes=$(./hcloud volume list -o noheader -o columns=name)

# Loop through the volumes and delete them
for volume in $volumes; do
  echo "Deleting volume: $volume"
  ./hcloud volume delete $volume
done

echo "All volumes deleted."

./hcloud ssh-key list |  awk '{print $1, $2}' | grep '_deploy$' | awk '{print $1}' | xargs -n1 ./hcloud ssh-key delete 

echo "All SSH keys deleted."
