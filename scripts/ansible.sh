#!/bin/bash
set -eu

USER=$1
VERSION=$2
BASHHUB_SERVER=$3

cd /data/ansible/
/usr/bin/ansible --version
ansible-galaxy install -r requirements.yml
ansible-galaxy collection install -r requirements.yml
/usr/bin/ansible-playbook --inventory 127.0.0.1, playbooks/ubuntu-docker.yml --extra-vars "user=${USER} version=${VERSION} bashhub_server=${BASHHUB_SERVER} github_token=${GITHUB_TOKEN}"
