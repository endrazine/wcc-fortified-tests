#
# Dockerfile : build WCC under Debian 26.04 (Resolute Raccoon)
#

FROM ubuntu:26.04

WORKDIR /home/ubuntu

# Clean and update package lists
RUN apt-get clean && apt-get update && apt-get upgrade -y

RUN apt-get install -y --no-install-recommends libbfd-dev libsframe-dev uthash-dev libelf-dev \
    libcapstone-dev libreadline-dev libiberty-dev libgsl-dev build-essential git \
    debootstrap file nano xxd ca-certificates cargo
    
# Build wcc & install it
RUN git clone https://github.com/endrazine/wcc.git && cd wcc && git checkout ce65f99f2b7963563a330728c4beab4d6d3e15c7 && git submodule init && git submodule update && make && make install

COPY mk_fortify_pocs.sh /home/ubuntu/
COPY verify_pocs.wsh /home/ubuntu/

USER ubuntu
