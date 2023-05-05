#!/bin/bash

# Docker Git:
# https://github.com/jenkinsci/jenkinsfile-runner

# Docker entrypoint script:
# https://github.com/jenkinsci/jenkinsfile-runner/blob/main/packaging/docker/unix/jenkinsfile-runner-launcher

# How to add jenkings plugins with custom docker
# https://github.com/jenkinsci/jenkinsfile-runner/blob/main/docs/using/EXTENDING_DOCKER.adoc

# Examples:
# https://github.com/jenkinsci/jenkinsfile-runner/tree/main/demo

# Docker wants a jenkins file in:
# /workspace/Jenkinsfile

#todo:
# stage+timestamp label
# mask pass
# share files? share env?
# Hide pre pipeline stuff until "Started" but show a WARN for it...

DOCKER_IMAGE=ghcr.io/jenkinsci/jenkinsfile-runner:latest
JAVA_OPTS="-Xms256m -Dhudson.model.ParametersAction.keepUndefinedParameters=false"
USER_INPUT=0

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
    if [ $USER_INPUT -eq 0 ]
    then
        docker run --rm \
            -e "JAVA_OPTS=$JAVA_OPTS" \
            -v "$(pwd):/workspace" \
            -i \
            --entrypoint "/app/bin/jenkinsfile-runner-launcher" \
            $DOCKER_IMAGE $@
    else
        docker run --rm \
            -it \
            -e "JAVA_OPTS=$JAVA_OPTS" \
            -v "$(pwd):/workspace" \
            --entrypoint "/app/bin/jenkinsfile-runner-launcher" \
            $DOCKER_IMAGE $@
    fi
}



lintfile () {
    # [05.05.23] For some reason, a verb (lint, run) clear flags, so we set them again.
    base lint --jenkins-war /app/jenkins \
    --plugins /usr/share/jenkins/ref/plugins \
    $@
}

lint () {
    lintfile --file /workspace/Jenkinsfile 
}

run () {
   # No verb = run, but pass flags (-a = params)
   base $@
}

runfile () {
    # [05.05.23] For some reason, a verb (lint, run) clear flags, so we set them again.
    base run --jenkins-war /app/jenkins \
    --plugins /usr/share/jenkins/ref/plugins \
    --runWorkspace /build \
    $@
}

cli () {
    # Version, list-plugins
    USER_INPUT=1
    base --cli
    USER_INPUT=0
}

info () {
    echo "[*] Runner version:"
    base version
    echo "[*] Jenkins version and plugins:"
    echo -e "version\nlist-plugins" | base --cli 2>&1 \
        | grep -E "^([a-z]|\s+>)" | grep -v "bye" # hide cli warnings
}

echo "[*] Params: $@"

if [ "$1" = "sanity" ]; then sanity $@; exit $? ; fi
if [ "$1" = "bash" ]; then bash $@; exit $? ; fi

if [ "$1" = "lint" ]; then lint $@; exit $? ; fi
if [ "$1" = "run" ]; then run  ${@: 2}; exit $? ; fi

if [ "$1" = "cli" ]; then cli $@; exit $? ; fi
if [ "$1" = "info" ]; then info; exit $? ; fi

# runfile expect --file relative to "pwd", we skip 2 params 
#    (https://stackoverflow.com/a/62630975/1997873)
if [ "$1" = "runfile" ]; then runfile ${@: 2}; exit $? ; fi
if [ "$1" = "lintfile" ]; then lintfile ${@: 2}; exit $? ; fi


echo "How to run:"
echo -e "\tbash jenkins.docker.sh <verb> <params>"
echo ""
echo "Verbs:"
echo -e "\t\033[1m sanity, bash, lint, run, cli, info \033[0m"
echo -e "\t\t (No params)"
echo -e "\t\033[1m runfile\033[0m"
echo -e "\t\t --file|-f /workspace/<relative to pwd>"
echo -e "\t\033[1m lintfile\033[0m"
echo -e "\t\t --file|-f /workspace/<relative to pwd>"