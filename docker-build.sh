#!/bin/bash
set -eu

if [[ ! -f "./build.cfg" ]]; then
    cp build.cfg.example build.cfg
fi

source "build.cfg"
source "VERSION"

SECONDS=0
DOCKER_BUILDKIT=1

if [[ "${IMAGE_SERVICE}" == "aws" ]]; then
  IMAGE_REF="${AWS_HOST}/${IMAGE_REPO}"
else
  IMAGE_REF="${IMAGE_REPO}"
fi

echo '--------------------'
echo ' BUILD DOCKER IMAGE '
echo '--------------------'
docker build --rm \
  --tag "${IMAGE_REF}:${VERSION}" \
  --tag "${IMAGE_REF}:latest" \
  --tag "${IMAGE_NAME}:latest" \
  --tag "${IMAGE_NAME}:${VERSION}" \
  --progress=plain \
  --build-arg BUILD_USER=$BUILD_USER \
  --build-arg VERSION=$VERSION \
  --build-arg BASHHUB_SERVER=$BASHHUB_SERVER \
  -f Dockerfile .

echo "Total Build Time: $(printf '%dh:%dm:%ds\n' $(($SECONDS / 3600)) $(($SECONDS % 3600 / 60)) $(($SECONDS % 60)))"

if [[ "${IMAGE_PUSH}" == "true" ]]; then
  if [[ "${IMAGE_SERVICE}" == "aws" ]]; then
    aws ecr get-login-password \
      --region "${AWS_REGION}" |
      docker login \
      --username "AWS" \
      --password-stdin "${AWS_HOST}"
  elif [[ "${IMAGE_SERVICE}" == "docker" ]]; then
    docker login --username "${DOCKER_USER}" --email "${DOCKER_EMAIL}"
  else
    echo "Push enabled but service not configured, <aws|docker>."
  fi
  echo '----------------------'
  echo ' PUSHING DOCKER IMAGE '
  echo '----------------------'
  docker push --all-tags "${IMAGE_REF}"
fi
