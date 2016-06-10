FROM ubuntu:15.04
MAINTAINER Deepak Prabhakara email: deepak@redsift.io version: 1.1.101

ENV SIFT_ROOT="/run/sandbox/sift" IPC_ROOT="/run/sandbox/ipc" SIFT_JSON="sift.json"
LABEL io.redsift.sandbox.version="1.0.0" io.redsift.sandbox.rpc="nanomsg"

# Fix for ubuntu to ensure /etc/default/locale is present
RUN update-locale

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
	apt-get install -y \
  curl autoconf libtool make cmake pkg-config && \
  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install nanomsg
ENV NANO_MSG=0.9-beta
RUN cd /tmp && curl -L https://github.com/nanomsg/nanomsg/archive/$NANO_MSG.tar.gz | tar xz && \
  cd /tmp/nanomsg-$NANO_MSG && mkdir build && cd build && cmake .. && cmake --build . && cmake --build . --target install && \
  rm -rf /tmp/nanomsg-$NANO_MSG

# Update .so cache
RUN ldconfig

VOLUME /run/sandbox/sift /run/sandbox/ipc

WORKDIR /run/sandbox/sift

# Setup sandbox user & group with uid & gid 7438
ENV HOME /home/sandbox
RUN groupadd -g 7438 sandbox && \
  adduser --system --home $HOME --shell /bin/false -u 7438 --gid 7438 sandbox && \
  chown -R sandbox:sandbox $HOME
