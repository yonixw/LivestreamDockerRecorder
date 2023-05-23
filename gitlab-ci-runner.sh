echo "[*] Cheking git..."

git status -s | grep -E '.'
NO_CHANGES=$?

if [ $NO_CHANGES -eq 0 ]
then
    echo "[*] [WARN] Not all files commited! They will be ignored..."
fi

echo "[*] Setting up..."

jobs=${@} # use space seperated params
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


# Bug fix, see: https://stackoverflow.com/a/65920577/1997873
docker exec \
    gitlab-runner \
    bash -c 'git config --global --add safe.directory "*"'

echo "[*] Running jobs(s): ${jobs[*]}"

for job in ${jobs[*]};
do
        echo "[*] -------------"
        echo "[*] Job=$job"
        docker exec \
            -w $PWD_RESOLVED \
            -it gitlab-runner \
            gitlab-runner exec \
            docker $job \
            --cache-dir /cache \
            --docker-cache-dir /cache \
            --docker-volumes $PWD_RESOLVED/gitlab-runner-cache:/cache/ \
            --docker-volumes '/var/run/docker.sock:/var/run/docker.sock' \
            --env ROOT_PWD=$PWD_RESOLVED \
        | sed -e "s/^/[$job] /;"
done


echo "[*] Stopping runner..."

docker stop gitlab-runner
docker rm gitlab-runner

echo "[*] Done!"
