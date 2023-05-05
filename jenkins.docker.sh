#!/bin/bash

# Docker Git:
# https://github.com/jenkinsci/jenkinsfile-runner

# Docker entrypoint script:
# https://github.com/jenkinsci/jenkinsfile-runner/blob/main/packaging/docker/unix/jenkinsfile-runner-launcher

DOCKER_IMAGE=ghcr.io/jenkinsci/jenkinsfile-runner:latest


sanity () {
    docker run --rm \
        -e "JAVA_OPTS=-Xms256m" \
        -v "$(pwd):/workspace" \
        bash \
            -c " \
            ls -lah /workspace && \
            cat /workspace/Jenkinsfile && \
            echo "$@" \
            "
}

bash () {
    docker run --rm \
        -e "JAVA_OPTS=-Xms256m" \
        -v "$(pwd)/Jenkinsfile:/workspace/Jenkinsfile" \
        -it \
        --entrypoint bash \
        $DOCKER_IMAGE
}


base () {
    echo "Params: $@"
    docker run --rm \
        -e "JAVA_OPTS=-Xms256m" \
        -v "$(pwd):/workspace" \
        $DOCKER_IMAGE version
    docker run --rm \
        -e "JAVA_OPTS=-Xms256m" \
        -v "$(pwd):/workspace" \
        --entrypoint "/app/bin/jenkinsfile-runner-launcher" \
        $DOCKER_IMAGE $@
}

lint () {
    base lint
}

run () {
   echo "Hello World2"
}


if [ "$1" = "sanity" ]
then
    sanity $@
    exit $?
fi

if [ "$1" = "bash" ]
then
    bash $@
    exit $?
fi

base $@