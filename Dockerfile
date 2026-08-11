FROM ubuntu:24.04

LABEL maintainer="FriedCircuits"

ARG BUILD_USER=william
ARG VERSION=0.0.0
# Defaults to the public Atuin service; override to point at a self-hosted one.
ARG ATUIN_SERVER="https://api.atuin.sh"
ARG ATUIN_VERSION="18.19.0"
ENV GOLIATH_VERISON=${VERSION}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y aptitude apt-utils sudo git ansible python3-apt python3-pip

RUN pip3 install github3.py --break-system-packages # For Ansible github_releases

RUN useradd -ms /bin/bash ${BUILD_USER}
RUN echo "%${BUILD_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${BUILD_USER}

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

ENTRYPOINT ["sh", "/entrypoint.sh"]

CMD ["tail", "-f", "/dev/null"]
