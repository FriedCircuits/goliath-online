FROM ubuntu:26.04

LABEL maintainer="FriedCircuits"

ARG BUILD_USER=ubuntu
ARG VERSION=0.0.0
# Defaults to the public Atuin service; override to point at a self-hosted one.
ARG ATUIN_SERVER="https://api.atuin.sh"
# renovate: datasource=github-releases depName=atuinsh/atuin extractVersion=^v(?<version>.+)$
ARG ATUIN_VERSION="18.24.1"
# renovate: datasource=github-releases depName=just-containers/s6-overlay extractVersion=^v(?<version>.+)$
ARG S6_OVERLAY_VERSION="3.2.3.2"
ARG TARGETARCH
ENV GOLIATH_VERISON=${VERSION}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y aptitude apt-utils sudo git ansible python3-apt python3-pip curl xz-utils

RUN pip3 install github3.py --break-system-packages # For Ansible github_releases

RUN id -u ${BUILD_USER} >/dev/null 2>&1 || useradd -ms /bin/bash ${BUILD_USER}
RUN echo "%${BUILD_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${BUILD_USER}

# s6-overlay runs as PID 1, reaps orphaned processes and restarts services that exit.
RUN set -eu; \
    case "${TARGETARCH:-amd64}" in \
      amd64) S6_ARCH=x86_64 ;; \
      arm64) S6_ARCH=aarch64 ;; \
      *) echo "Unsupported architecture ${TARGETARCH}"; exit 1 ;; \
    esac; \
    cd /tmp; \
    for f in noarch ${S6_ARCH}; do \
      curl -fsSLO "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${f}.tar.xz"; \
      curl -fsSLO "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${f}.tar.xz.sha256"; \
    done; \
    sha256sum -c s6-overlay-*.sha256; \
    for f in s6-overlay-*.tar.xz; do tar -C / -Jxpf "$f"; done; \
    rm s6-overlay-*
# s6 runs as the build user, which needs to write its state to /run.
RUN chown ${BUILD_USER}:${BUILD_USER} /run
# Stop the container if startup fails instead of running half set up.
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

RUN mkdir -p /data/scripts /data/ansible
COPY ./scripts /data/scripts
COPY ./ansible /data/ansible
RUN chown -R ${BUILD_USER}:${BUILD_USER} /data /home/${BUILD_USER}

USER ${BUILD_USER}
WORKDIR /home/${BUILD_USER}

RUN --mount=type=secret,id=GITHUB_TOKEN,env=GITHUB_TOKEN \
    /data/scripts/ansible.sh ${BUILD_USER} ${GOLIATH_VERISON} ${ATUIN_SERVER} ${ATUIN_VERSION}

## Clean Up
RUN sudo rm -rf /data && sudo rm -rf /tmp/*

ENTRYPOINT ["/init"]

# No command, the container runs until it is stopped.
CMD []
