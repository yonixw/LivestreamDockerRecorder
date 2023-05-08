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
# user script to add to custom docker
# move all $ref to ./Jenkins/ for housekeeping
# fix dind bug with same name share: https://github.com/jenkinsci/docker/issues/626#issuecomment-358331311
# how to create local docker from latest version of jenkins, or from a specifiec one?

# stage+timestamp label
# mask pass
# share files? share env?
# Hide pre pipeline stuff until "Started" but show a WARN for it...

# Jenkins File Runner
JFR_IMAGE=ghcr.io/jenkinsci/jenkinsfile-runner
JFR_TAG=jre-11@sha256:72ff68c1c368220eb4953a562de3f545404fb5b8c529157b9d6915b90b2c750e # 1.0-beta-32-SNAPSHOT

# JDK helper Image (as JFR not always contain all tools)
JDK_HELPER_IMAGE=eclipse-temurin
JDK_HELPER_TAG=11-jdk@sha256:9de4aabba13e1dd532283497f98eff7bc89c2a158075f0021d536058d3f5a082

# Local tag to hold latest or plugin built image
LOCAL_DOCKER_IMAGE=local_jfr$LOCAL_JFR_TAG

# Java options to pass to environment
JAVA_OPTS="-Xms256m -Dhudson.model.ParametersAction.keepUndefinedParameters=false -Dorg.jenkinsci.plugins.durabletask.BourneShellScript.LAUNCH_DIAGNOSTICS=true"

# Inner Flag if to pass `-t` to docker run
USER_INPUT=0

verify_local_image() {
    docker images --format "{{.Repository}}:{{.Tag}}" | grep $LOCAL_DOCKER_IMAGE > /dev/null
    if [ $? -ne 0 ]
    then
        echo "ERR: No local image found! please run pull/addplugins verb before"
        exit 1;
    fi
}

pull () {
    echo "JFR Pull start..."
    docker pull $JFR_IMAGE:$JFR_TAG
    docker tag $JFR_IMAGE:$JFR_TAG $LOCAL_DOCKER_IMAGE
    echo "JFR Pull done!"
}

addplugins () {
    verify_local_image

    tmpfile=$(mktemp Dockerfile.jfr-plugins.XXXXXX)
    echo "JFR Add plugin started.. using $tmpfile"
    cat >$tmpfile <<EOF
FROM $LOCAL_DOCKER_IMAGE as base

FROM $JDK_HELPER_IMAGE:$JDK_HELPER_TAG as helper
COPY --from=base /app/jenkins /app/jenkins
# Zip /app/jenkins into jenkins.war because plugin manager works against a WAR/JAR 
RUN cd /app/jenkins && \\
    jar -cvf jenkins.war *

FROM $LOCAL_DOCKER_IMAGE
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY --from=helper /app/jenkins/jenkins.war /app/jenkins/jenkins.war

# add apt:
RUN apt update && apt install -y docker.io
#TODO: replace with user script

# Update plugins:
RUN java -jar /app/bin/jenkins-plugin-manager.jar \\
    --list \\
    --jenkins-version "\$(cat /app/jenkins/META-INF/MANIFEST.MF | grep Jenkins-Version | grep -oE "[0-9]+(\.[0-9]+)+")" \\
    --war /app/jenkins/jenkins.war \\
    --plugin-file /usr/share/jenkins/ref/plugins.txt \\
    && rm /app/jenkins/jenkins.war
EOF

    docker build -t $LOCAL_DOCKER_IMAGE -f "$tmpfile" .
    rm $tmpfile
    echo "JFR Add plugin done!"

}

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

sh () {
    verify_local_image
    docker run --rm \
        -e "JAVA_OPTS=$JAVA_OPTS" \
        -v "$(pwd):/workspace" \
        -it \
        --entrypoint sh \
        $LOCAL_DOCKER_IMAGE
}

base () {
    verify_local_image
    if [ $USER_INPUT -eq 0 ]
    then
        docker run --rm \
            -e "JAVA_OPTS=$JAVA_OPTS" \
            -v "$(pwd):/workspace" \
            -v /var/run/docker.sock:/var/run/docker.sock \
            --entrypoint "/app/bin/jenkinsfile-runner-launcher" \
            $LOCAL_DOCKER_IMAGE $@ 2>&1 | grep -v WARNING
    else
        docker run --rm \
            -it \
            -e "JAVA_OPTS=$JAVA_OPTS" \
            -v "$(pwd):/workspace" \
            -v /var/run/docker.sock:/var/run/docker.sock \
            --entrypoint "/app/bin/jenkinsfile-runner-launcher" \
            $LOCAL_DOCKER_IMAGE $@ 2>&1 | grep -v WARNING
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
if [ "$1" = "sh" ]; then sh; exit $? ; fi

if [ "$1" = "pull" ]; then pull; exit $? ; fi
if [ "$1" = "addplugins" ]; then addplugins; exit $? ; fi

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
echo -e "\t\033[1m pull, sanity, sh, lint, run, cli, info \033[0m"
echo -e "\t\t (No params)"
echo -e "\t\033[1m runfile\033[0m"
echo -e "\t\t --file|-f /workspace/<relative \033[4mJenkinsfile\033[0m to pwd>"
echo -e "\t\t --plugins|-p /workspace/<relative \033[4mplugins.txt\033[0m to pwd>"
echo -e "\t\033[1m lintfile\033[0m"
echo -e "\t\t --file|-f /workspace/<relative \033[4mJenkinsfile\033[0m to pwd>"
echo -e "\t\t --plugins|-p /workspace/<relative \033[4mplugins.txt\033[0m to pwd>"
echo -e "\t\033[1m addplugins\033[0m"
echo -e "\t\t need ./plugins.txt with {id}:{version} like slack:2.49"
echo -e "\t\t see https://updates.jenkins-ci.org/download/plugins/"
echo -e "\t\t but make sure it compatible with docker version"
