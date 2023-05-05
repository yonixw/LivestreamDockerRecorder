#!/bin/bash

# Docker Git:
# https://github.com/jenkinsci/jenkinsfile-runner

# Docker entrypoint script:
# https://github.com/jenkinsci/jenkinsfile-runner/blob/main/packaging/docker/unix/jenkinsfile-runner-launcher

# How to add jenkings plugins with custom docker
# https://github.com/jenkinsci/jenkinsfile-runner/blob/main/docs/using/EXTENDING_DOCKER.adoc

# Docker wants a jenkins file in:
# /workspace/Jenkinsfile

DOCKER_IMAGE=ghcr.io/jenkinsci/jenkinsfile-runner:latest
JAVA_OPTS=-Xms256m

sanity () {
    docker run --rm \
        -e "JAVA_OPTS=$JAVA_OPTS" \
        -v "$(pwd):/workspace" \
        bash \
            -c " \
            printenv && \
            ls -lah /workspace && \
            cat /workspace/Jenkinsfile && \
            echo "$@" \
            "
}

bash () {
    docker run --rm \
        -e "JAVA_OPTS=$JAVA_OPTS" \
        -v "$(pwd):/workspace" \
        -it \
        --entrypoint bash \
        $DOCKER_IMAGE
}

base () {
    echo "Params: $@"
    docker run --rm \
        -e "JAVA_OPTS=$JAVA_OPTS" \
        -v "$(pwd):/workspace" \
        $DOCKER_IMAGE version
    docker run --rm \
        -e "JAVA_OPTS=$JAVA_OPTS" \
        -v "$(pwd):/workspace" \
        --entrypoint "/app/bin/jenkinsfile-runner-launcher" \
        $DOCKER_IMAGE $@
}

lint () {
    # [05.05.23] For some reason, a verb (lint, run) clear flags, so we set them again.
    base lint --jenkins-war /app/jenkins \
    --plugins /usr/share/jenkins/ref/plugins \
    --file /workspace/Jenkinsfile 
}

run () {
   # No verb = run
   base
}

runfile () {
    # [05.05.23] For some reason, a verb (lint, run) clear flags, so we set them again.
    base run --jenkins-war /app/jenkins \
    --plugins /usr/share/jenkins/ref/plugins \
    --runWorkspace /build \
    $@
}

if [ "$1" = "sanity" ]; then sanity $@; exit $? ; fi
if [ "$1" = "bash" ]; then bash $@; exit $? ; fi

if [ "$1" = "lint" ]; then lint $@; exit $? ; fi
if [ "$1" = "run" ]; then run $@; exit $? ; fi

# runfile expect --file relative to "pwd"
if [ "$1" = "runfile" ]; then runfile ${@: 2}; exit $? ; fi


echo "How to run:"
echo -e "\tbash jenkins.docker.sh <verb> <params>"
echo ""
echo "Verbs:"
echo -e "\tsanity, bash, lint, run\n\t\tNo params"
echo -e "\trunfile\n\t\t--file /workspace/<relative to pwd>"