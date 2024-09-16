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

# sap binaries
INCLUDE+ common/saplibs.Dockerfile

# work user
USER ${adminuser}
WORKDIR /home/${adminuser}

RUN printf "alias e=exit\nalias ..=cd..\nalias :q=exit\nalias ll='ls -l'\nalias la='ls -la'\nalias distro='cat /etc/*-release'\n" > .bash_aliases && \
  printf "\n# colors\nexport TERM=xterm-256color\n" >> .bashrc && \
  printf "\nexport PATH=/home/${adminuser}/.local/bin:$PATH\n" >> .bashrc

SHELL ["/bin/bash", "-c"]

RUN pip install ${dev_python}
