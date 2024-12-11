#!/bin/bash
# review and improve
set -e # stop  on any error
set -x
export ROOT="/mnt/data1/swarms"
export WORKSOURCE="${ROOT}/opt/swarms/api"
if [ 1 == 0 ]; then
    sudo apt update
    sudo apt install --allow-change-held-packages -y git virtualenv
fi
#rm -rf ./src/swarms # oops
adduser swarms --home "${ROOT}/home/swarms" || echo ignore
git config --global --add safe.directory "${ROOT}/opt/swarms"
git config --global --add safe.directory "${ROOT}/opt/swarms-memory"
# we should have done this
if [ ! -d "${ROOT}/opt/swarms/" ];
then
    git clone https://github.com/jmikedupont2/swarms "${ROOT}/opt/swarms/"
fi

pushd "${ROOT}/opt/swarms/" || exit 1 # "we need swarms"
git remote add local /time/2024/05/swarms/ || git remote set-url local /time/2024/05/swarms/ 
git fetch local 
git checkout feature/ec2 # switch branches
git pull local feature/ec2
popd || exit 2
  
if [ ! -d "${ROOT}/opt/swarms-memory/" ];
then
    git clone https://github.com/The-Swarm-Corporation/swarms-memory "${ROOT}/opt/swarms-memory"
fi

# where the swarms will run
mkdir -p "${ROOT}/var/swarms/agent_workspace/"
mkdir -p "${ROOT}/home/swarms"
chown -R swarms:swarms "${ROOT}/var/swarms/agent_workspace" "${ROOT}/home/swarms"

# copy the run file from git
cp "${WORKSOURCE}/boot.sh" "${ROOT}/var/swarms/agent_workspace/boot.sh"
mkdir -p "${ROOT}/var/swarms/logs"
chmod +x "${ROOT}/var/swarms/agent_workspace/boot.sh"
chown -R swarms:swarms "${ROOT}/var/swarms/" "${ROOT}/home/swarms" "${ROOT}/opt/swarms"

# user install but do not start
su -c "bash -e -x ${ROOT}/var/swarms/agent_workspace/boot.sh" swarms

# now we setup the service
cp "${WORKSOURCE}/nginx/site.conf" /etc/nginx/sites-enabled/default
cp "${WORKSOURCE}/systemd/uvicorn.service" /etc/systemd/system/swarms-uvicorn.service

# we create a second installation of unicorn so agents cannot mess it up.
mkdir -p "${ROOT}/var/run/uvicorn/env/"
if [ ! -f "${ROOT}/var/run/uvicorn/env/" ];
then
   virtualenv "${ROOT}/var/run/uvicorn/env/"
fi
. "${ROOT}/var/run/uvicorn/env/bin/activate"
pip install  uvicorn
###

systemctl daemon-reload
systemctl start swarms-uvicorn
systemctl enable swarms-uvicorn
service nginx restart

