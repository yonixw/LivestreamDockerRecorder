# For community tool: https://github.com/firecow/gitlab-ci-local

sudo apt install -y git rsync
yarn global add gitlab-ci-local
gitlab-ci-local --completion >> ~/.bashrc 

# For fast Builds:
echo "alias gcl='gitlab-ci-local'" >> ~/.bashrc


