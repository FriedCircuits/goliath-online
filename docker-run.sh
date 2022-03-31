#!/bin/bash
set -eu

source "build.cfg"
source "VERSION"

docker run -d \
  -e SSH_AUTH_SOCK=${SSH_AUTH_SOCK} \
  -v $SSH_AUTH_SOCK:${SSH_AUTH_SOCK} \
  -v /var/run/docker.sock.raw:/var/run/docker.sock \
  -v ${IMAGE_NAME}:/home/$BUILD_USER \
  -v ~/.ssh:/home/$BUILD_USER/.ssh \
  -v ~/.kube:/home/$BUILD_USER/.kube \
  -v ~/.aws:/home/$BUILD_USER/.aws \
  -v ~/.zhistory:/home/$BUILD_USER/.zhistory \
  -v ~/.docker:/home/$BUILD_USER/.docker \
  -p 22:22 \
  -p 8080:8080 \
  --hostname=${IMAGE_NAME} \
  --name ${IMAGE_NAME} ${IMAGE_NAME}:latest
