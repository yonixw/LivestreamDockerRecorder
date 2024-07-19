#!/bin/bash

# Get a list of all servers
servers=$(hcloud server list -o noheader -o columns=name)

# Loop through the servers and delete them
for server in $servers; do
  echo "Deleting server: $server"
  hcloud server delete --confirm $server
done

echo "All servers deleted."
