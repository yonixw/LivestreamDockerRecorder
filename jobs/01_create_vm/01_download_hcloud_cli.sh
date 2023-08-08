#!/usr/bin/env bash
# from: https://github.com/MuhammedKalkan/OpenLens/issues/130

GH_DL_REPO=hetznercloud/cli
# WARN: double check no weird stuff with $GH_DL_FILTER
GH_DL_SAVEPATH=hcloud-linux-amd64.tar.gz
GH_DL_FILTER=$GH_DL_SAVEPATH

set -e

LATEST_URL=$(curl https://api.github.com/repos/$GH_DL_REPO/releases/latest | 
    jq -r '.assets[] |  .browser_download_url' | grep -i "$GH_DL_FILTER")

echo "LATEST_URL=$LATEST_URL"


if [[ -z $LATEST_URL ]]
then
 echo "Couldn't get latest link, exiting."
 exit 1
fi

curl -L $LATEST_URL > "$GH_DL_SAVEPATH"