# DockerFile for firedrake
# Based on https://github.com/firedrakeproject/firedrake/blob/master/docker
#
# build cmd:
#
# $ docker build -f Dockerfile --build-tag VERSION=complex-int64 --tag lrtfm/firedrake-complex-int64 .
# $ docker build -f Dockerfile --build-tag VERSION=real-int32 --tag lrtfm/firedrake-real-int32 .

ARG VERSION=real-int32

# Notes on PETSc:
#
#   1. Pragmatic cannot be built with 64-bit integers
#

ARG PETSC_COMMON_OPTS="\
--download-fftw \
--download-mmg \
--download-p4est \
--download-parmmg \
--download-triangle \
--download-tetgen \
--download-ctetgen \
--download-hpddm \
--download-libpng \
--download-slepc \
"
# --download-bamg --download-ctetgen \
# --download-egads --download-exodusii \
# --download-ks --download-libceed \
# --download-opencascade \
# --download-muparser \

# ARG PETSC_DEBUG_OPTS=""
ARG PETSC_NONDEBUG_OPTS=""
ARG PETSC_INT64_OPTS="--download-scalapack --download-mumps"
ARG PETSC_INT32_OPTS="--download-pragmatic"

ARG FIRDRAKE_COMMON_OPTS="\
--no-package-manager --disable-ssh \
--documentation-dependencies \
"
ARG FIRDRAKE_NONDEBUG_OPTS="--remove-build-files"
ARG CLEAN_PIP_CACHED="rm -rf /home/firedrake/.cached/pip"
ARG REAL_INT32="\
python3 firedrake-install $FIRDRAKE_COMMON_OPTS $FIRDRAKE_NONDEBUG_OPTS \
&& $CLEAN_PIP_CACHED \
"
ARG REAL_INT32_DEBUG="\
python3 firedrake-install $FIRDRAKE_COMMON_OPTS \
&& $CLEAN_PIP_CACHED \
"
ARG COMPLEX_INT32="\
python3 firedrake-install $FIRDRAKE_COMMON_OPTS $FIRDRAKE_NONDEBUG_OPTS \
  --complex \
&& $CLEAN_PIP_CACHED \
"
ARG COMPLEX_INT32_DEBUG="\
python3 firedrake-install $FIRDRAKE_COMMON_OPTS \
  --complex \
&& $CLEAN_PIP_CACHED \
"
ARG COMPLEX_INT64="\
python3 firedrake-install $FIRDRAKE_COMMON_OPTS $FIRDRAKE_NONDEBUG_OPTS \
  --petsc-int-type int64 --complex \
&& $CLEAN_PIP_CACHED \
"
ARG COMPLEX_INT64_DEBUG="\
python3 firedrake-install $FIRDRAKE_COMMON_OPTS \
  --petsc-int-type int64 --complex \
&& $CLEAN_PIP_CACHED \
"

FROM lrtfm/firedrake:env AS base
USER firedrake
WORKDIR /home/firedrake
RUN curl -O https://raw.githubusercontent.com/firedrakeproject/firedrake/master/scripts/firedrake-install

FROM base AS debug
ARG DEBUG_HACK="sed -i.bak -e 's/\(--with-debugging=\)0/\11/g' firedrake-install"
RUN bash -c "$DEBUG_HACK"

FROM debug AS firedrake-real-int32-debug
ARG REAL_INT32_DEBUG
ARG PETSC_COMMON_OPTS PETSC_INT32_OPTS
ARG PETSC_CONFIGURE_OPTIONS="$PETSC_COMMON_OPTS $PETSC_INT32_OPTS"
RUN bash -c "$REAL_INT32_DEBUG"

FROM debug AS firedrake-complex-int32-debug
ARG COMPLEX_INT32_DEBUG
ARG PETSC_COMMON_OPTS PETSC_INT32_OPTS
ARG PETSC_CONFIGURE_OPTIONS="$PETSC_COMMON_OPTS $PETSC_INT32_OPTS"
RUN bash -c "$COMPLEX_INT32_DEBUG"

FROM debug AS firedrake-complex-int64-debug
ARG COMPLEX_INT64_DEBUG
ARG PETSC_COMMON_OPTS PETSC_INT64_OPTS
ARG PETSC_CONFIGURE_OPTIONS="$PETSC_COMMON_OPTS $PETSC_INT64_OPTS"
RUN bash -c "$COMPLEX_INT64_DEBUG"

FROM base AS firedrake-real-int32
ARG REAL_INT32
ARG PETSC_COMMON_OPTS PETSC_NONDEBUG_OPTS PETSC_INT32_OPTS
ARG PETSC_CONFIGURE_OPTIONS="$PETSC_COMMON_OPTS $PETSC_NONDEBUG_OPTS $PETSC_INT32_OPTS"
RUN bash -c "$REAL_INT32"

FROM base AS firedrake-complex-int32
ARG COMPLEX_INT32
ARG PETSC_COMMON_OPTS PETSC_NONDEBUG_OPTS PETSC_INT32_OPTS
ARG PETSC_CONFIGURE_OPTIONS="$PETSC_COMMON_OPTS $PETSC_NONDEBUG_OPTS $PETSC_INT32_OPTS"
RUN bash -c "$COMPLEX_INT32"

FROM base AS firedrake-complex-int64
ARG COMPLEX_INT64
ARG PETSC_COMMON_OPTS PETSC_NONDEBUG_OPTS PETSC_INT64_OPTS
ARG PETSC_CONFIGURE_OPTIONS="$PETSC_COMMON_OPTS $PETSC_NONDEBUG_OPTS $PETSC_INT64_OPTS"
RUN bash -c "$COMPLEX_INT64"

FROM firedrake-$VERSION AS final
# This DockerFile is looked after by
MAINTAINER Zongze Yang <yangzongze@gmail.com>
ARG VERSION
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
