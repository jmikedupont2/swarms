# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set environment variables
#ENV PYTHONDONTWRITEBYTECODE 1
#ENV PYTHONUNBUFFERED 1

# Set the working directory in the container
WORKDIR /opt/swarms/

RUN apt update
RUN apt install -y git
# Install Python dependencies
# COPY requirements.txt and pyproject.toml if you're using poetry for dependency management
COPY requirements.txt .
#RUN pip install --upgrade pip
RUN mkdir -p /var/swarms/agent_workspace/


RUN adduser --disabled-password --gecos "" swarms --home "/home/swarms"
RUN chown  -R swarms:swarms /var/swarms/agent_workspace
USER swarms

RUN python3 -m venv /var/swarms/agent_workspace/.venv/
RUN /var/swarms/agent_workspace/.venv/bin/python -m pip install -r /opt/swarms/requirements.txt


RUN git config --global --add safe.directory "/opt/swarms"

# Copy the rest of the application
#COPY . .

# Expose port if your application has a web interface
# EXPOSE 5000

# # Define environment variable for the swarm to work
# ENV OPENAI_API_KEY=your_swarm_api_key_here

# If you're using `CMD` to execute a Python script, make sure it's executable
RUN fastapi api:main
