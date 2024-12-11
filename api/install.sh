export WORKSOURCE=/opt/swarms/api
sudo apt update
sudo apt install -y git virtualenv
rm -rf ./src/swarms # oops
useradd swarms
# we should have done this
if [ ! -d /opt/swarms/ ];
then
    git clone https://github.com/jmikedupont2/swarms /opt/swarms/
fi

pushd /opt/swarms/
git checkout feature/ec2 # switch branches
git pull # update 
popd
  
if [ ! -d /opt/swarms-memory/ ];
then
    git clone https://github.com/The-Swarm-Corporation/swarms-memory /opt/swarms-memory
fi

# where the swarms will run
mkdir -p /var/swarms/agent_workspace/
mkdir -p /home/swarms
chown -R swarms:swarms /var/swarms/agent_workspace /home/swarms

# copy the run file from git
cp "${WORKSOURCE}/run.sh" /var/swarms/agent_workspace/run.sh
mkdir -p /var/swarms/logs
chmod +x /var/swarms/agent_workspace/run.sh
chown -R swarms:swarms /var/swarms/ /home/swarms /opt/swarms

# user install but do not start
su -c "bash -x /var/swarms/agent_workspace/run.sh" swarms

# now we setup the service
cp "${WORKSOURCE}/nginx/site.conf" /etc/nginx/sites-enabled/default
cp "${WORKSOURCE}/systemd/gunicorn.service" /etc/systemd/system/

# we create a second installation of unicorn so agents cannot mess it up.
mkdir -p /var/run/uvicorn/env/
if [ ! -f /var/run/uvicorn/env/ ];
then
   virtualenv /var/run/uvicorn/env/
fi
. /var/run/uvicorn/env/bin/activate
pip install  uvicorn
###

systemctl daemon-reload
systemctl start gunicorn
systemctl enable gunicorn
service nginx restart

