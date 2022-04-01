FROM ubuntu:20.04

LABEL maintainer="FriedCircuits"

ARG BUILD_USER=ubuntu
ARG VERSION=0.0.0
ARG BASHHUB_SERVER="https://bashhub.com"
ENV GOLIATH_VERISON=${VERSION}

RUN apt-get update -y && \
    apt-get install -y aptitude apt-utils sudo git ansible python3-apt python3-pip

RUN pip3 install github3.py

RUN useradd -ms /bin/bash ${BUILD_USER}
RUN echo "%${BUILD_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${BUILD_USER}

RUN mkdir -p /data/scripts /data/ansible
COPY ./scripts /data/scripts
COPY ./ansible /data/ansible
RUN chown -R ${BUILD_USER}:${BUILD_USER} /data /home/${BUILD_USER}

USER ${BUILD_USER}
WORKDIR /home/${BUILD_USER}

RUN /data/scripts/ansible.sh ${BUILD_USER} ${GOLIATH_VERISON} ${BASHHUB_SERVER}

## Clean Up
RUN sudo rm -rf /data

ENTRYPOINT ["sh", "/entrypoint.sh"]

CMD tail -f /dev/null
