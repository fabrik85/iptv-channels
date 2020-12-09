FROM ubuntu:18.04
LABEL maintainer="Attila Fabrik, fabrik85@gmail.com"

# Run 'dpkg' without interactive dialogue. (e.g. Configuring tzdata requires user input.)
ARG DEBIAN_FRONTEND=noninteractive

# hadolint ignore=DL3015
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3-pip=9.0.* \
        python3-setuptools=39.0.* \
        jq=1.5+dfsg-2 \
        mutt=1.9.* \
        libsasl2-modules=2.1.* \
    && pip3 install wheel==0.34.* \
    && pip3 install awscli==1.18.* --upgrade \
    && rm -rf /var/lib/apt/lists/*

# Infrastructure files
COPY docker/resource/yaml2json /usr/bin/
COPY docker/resource/mutt /root/.mutt

# Application files
COPY config.yml helper.sh main.sh /home/src/
COPY actions /home/src/actions

# ENTRYPOINT
COPY docker/docker-entrypoint.sh /usr/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["help"]