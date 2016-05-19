FROM ubuntu:15.04
MAINTAINER Deepak Prabhakara email: deepak@redsift.io version: 1.1.101

ENV SIFT_ROOT="/run/dagger/sift" IPC_ROOT="/run/dagger/ipc" SIFT_JSON="sift.json"
LABEL io.redsift.dagger.version="1.0.0" io.redsift.dagger.ipc="nanomsg"

# Fix for ubuntu to ensure /etc/default/locale is present
RUN update-locale

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
	apt-get install -y \
  curl autoconf libtool make pkg-config && \
  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install nanomsg
ENV NANO_MSG=0.8-beta
RUN cd /tmp && curl -L https://github.com/nanomsg/nanomsg/archive/$NANO_MSG.tar.gz | tar xz && \
  cd /tmp/nanomsg-$NANO_MSG && sh autogen.sh && ./configure && make && make install && \
  rm -rf /tmp/nanomsg-$NANO_MSG

# Update .so cache
RUN ldconfig

VOLUME /run/dagger/sift /run/dagger/ipc

WORKDIR /run/dagger/sift

# Setup sandbox user & group with uid & gid 7438
ENV HOME /home/sandbox
RUN groupadd -g 7438 sandbox && \
  adduser --system --home $HOME --shell /bin/false -u 7438 --gid 7438 sandbox && \
  chown -R sandbox:sandbox $HOME
