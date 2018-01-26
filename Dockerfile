FROM ppc64le/ubuntu:xenial
MAINTAINER Nimbix, Inc.

# Update SERIAL_NUMBER to force rebuild of all layers (don't use cached layers)
ARG SERIAL_NUMBER
ENV SERIAL_NUMBER ${SERIAL_NUMBER:-20180125.1418}

ARG GIT_BRANCH
ENV GIT_BRANCH ${GIT_BRANCH:-master}

RUN apt-get -y update && \
    apt-get -y install curl && \
    curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/$GIT_BRANCH/install-nimbix.sh \
        | bash -s -- --image-common-branch $GIT_BRANCH

WORKDIR /tmp

# 1604 == xenial
ARG CUDA_REPO_DISTVER
ENV CUDA_REPO_DISTVER ${CUDA_REPO_DISTVER:-1604}

ARG CUDA_REPO_VER
ENV CUDA_REPO_VER ${CUDA_REPO_VER:-9.1.85-1}
ARG NVML_REPO_VER
ENV NVML_REPO_VER ${NVML_REPO_VER:-1.0.0-1}
ARG NV_DRV_VER
ENV NV_DRV_VER ${NV_DRV_VER:-361}

ENV CUDA_REPO_URL http://developer.download.nvidia.com/compute/cuda/repos/ubuntu${CUDA_REPO_DISTVER}/ppc64el/cuda-repo-ubuntu${CUDA_REPO_DISTVER}_${CUDA_REPO_VER}_ppc64el.deb
ENV NVML_REPO_URL http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu${CUDA_REPO_DISTVER}/ppc64el/nvidia-machine-learning-repo-ubuntu${CUDA_REPO_DISTVER}_${NVML_REPO_VER}_ppc64el.deb

RUN curl -O ${CUDA_REPO_URL} && dpkg --install *.deb && rm -rf *.deb
RUN curl -O ${NVML_REPO_URL} && dpkg --install *.deb && rm -rf *.deb
RUN apt-get update && apt-get -y install cuda-toolkit-8-0 libcudnn5-dev libcudnn6-dev && apt-get clean

ENV CUDA_REPO_URL ""
ENV NVML_REPO_URL ""

# Hack to allow builds in Docker container
# XXX: this should be okay even if the host driver is rev'd, since the JARVICE
# runtime actually binds in the host version anyway
WORKDIR /tmp
RUN apt-get download nvidia-${NV_DRV_VER} && dpkg --unpack nvidia-${NV_DRV_VER}*.deb && rm -f nvidia-${NV_DRV_VER}*.deb && rm -f /var/lib/dpkg/info/nvidia-${NV_DRV_VER}*.postinst
RUN apt-get -yf install && apt-get clean && ldconfig -f /usr/lib/nvidia-${NV_DRV_VER}/ld.so.conf

# for building CUDA code later
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64/stubs

ADD AppDef.json /etc/NAE/AppDef.json
