#!/bin/bash

# Docker Git:
# https://github.com/jenkinsci/jenkinsfile-runner


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

base () {
    docker run --rm \
        -e "JAVA_OPTS=-Xms256m" \
        -v "$(pwd)/Jenkinsfile:/workspace/Jenkinsfile" \
        jenkins/jenkinsfile-runner version
    docker run --rm \
        -e "JAVA_OPTS=-Xms256m" \
        -v "$(pwd)/Jenkinsfile:/workspace/Jenkinsfile" \
        jenkins/jenkinsfile-runner -f "/workspace/Jenkinsfile" $@
}

lint () {
    base lint
}

run () {
   echo "Hello World2"
}

if [ "$1" = "lint" ]
then
    lint
    exit $?
fi

if [ "$1" = "run" ]
then
    run
    exit $?
fi

if [ "$1" = "sanity" ]
then
    sanity $@
    exit $?
fi

base ${@-help}