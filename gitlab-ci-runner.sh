echo "[*] Setting up..."

stages=${@} # use space seperated params
PWD_RESOLVED="$(pwd -P)"
mkdir -p $PWD_RESOLVED/gitlab-runner-cache

echo "[*] Starting runner..."

docker run -d --name gitlab-runner --restart always \
    --network host \
    -v $PWD_RESOLVED/gitlab-runner-cache:/cache/ \
    -v $PWD_RESOLVED:$PWD_RESOLVED \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --workdir $PWD_RESOLVED \
    gitlab/gitlab-runner:latest

echo "[*] Running jobs(s): ${stages[*]}"

for stage in ${stages[*]};
do
        echo "[*] Stage=$stage"
        docker exec -w $PWD_RESOLVED -it gitlab-runner \
            gitlab-runner exec docker $stage --cache-dir /cache \
            --docker-cache-dir /cache --docker-volumes $PWD_RESOLVED/gitlab-runner-cache:/cache/ \
            --docker-volumes '/var/run/docker.sock:/var/run/docker.sock' --env ROOT_PWD=$PWD_RESOLVED 
done


echo "[*] Stopping runner..."

docker stop gitlab-runner
docker rm gitlab-runner

echo "[*] Done!"
