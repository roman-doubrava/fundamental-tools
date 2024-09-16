# syntax = edrevo/dockerfile-plus

# SPDX-FileCopyrightText: 2014 SAP SE Srdjan Boskovic <srdjan.boskovic@sap.com>
#
# SPDX-License-Identifier: Apache-2.0

#
# Build:
# docker build --platform=linux/amd64 -t python-311-slim-buster -f python-311-slim-buster.Dockerfile .
# docker run --platform=linux/amd64 -it --name python-311-slim-buster -v /Users/d037732/SAPDevelop/dev:/home/www-admin/src python-311-slim-buster /bin/bash --login
#
# Run:
# docker start -ai python-311-slim-buster
#

FROM python:3.12.2-slim-bookworm

ARG adminuser=www-admin

ARG dev_python="pyrfc==3.3.1"
ARG dev_tools="sudo curl wget git unzip nano tree tmux iproute2 iputils-ping"
ARG dev_libs="build-essential make libssl-dev zlib1g-dev libbz2-dev libncurses5-dev libncursesw5-dev xz-utils"

ENV container docker

# os update and packages
USER root
RUN \
  apt update && DEBIAN_FRONTEND=noninteractive apt install -y locales ${dev_tools} ${dev_libs} && rm -rf /var/lib/apt/lists/*

# timezone # https://serverfault.com/questions/683605/docker-container-time-timezone-will-not-reflect-changes
ENV TZ=Europe/Berlin
RUN locale-gen de_DE && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# https://daten-und-bass.io/blog/fixing-missing-locale-setting-in-ubuntu-docker-image/
RUN \
  sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
  dpkg-reconfigure --frontend=noninteractive locales && \
  update-locale LANG=en_US.UTF-8 && \
  # admin user
  adduser --disabled-password --gecos "" ${adminuser} && \
  usermod -aG www-data,sudo ${adminuser} && \
  echo "${adminuser} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
  # cleanup
  rm -rf /tmp/*

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# sap binaries INCLUDE+ common/saplibs.Dockerfile
ARG nwrfc_version=nwrfcsdk
ARG crypto_version=cryptolib
ARG sap_source=/sap
ARG sap_target=/usr/local/sap

# as root user

RUN mkdir -p ${sap_target}
COPY --chown=${adminuser}:${adminuser} ${sap_source}/${nwrfc_version} ${sap_target}/${nwrfc_version}
COPY --chown=${adminuser}:${adminuser} ${sap_source}/${crypto_version} ${sap_target}/${crypto_version}
COPY --chown=${adminuser}:${adminuser} ${sap_source}/sapcar /usr/local/bin/sapcar

RUN printf "\n# sap libs \n" >> ~/.bashrc && \
  printf "\n# sap libs\nexport SAPNWRFC_HOME=${sap_target}/${nwrfc_version}\nexport PATH=${sap_target}/${crypto_version}:\$PATH\n" >> /home/${adminuser}/.bashrc && \
  chmod -R a+r ${sap_target}/${nwrfc_version} && \
  chmod -R a+x ${sap_target}/${nwrfc_version}/bin && \
  chmod -R a+x ${sap_target}/${nwrfc_version}/lib && \
  chmod a+x /usr/local/bin/sapcar && \
  printf "# include sap nwrfcsdk\n${sap_target}/${nwrfc_version}/lib\n" | tee /etc/ld.so.conf.d/saplibs.conf && \
  ldconfig && ldconfig -p | grep sap

# work user
USER ${adminuser}
WORKDIR /home/${adminuser}
SHELL ["/bin/bash", "-i", "-c"]

RUN printf "alias e=exit\nalias ..=cd..\nalias :q=exit\nalias ll='ls -l'\nalias la='ls -la'\nalias distro='cat /etc/*-release'\n" > .bash_aliases && \
  printf "\n# colors\nexport TERM=xterm-256color\n" >> .bashrc && \
  printf "\nexport PATH=/home/${adminuser}/.local/bin:$PATH\n" >> .bashrc

RUN echo $SAPNWRFC_HOME
RUN pip install ${dev_python}
