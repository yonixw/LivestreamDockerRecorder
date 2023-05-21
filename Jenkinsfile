pipeline {
    agent any
    options { timestamps () }
    parameters {
        string(name: 'param1', defaultValue: '', description: 'Greeting message')
        string(name: 'param2', defaultValue: '', description: '2nd parameter')

        string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
        text(name: 'BIOGRAPHY', defaultValue: '', description: 'Enter some information about the person')
        booleanParam(name: 'TOGGLE', defaultValue: true, description: 'Toggle this value')
        choice(name: 'CHOICE', choices: ['One', 'Two', 'Three'], description: 'Pick something')
        password(name: 'PASSWORD', defaultValue: 'SECRET', description: 'Enter a password')
    }
    stages {
        stage('Build') {
            parallel {
                stage('Build.A') {
                    steps {
                        echo 'Hello world!'
                        echo "message: ${params.param1}"
                        echo "param2: ${params.param2}"
                        sh 'ls -la'
                    }
                }
                stage('Build.B') {
                    steps {
                        echo "Inside C inside B!"
                    }
                }
            }
        }
        stage('Example') {
            steps {
                echo "Hello ${params.PERSON}"
                echo "Biography: ${params.BIOGRAPHY}"
                echo "Toggle: ${params.TOGGLE}"
                echo "Choice: ${params.CHOICE}"
                echo "Password: ${params.PASSWORD}"
                sh 'docker ps'
                echo "Did you see last docker ps command?"
            }
        }
        stage('Example Docker') {
            agent {
                 docker { 
                    image 'node' 
                    image 'node:6-alpine'
                    //args '-v ${PWD}:/usr/src/app'
                    reuseNode true
                }
            }
            steps {
                sh 'echo $(date) > result.txt'
                sh 'ls -la .'
                sh 'node -v'
                stash includes: 'result.txt', name: 'app'  
            }
        }
        stage('Example Docker2') {
            agent {
                 docker { 
                    image 'python' 
                    //args '-v ${PWD}:/usr/src/app'
                    reuseNode true
                }
            }
            steps {
                unstash 'app' 
                sh 'cat result.txt || ls -la .'
                sh 'python -V'
            }
        }
        stage('BuiltInStuff') {
            steps {
                sh '''
                    #printenv
                    echo "BUILD_NAME=$BUILD_NAME"
                    echo "BUILD_NAME=${BUILD_NAME}"
                    echo "BUILD_URL=${BUILD_URL}"
                    echo EXECUTOR_NUMBER=${EXECUTOR_NUMBER}
                    echo STAGE_NAME=${STAGE_NAME}
                    echo BUILD_DISPLAY_NAME=${BUILD_DISPLAY_NAME}
                    echo BUILD_ID=${BUILD_ID}
                    echo JOB_DISPLAY_URL=${JOB_DISPLAY_URL}
                    echo JOB_NAME=${JOB_NAME}
                    echo JOB_BASE_NAME=${JOB_BASE_NAME}
                '''
                // currentBuild = org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper
                echo "currentBuild.fullDisplayName=${currentBuild.fullDisplayName}"
                echo "currentBuild.url=${currentBuild.absoluteUrl}"
                echo "If you see this, done!"
                sh "sleep 1d"
            }
        }
        stage('BuiltInStuff2') {
            steps {
                echo "Pending?"
            }
        }
    }
}