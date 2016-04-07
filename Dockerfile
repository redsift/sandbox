FROM ubuntu:15.04
MAINTAINER Deepak Prabhakara email: deepak@redsift.io version: 1.1.101

ENV NANO_MSG=0.8-beta

ENV SIFT_ROOT="/run/dagger/sift" IPC_ROOT="/run/dagger/ipc" SIFT_JSON="sift.json"

# Fix for ubuntu to ensure /etc/default/locale is present
RUN update-locale

RUN export DEBIAN_FRONTEND=noninteractive && \ 
  apt-get update && \
	apt-get install -y \
  curl autoconf libtool make && \
  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd /tmp && curl -L https://github.com/nanomsg/nanomsg/archive/$NANO_MSG.tar.gz | tar xz && \
  cd /tmp/nanomsg-$NANO_MSG && sh autogen.sh && ./configure && make && make check && make install && \
  rm -rf /tmp/nanomsg-$NANO_MSG

# Update .so cache
RUN ldconfig

VOLUME /run/dagger/sift

WORKDIR /run/dagger/sift