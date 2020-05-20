FROM ppc64le/ubuntu:bionic
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

RUN apt-get -y update && \
    apt-get -y install curl && \
    curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
        | bash -s --

WORKDIR /tmp

# 1804 == bionic 18.04
ARG CUDA_REPO_DISTVER
ENV CUDA_REPO_DISTVER ${CUDA_REPO_DISTVER:-1804}

ARG CUDA_REPO_VER
ENV CUDA_REPO_VER ${CUDA_REPO_VER:-10.0.130-1}
ARG NVML_REPO_VER
ENV NVML_REPO_VER ${NVML_REPO_VER:-1.0.0-1}
ARG NV_DRV_VER
ENV NV_DRV_VER ${NV_DRV_VER:-410}

ENV CUDA_REPO_URL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${CUDA_REPO_DISTVER}/ppc64el/cuda-repo-ubuntu${CUDA_REPO_DISTVER}_${CUDA_REPO_VER}_ppc64el.deb
ENV NVML_REPO_URL https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu${CUDA_REPO_DISTVER}/ppc64el/nvidia-machine-learning-repo-ubuntu${CUDA_REPO_DISTVER}_${NVML_REPO_VER}_ppc64el.deb

RUN curl -O ${CUDA_REPO_URL} && dpkg --install *.deb && rm -rf *.deb
RUN curl -O ${NVML_REPO_URL} && dpkg --install *.deb && rm -rf *.deb
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${CUDA_REPO_DISTVER}/ppc64el/7fa2af80.pub && \
    apt-get update && \
    apt-get -y install cuda-toolkit-10-0 libcudnn7-dev && \
    apt-get clean

ENV CUDA_REPO_URL ""
ENV NVML_REPO_URL ""

# Hack to allow builds in Docker container
# XXX: this should be okay even if the host driver is rev'd, since the JARVICE
# runtime actually binds in the host version anyway
WORKDIR /tmp
RUN apt-get download nvidia-headless-${NV_DRV_VER} && \
    dpkg --unpack nvidia-headless-${NV_DRV_VER}*.deb && \
    rm -f nvidia-headless-${NV_DRV_VER}*.deb && \
    rm -f /var/lib/dpkg/info/nvidia-${NV_DRV_VER}*.postinst
RUN apt-get -yf install && \
    apt-get clean && \
    ldconfig -f /usr/lib/nvidia-${NV_DRV_VER}/ld.so.conf
RUN echo 'export PATH=$PATH:/usr/local/cuda/bin' >/etc/profile.d/cuda.sh

# for building CUDA code later
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64/stubs

COPY AppDef.json /etc/NAE/AppDef.json
RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://api.jarvice.com/jarvice/validate
