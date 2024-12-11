# to be run as swarms user
export HOME=/home/swarms
unset CONDA_EXE
unset CONDA_PYTHON_EXE
export PATH=/var/task/agent_workspace/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [ ! -f /var/task/agent_workspace/.venv/ ];
then
   virtualenv /var/task/agent_workspace/.venv/
fi
. /var/task/agent_workspace/.venv/bin/activate
pip install fastapi   uvicorn  termcolor
pip install -e /opt/swarms/
cd /var/task/
pip install -e  /opt/swarms-memory
pip install "fastapi[standard]"
pip install "loguru"
pip install  pydantic==2.8.2
pip freeze
# launch as systemd
#python /opt/swarms/api/main.py


