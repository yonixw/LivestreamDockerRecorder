#!/bin/bash
# exit when any command fails
set -e

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
# Better log? stage prefix per line?
#   A must for parallel stuff
#       after docker install we have python... use it? or just ts with deno docker? user defined in post {} ?
#       reset && curl -v http://localhost:80/job/job/1/execution/node/22/wfapi/log | jq
#           http://localhost:80/job/job/1/wfapi/describe => $BUILD_URL/wfapi/describe
#       curl http://localhost:80/job/job/1/consoleText || consoleFull
#       curl http://localhost:80/job/job/1/api/json?depth=2 | jq

#   how parallel log looks  like with docker agent?
#   https://github.com/gdemengin/pipeline-logparser
#       logs of nested stages (stage inside stage)
#       if 2 steps or stages have the sane name
# AsciColor plufing.. html?
# DIR to change docker build context or Jenkinsfile source
#       how to handle workspace in pwd like in gitpod?
# "rundind" variation with custom --file input
#  also add http port for all verbs
# mask pass
#    in console print and log export
# share env between stages?
# share "def" between scripts in other dockers?
# array loop
    # https://gist.github.com/oifland/ab56226d5f0375103141b5fbd7807398
    # https://serverfault.com/questions/1014334/how-to-use-for-loop-in-jenkins-declarative-pipeline
# how to create local docker from latest version of jenkins, or from a specifiec one?
#
# [X] alsto timestamp per row? -> calc from wfapi
# [V] timestamp label - plugin
# [V] share file - stash
# [V] Hide pre pipeline stuff until "Started" but show a WARN for it...
# [V] fix dind bug with same name share: https://github.com/jenkinsci/docker/issues/626#issuecomment-358331311

# Config
SHOW_VERBOSE=${VERBOSE:-0}
CURR_DIR="$(pwd)"

if [ ! -z $DIR ]
then
    echo "[*] Using env.DIR=$DIR"
    cd $DIR
fi

if [ $SHOW_VERBOSE -eq 1 ] 
then
    echo "[*] Verbose mode is on"
    JVM_VERBOSE="-Dorg.jenkinsci.plugins.durabletask.BourneShellScript.LAUNCH_DIAGNOSTICS=true"
    #   https://stackoverflow.com/a/63490535/1997873 for debugging dind that uses durable tasks
    REMOVE_GREP="_unlikely_string_"
else
    REMOVE_GREP="WARNING"
fi

# Jenkins File Runner
JFR_IMAGE=ghcr.io/jenkinsci/jenkinsfile-runner
JFR_TAG=jre-11@sha256:72ff68c1c368220eb4953a562de3f545404fb5b8c529157b9d6915b90b2c750e # 1.0-beta-32-SNAPSHOT

# JDK helper Image (as JFR not always contain all tools)
JDK_HELPER_IMAGE=eclipse-temurin
JDK_HELPER_TAG=11-jdk@sha256:9de4aabba13e1dd532283497f98eff7bc89c2a158075f0021d536058d3f5a082

# Local tag to hold latest or plugin built image
LOCAL_DOCKER_IMAGE=local_jfr$LOCAL_JFR_TAG

# Java options to pass to environment
JAVA_OPTS="-Xms256m -Dhudson.model.ParametersAction.keepUndefinedParameters=false $JVM_VERBOSE"

# Inner Flag if to pass `-t` to docker run
USER_INPUT=0

# Workaround for dind (need mountex "ws" + "ws@/1/2/..." + pwd (that the link point to))
tmpdindctx=$(mktemp -d -t jfr-dind-ctx-XXXXXX)
# this created temp dir, and allow all ws@???@tmp to be created and shared
ln -s "$(pwd)" $tmpdindctx/ws # ln -s real soft
echo "[*] Using temp context: $tmpdindctx"

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
COPY Jenkins-plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY Jenkins-prepare.sh /tmp/Jenkins-prepare.sh
COPY --from=helper /app/jenkins/jenkins.war /app/jenkins/jenkins.war

# add user defined software:
RUN chmod +x /tmp/Jenkins-prepare.sh && \
    /tmp/Jenkins-prepare.sh && \
    rm /tmp/Jenkins-prepare.sh

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
        -v  "$tmpdindctx:$tmpdindctx" \
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
        -v  "$tmpdindctx:$tmpdindctx" \
        -v "$(pwd):$(pwd)" \
        -v "$(pwd):/workspace" \
        -it \
        --entrypoint sh \
        $LOCAL_DOCKER_IMAGE
}

base () {
    verify_local_image
    if [ $USER_INPUT -eq 0 ]
    then
        # "-i" Important for getting info input from stdin
        docker run --rm \
            -i \
            -p 40888:80 \
            -e "JAVA_OPTS=$JAVA_OPTS" \
            -v "$(pwd):/workspace" \
            -v  "$tmpdindctx:$tmpdindctx" \
            -v "$(pwd):$(pwd)" \
            -v /var/run/docker.sock:/var/run/docker.sock \
            --entrypoint "/app/bin/jenkinsfile-runner-launcher" \
            $LOCAL_DOCKER_IMAGE $@ 
    else
        docker run --rm \
            -it \
            -p 40888:80 \
            -e "JAVA_OPTS=$JAVA_OPTS" \
            -v "$(pwd):/workspace" \
            -v  "$tmpdindctx:$tmpdindctx" \
            -v "$(pwd):$(pwd)" \
            -v /var/run/docker.sock:/var/run/docker.sock \
            --entrypoint "/app/bin/jenkinsfile-runner-launcher" \
            $LOCAL_DOCKER_IMAGE $@ 
    fi
}



