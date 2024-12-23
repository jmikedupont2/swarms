# run swarms via docker via systemd
# this script is called from ssm 
# pull the new version via systemd

# now allow for reconfigure of the systemd
export WORKSOURCE="${ROOT}/opt/swarms/api"
sed -e "s!ROOT!${ROOT}!g" > /etc/nginx/sites-enabled/default < "${WORKSOURCE}/nginx/site.conf"

systemctl daemon-reload
# start and stop the service pulls the docker image
systemctl stop swarms-docker || journalctl -xeu swarms-docker
systemctl start swarms-docker || journalctl -xeu swarms-docker
systemctl enable swarms-docker || journalctl -xeu swarms-docker
