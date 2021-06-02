ARG BUILDER_IMAGE=neubauergroup/centos-build-base:latest
FROM ${BUILDER_IMAGE} as builder

USER root
WORKDIR /

SHELL [ "/bin/bash", "-c" ]

ARG TARGET_BRANCH=v6-24-00
ARG GIT_PROJECT_URL=https://github.com/atlascollaboration/root

COPY packages.txt /tmp/packages.txt
COPY requirements.txt /tmp/requirements.txt
RUN yum update -y && \
    yum install -y $(cat /tmp/packages.txt) && \
    yum clean all && \
    yum autoremove -y && \
    python -m pip --no-cache-dir install --upgrade pip setuptools wheel && \
    python -m pip --no-cache-dir install --requirement /tmp/requirements.txt && \
    python -m pip list
# c.f. https://root.cern/install/build_from_source/#all-build-options
RUN mkdir /code && \
    cd /code && \
    git clone --depth 1 "${GIT_PROJECT_URL}" \
      --branch "${TARGET_BRANCH}" \
      --single-branch \
      root_src && \
    cmake \
        -Dall=OFF \
        -Dsoversion=ON \
        -Dgsl_shared=ON \
        -DCMAKE_CXX_STANDARD=17 \
        -Droot7=ON \
        -Dfortran=ON \
        -Droofit=ON \
        -Droostats=ON \
        -Dhistfactory=ON \
        -Dminuit2=ON \
        -Dbuiltin_xrootd=ON \
        -Dxrootd=ON \
        -Dpyroot=ON \
        -DPYTHON_EXECUTABLE=$(which python3) \
        -DCMAKE_INSTALL_PREFIX=/usr/local/root-cern \
        -S root_src \
        -B build && \
    cmake build -L && \
    cmake --build build -- -j$(($(nproc) - 1)) && \
    cmake --build build --target install && \
    cd / && \
    rm -rf /code

ENV PYTHONPATH=/usr/local/root-cern/lib:$PYTHONPATH
ENV LD_LIBRARY_PATH=/usr/local/root-cern/lib:$LD_LIBRARY_PATH
ENV ROOTSYS=/usr/local/root-cern

WORKDIR /home/data
ENV HOME /home

ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/bin/bash"]
