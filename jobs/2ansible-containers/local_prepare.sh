echo IP=$IP
echo ANSIBLE_IMAGE=$ANSIBLE_IMAGE #from .gitlab-ci-local-env

# Create random pass for VNC
export PASS=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
echo VNC_PASSWD=$PASS > .remote.env
cat .remote.env

# Put image in docker-compose tmplate
cat docker-compose.tmpl.yml |  sed -e "s|var_image|$ANSIBLE_IMAGE|g"  \
    > ./docker-compose.yml


# Prepare url to echo later:
echo "http://$IP:15901/?password=$PASS > output.txt
