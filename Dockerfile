FROM ppc64le/ubuntu:xenial
MAINTAINER Nimbix, Inc.

# Update SERIAL_NUMBER to force rebuild of all layers (don't use cached layers)
ARG SERIAL_NUMBER
ENV SERIAL_NUMBER ${SERIAL_NUMBER:-20180124.1405}

ARG GIT_BRANCH
ENV GIT_BRANCH ${GIT_BRANCH:-master}

RUN apt-get -y update && \
    apt-get -y install curl && \
    curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/$GIT_BRANCH/install-nimbix.sh \
        | bash -s -- --setup-nimbix-desktop --image-common-branch $GIT_BRANCH

WORKDIR /tmp
ENV CUDA_REPO_URL http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/ppc64el/cuda-repo-ubuntu1604_8.0.61-1_ppc64el.deb
ENV NVML_REPO_URL http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/ppc64el/nvidia-machine-learning-repo-ubuntu1604_1.0.0-1_ppc64el.deb
RUN curl -O ${CUDA_REPO_URL} && dpkg --install *.deb && rm -rf *.deb
RUN curl -O ${NVML_REPO_URL} && dpkg --install *.deb && rm -rf *.deb
RUN apt-get update && apt-get -y install cuda-toolkit-8-0 libcudnn5-dev libcudnn6-dev && apt-get clean
ENV CUDA_REPO_URL ""
ENV NVML_REPO_URL ""

# Hack to allow builds in Docker container
# XXX: this should be okay even if the host driver is rev'd, since the JARVICE
# runtime actually binds in the host version anyway
WORKDIR /tmp
RUN apt-get download nvidia-361 && dpkg --unpack nvidia-361*.deb && rm -f nvidia-361*.deb && rm -f /var/lib/dpkg/info/nvidia-361*.postinst
RUN apt-get -yf install && apt-get clean && ldconfig -f /usr/lib/nvidia-361/ld.so.conf

# for building CUDA code later
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64/stubs

