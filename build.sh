#!/bin/bash

docker build -f Dockerfile.env --tag lrtfm/firedrake-env .
docker push lrtfm/firedrake-env

docker build -f Dockerfile --build-arg VERSION=real-int32 --tag lrtfm/firedrake-real-int32 .
docker push lrtfm/firedrake-real-int32

docker build -f Dockerfile --build-arg VERSION=complex-int64 --tag lrtfm/firedrake-complex-int64 .
docker push lrtfm/firedrake-complex-int64

tag=`date +%Y%m%d`

docker tag lrtfm/firedrake-env lrtfm/firedrake-env:$tag
docker tag lrtfm/firedrake-real-int32 lrtfm/firedrake-real-int32:$tag
docker tag lrtfm/firedrake-complex-int64 lrtfm/firedrake-complex-int64:$tag

docker push lrtfm/firedrake-env:$tag
docker push lrtfm/firedrake-real-int32:$tag
docker push lrtfm/firedrake-complex-int64:$tag

docker build --build-arg BASE_IMAGE=lrtfm/firedrake-real-int32:latest \
             --build-arg UID=`id -u` \
             --tag firedrake-real-int32-local \
             -f Dockerfile.local .

docker build --build-arg BASE_IMAGE=lrtfm/firedrake-complex-int64:latest \
             --build-arg UID=`id -u` \
             --tag firedrake-complex-int64-local \
             -f Dockerfile.local .

