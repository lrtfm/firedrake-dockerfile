# DockerFile for firedrake
# Based on https://github.com/firedrakeproject/firedrake/blob/master/docker
#
# build cmd:
#
# $ docker build -f Dockerfile --build-tag VERSION=complex-int64 --tag lrtfm/firedrake-complex-int64 .
# $ docker build -f Dockerfile --build-tag VERSION=real-int32 --tag lrtfm/firedrake-real-int32 .

ARG VERSION=real-int32

# Notes on PETSc:
#   1. hpddm needs -fext-numeric-literals
#      Ref: https://gcc.gnu.org/onlinedocs/gcc/C_002b_002b-Dialect-Options.html
#      Change the dialect from c++11 to gnu++11 can fix this.
#      See ARG CXX_DIALECT_HACK if this is needed
#
#   2. There is an error when build libpng with optiong '-g3'
#      Ref:
#        + https://github.com/glennrp/libpng/issues/254
#        . https://gitlab.com/petsc/petsc/-/issues/1265
#
#   3. Pragmatic cannot be built with 64-bit integers
#

ARG PETSC_COMMON_OPTS="\
--download-fftw \
--download-mmg \
--download-p4est \
--download-parmmg \
--download-triangle \
--download-tetgen \
"
# --download-hpddm \
# --download-bamg --download-ctetgen \
# --download-egads --download-exodusii \
# --download-ks --download-libceed \
# --download-opencascade \
# --download-muparser \

# ARG PETSC_DEBUG_OPTS=""
ARG PETSC_NONDEBUG_OPTS="--download-libpng"
ARG PETSC_INT64_OPTS="--download-scalapack --download-mumps"
ARG PETSC_INT32_OPTS="--download-pragmatic"

ARG FIRDRAKE_COMMON_OPTS="--slepc \
--no-package-manager --disable-ssh \
--documentation-dependencies \
--remove-build-files \
"
ARG FIRDRAKE_NONDEBUG_OPTS=""
ARG CLEAN_PIP_CACHED="rm -rf /home/firedrake/.cached/pip"
ARG REAL_INT32="\
python3 firedrake-install $FIRDRAKE_COMMON_OPTS $FIRDRAKE_NONDEBUG_OPTS \
&& $CLEAN_PIP_CACHED \
"
ARG REAL_INT32_DEBUG="\
python3 firedrake-install $FIRDRAKE_COMMON_OPTS \
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

FROM lrtfm/firedrake-env:latest AS base
# ARG CXX_DIALECT_HACK="sed -i.bkp -e 's/\(--with-cxx-dialect=\)C++11/\1gnu++11/g' firedrake-install"
USER firedrake
WORKDIR /home/firedrake
RUN curl -O https://raw.githubusercontent.com/firedrakeproject/firedrake/master/scripts/firedrake-install
# RUN bash -c "$CXX_DIALECT_HACK"

FROM base AS debug
ARG DEBUG_HACK="sed -i.bak -e 's/\(--with-debugging=\)0/\11/g' firedrake-install"
RUN bash -c "$DEBUG_HACK"

FROM debug AS firedrake-real-int32-debug
ARG REAL_INT32_DEBUG
ARG PETSC_COMMON_OPTS PETSC_INT32_OPTS
ARG PETSC_CONFIGURE_OPTIONS="$PETSC_COMMON_OPTS $PETSC_INT32_OPTS"
RUN bash -c "$REAL_INT32_DEBUG"

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
