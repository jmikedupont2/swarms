#!/bin/bash

# this is the install script 
#  install_script = "/opt/swarms/api/rundocker.sh"
# called on boot.

# this is the refresh script called from ssm for a refresh
#  #refresh_script = "/opt/swarms/api/docker-boot.sh" 

. ./.env # for secrets
set -e # stop  on any error
export ROOT="" # empty
export WORKSOURCE="${ROOT}/opt/swarms/api"

adduser --disabled-password --gecos "" swarms --home "${ROOT}/home/swarms"  || echo ignore
git config --global --add safe.directory "${ROOT}/opt/swarms"
git config --global --add safe.directory "${ROOT}/opt/swarms-memory"

cd "${ROOT}/opt/swarms/" || exit 1 # "we need swarms"
git log -2 --patch | head  -1000

mkdir -p "${ROOT}/var/swarms/agent_workspace/"
mkdir -p "${ROOT}/home/swarms"


cd "${ROOT}/opt/swarms/" || exit 1 # "we need swarms"

mkdir -p "${ROOT}/var/swarms/logs"
chmod +x "${ROOT}/var/swarms/agent_workspace/boot_fast.sh"
chown -R swarms:swarms "${ROOT}/var/swarms/" "${ROOT}/home/swarms" "${ROOT}/opt/swarms"

# user install but do not start
su -c "bash -e -x ${ROOT}/var/swarms/agent_workspace/boot_fast.sh" swarms

cd "${ROOT}/opt/swarms/" || exit 1 # "we need swarms"

mkdir -p "${ROOT}/var/run/swarms/secrets/"
mkdir -p "${ROOT}/home/swarms/.cache/huggingface/hub"
export OPENAI_KEY=`aws ssm get-parameter     --name "swarms_openai_key" | jq .Parameter.Value -r `
echo "OPENAI_KEY=${OPENAI_KEY}" > "${ROOT}/var/run/swarms/secrets/env"

## append new homedir
check if the entry exists already before appending pls
if ! grep -q "HF_HOME" ${ROOT}/var/run/swarms/secrets/env"; then
       echo "HF_HOME=${ROOT}/home/swarms/.cache/huggingface/hub" >> "${ROOT}/var/run/swarms/secrets/env"
fi

if ! grep -q "^HOME" ${ROOT}/var/run/swarms/secrets/env"; then
    echo "HOME=${ROOT}/home/swarms" >> "${ROOT}/var/run/swarms/secrets/env"
fi

if ! grep -q "^HOME" ${ROOT}/var/run/swarms/secrets/env"; then
# attempt to move the workspace
echo 'WORKSPACE_DIR=${STATE_DIRECTORY}' >> "${ROOT}/var/run/swarms/secrets/env"

# setup the systemd service again
sed -e "s!ROOT!${ROOT}!g" > /etc/nginx/sites-enabled/default < "${WORKSOURCE}/nginx/site.conf"
sed -e "s!ROOT!${ROOT}!g" > /etc/systemd/system/swarms-docker.service < "${WORKSOURCE}/systemd/swarms-docker.service"
grep . -h -n /etc/systemd/system/swarms-docker.service

chown -R swarms:swarms ${ROOT}/var/run/swarms/
mkdir -p ${ROOT}/opt/swarms/api/agent_workspace/try_except_wrapper/
chown -R swarms:swarms ${ROOT}/opt/swarms/api/

# always reload
systemctl daemon-reload
systemctl start swarms-docker || journalctl -xeu swarms-docker
systemctl enable swarms-docker || journalctl -xeu swarms-docker
systemctl enable nginx
systemctl start nginx

journalctl -xeu swarms-docker | tail -200 || echo oops
systemctl status swarms-docker || echo oops2

# now after swarms is up, we restart nginx
HOST="localhost"
PORT=5474
while ! nc -z $HOST $PORT; do
  sleep 1
  echo -n "."
done
echo "Port $PORT is now open!"

systemctl restart nginx