lintfile () {
    # [05.05.23] For some reason, a verb (lint, run) clear flags, so we set them again.
    base lint --jenkins-war /app/jenkins \
    --plugins /usr/share/jenkins/ref/plugins \
    $@ \
    2>&1 | grep -v $REMOVE_GREP
}

lint () {
    lintfile --file /workspace/Jenkinsfile \
    2>&1 | grep -v $REMOVE_GREP
}

run () {
   # No verb = run, but pass flags (-a = params)
   base $@ \
    2>&1 | grep -v $REMOVE_GREP
}

runfile () {
    # [05.05.23] For some reason, a verb (lint, run) clear flags, so we set them again.
    base run --jenkins-war /app/jenkins \
    --plugins /usr/share/jenkins/ref/plugins \
    --runWorkspace "/buid" \
    $@ \
    2>&1 | grep -v $REMOVE_GREP
}

rundind () {
    # [05.05.23] For some reason, a verb (lint, run) clear flags, so we set them again.
    base run --jenkins-war /app/jenkins \
    --plugins /usr/share/jenkins/ref/plugins \
    --runWorkspace "$tmpdindctx/ws" \
    --file "$tmpdindctx/ws/Jenkinsfile" \
    --httpPort 80 \
    $@ \
    2>&1 | grep -v $REMOVE_GREP
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
    # TODO: echo "[*] Jenkins from HTTP:"
    # curl http://localhost:80 .. wait on idle flag?
    echo "[*] Jenkins from MANIFEST.MF:"
    docker run --rm --entrypoint sh $LOCAL_DOCKER_IMAGE -c \
        "cat /app/jenkins/META-INF/MANIFEST.MF | grep Jenkins-Version | grep -oE \"[0-9]+(\.[0-9]+)+\""
    echo "[*] Jenkins CLI version and plugins:"
    echo -e "version\nlist-plugins" | \
        base --cli \
        2>&1 \
        | grep -E "^([a-z]|\s+>)" | grep -v "bye" # hide cli warnings
}

exit_back() {
    echo "[*] JFR Clean temps..."
    rm -rf $tmpdindctx
    cd "$CURR_DIR"
    echo "[*] JFR done with code $1"
    exit $1
}

echo "[*] Params: $@"

if [ "$1" = "sanity" ]; then sanity $@; exit_back $? ; fi
if [ "$1" = "sh" ]; then sh; exit_back $? ; fi

if [ "$1" = "pull" ]; then pull; exit_back $? ; fi
if [ "$1" = "addplugins" ]; then addplugins; exit_back $? ; fi

if [ "$1" = "lint" ]; then lint $@; exit_back $? ; fi
if [ "$1" = "run" ]; then run  ${@: 2}; exit_back $? ; fi
if [ "$1" = "rundind" ]; then rundind; exit_back $? ; fi

if [ "$1" = "cli" ]; then cli $@; exit_back $? ; fi
if [ "$1" = "info" ]; then info; exit_back $? ; fi

# runfile expect --file relative to "pwd", we skip 2 params 
#    (https://stackoverflow.com/a/62630975/1997873)
if [ "$1" = "runfile" ]; then runfile ${@: 2}; exit_back $? ; fi

if [ "$1" = "lintfile" ]; then lintfile ${@: 2}; exit_back $? ; fi


echo "How to run:"
echo -e "\t[ENV=VAL] bash jenkins.docker.sh <verb> <params>"
echo ""
echo "Environment:"
echo -e "\t\033[1m VERBOSE \033[0m"
echo -e "\t\t 1 to enable"
echo -e "\t\033[1m DIR \033[0m"
echo -e "\t\t where the Jenkins files are located"
echo ""
echo "Verbs:"

echo -e "\t\033[1m pull\033[0m: pull/restore default JFR docker image"
echo -e "\t\t (No params)"
echo -e "\t\033[1m sanity\033[0m: print Jenkinsfile+env+ls from docker"
echo -e "\t\t (No params)"
echo -e "\t\033[1m sh\033[0m: run shell inside a docker, good for test/debug"
echo -e "\t\t (No params)"
echo -e "\t\033[1m lint\033[0m: lint the Jenkinsfile using JFR image"
echo -e "\t\t (No params)"
echo -e "\t\033[1m run\033[0m: run the Jenkinsfile using JFR image (no dind)"
echo -e "\t\t (No params)"
echo -e "\t\033[1m rundind\033[0m: run the Jenkinsfile using JFR image (using docker-in-docker fixes)"
echo -e "\t\t Works best with agent.resueNode=true"
echo -e "\t\t (No params)"
echo -e "\t\033[1m cli\033[0m: get a JFR cli session "
echo -e "\t\t (No params)"
echo -e "\t\033[1m info\033[0m: get versions and plugins in current JFR image "
echo -e "\t\t (No params)"


echo -e "\t\033[1m runfile:\033[0m"
echo -e "\t\t --file|-f /workspace/<relative \033[4mJenkinsfile\033[0m to pwd>"
echo -e "\t\t --plugins|-p /workspace/<relative \033[4mplugins.txt\033[0m to pwd>"
echo -e "\t\033[1m lintfile:\033[0m"
echo -e "\t\t --file|-f /workspace/<relative \033[4mJenkinsfile\033[0m to pwd>"
echo -e "\t\t --plugins|-p /workspace/<relative \033[4mplugins.txt\033[0m to pwd>"
echo -e "\t\033[1m addplugins:\033[0m"
echo -e "\t\t replaces local JFR image with a custom one"
echo -e "\t\t need ./plugins.txt with {id}:{version} like slack:2.49"
echo -e "\t\t see https://updates.jenkins-ci.org/download/plugins/"
echo -e "\t\t but make sure it compatible with docker version"
exit_back 1