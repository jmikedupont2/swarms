# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set environment variables
#ENV PYTHONDONTWRITEBYTECODE 1
#ENV PYTHONUNBUFFERED 1

WORKDIR /opt/swarms/
RUN apt update
RUN apt install -y git
RUN apt install --allow-change-held-packages -y python3-virtualenv
RUN apt install --allow-change-held-packages -y expect
RUN apt install --allow-change-held-packages -y jq netcat-traditional # missing packages

# Install Python dependencies
COPY requirements.txt .
RUN mkdir -p /var/swarms/agent_workspace/
RUN adduser --disabled-password --gecos "" swarms --home "/home/swarms"
RUN chown  -R swarms:swarms /var/swarms/agent_workspace
USER swarms
RUN python3 -m venv /var/swarms/agent_workspace/.venv/
RUN /var/swarms/agent_workspace/.venv/bin/python -m pip install -r /opt/swarms/requirements.txt
RUN git config --global --add safe.directory "/opt/swarms"
RUN /var/swarms/agent_workspace/.venv/bin/python -m pip install uvicorn fastapi
COPY swarms /opt/swarms/swarms
COPY pyproject.toml /opt/swarms/
COPY README.md /opt/swarms/
RUN /var/swarms/agent_workspace/.venv/bin/python -m pip install -e /opt/swarms/

# things that change
COPY api/main.py /opt/swarms/api/main.py
WORKDIR /opt/swarms/api/
CMD ["/usr/bin/unbuffer", "/var/swarms/agent_workspace/.venv/bin/uvicorn", "--proxy-headers", "--forwarded-allow-ips='*'", "--workers=4", "--port=8000",    "--reload-delay=30",  "main:create_app"]
