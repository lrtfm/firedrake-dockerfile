#!/bin/bash

export PETSC_DIR=$(readlink -f $(dirname `which python`)/../src/petsc)
export PETSC_ARCH=default
export SLEPC_DIR="$(find $PETSC_DIR/$PETSC_ARCH/externalpackages -maxdepth 1 -name '*slepc*')"

python -m pip install --no-build-isolation --no-binary mpi4py,randomgen,islpy,numpy \
    --no-deps -vvv --ignore-installed $SLEPC_DIR/src/binding/slepc4py

