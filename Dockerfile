# DockerFile for firedrake
# Based on https://github.com/firedrakeproject/firedrake/blob/master/docker
#
# build cmd:
# 
# $ docker build -f Dockerfile --build-tag VERSION=complex-int64 --tag lrtfm/firedrake-complex-int64 .
# $ docker build -f Dockerfile --build-tag VERSION=real-int32 --tag lrtfm/firedrake-real-int32 .

ARG VERSION=real-int32

FROM lrtfm/firedrake-env:latest AS base
USER firedrake
WORKDIR /home/firedrake
RUN curl -O https://raw.githubusercontent.com/firedrakeproject/firedrake/master/scripts/firedrake-install

FROM base AS firedrake-complex-int64
# RUN bash -c "\
# PETSC_CONFIGURE_OPTIONS='--download-scalapack --download-mumps' \
#     python3 firedrake-install --petsc-int-type int64 --complex --slepc \
#     --no-package-manager --disable-ssh --documentation-dependencies --remove-build-files && \
# find /home/firedrake/firedrake -type d -name '.git' -exec rm -rf {} + && \
# rm -rf /home/firedrake/firedrake/src/{petsc,slepc}/default/obj && \
# rm -rf /home/firedrake/.cached/pip \
# "
RUN bash -c "\
PETSC_CONFIGURE_OPTIONS='--download-scalapack --download-mumps' \
    python3 firedrake-install --petsc-int-type int64 --complex --slepc \
    --no-package-manager --disable-ssh --documentation-dependencies --remove-build-files && \
rm -rf /home/firedrake/.cached/pip \
"

FROM base AS firedrake-real-int32
RUN bash -c "\
python3 firedrake-install --slepc --no-package-manager --disable-ssh --documentation-dependencies --remove-build-files && \
rm -rf /home/firedrake/.cached/pip \
"

FROM firedrake-$VERSION AS final
# This DockerFile is looked after by
MAINTAINER Zongze Yang <yangzongze@gmail.com>

RUN echo "Build for $VERSION"
RUN bash -c "\
. /home/firedrake/firedrake/bin/activate && \
pip install jupyterlab ipyparallel ipywidgets && \
pip install mpltools meshio gmsh scipy pyyaml pandas && \
rm -rf /home/firedrake/.cached/pip \
"

ENV OMP_NUM_THREADS=1
ENV PATH=/home/firedrake/firedrake/bin:$PATH

CMD /home/firedrake/firedrake/bin/jupyter-lab --ip 0.0.0.0 --no-browser --allow-root
