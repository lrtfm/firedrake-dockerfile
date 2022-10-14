#!/bin/bash

set -e

_VERSIONS="real-int32 real-int32-debug complex-int64 complex-int64-debug"

help_fun() {
    echo ""
    echo "Usage:"
    echo "  $0 [-p] [-b <versionlist>]"
    echo "    -p: push the build images"
    echo "    -b: a list of build versions"
    echo "        optinal versions are:"
    echo "          '$_VERSIONS'"
    echo "        build all the versions if this option is omit"
    echo ""
    echo "Example:"
    echo "  $0"
    echo "  $0 -p"
    echo "  $0 -b real-int32"
    echo "  $0 -p -b 'real-int32 real-int32-debug'"
    echo "  $0 -p -b \"real-int32 real-int64\""
    echo ""
    exit -1
}

while getopts 'pb:' OPT
do
    case $OPT in
        p) PUSH="push";;
        b) VERSIONS=$OPTARG;;
        ?) help_fun;;
    esac
done

# check the valid versions
for v in $VERSIONS
do
    _check=""
    for _v in $_VERSIONS
    do
        if [[ "$_v" == "$v" ]]
        then
            _check="ok"
        fi
    done
    if [[ "$_check" != "ok" ]]
    then
        echo ""
        echo "Error: version '$v' not in '$_VERSIONS'"
        help_fun
    fi
done

VERSIONS="${VERSIONS-$_VERSIONS}"

echo Build versions: $VERSIONS
echo Those version will be pushed after the build process

set -x

BARGS='--network host'
docker build $BARGS -f Dockerfile.env --tag lrtfm/firedrake-env .

for version in $VERSIONS
do
    docker build $BARGS -f Dockerfile --build-arg VERSION=$version --tag lrtfm/firedrake-$version .
    docker build $BARGS --build-arg BASE_IMAGE=lrtfm/firedrake-$version:latest \
        --build-arg UID=`id -u` --tag firedrake-$version-local \
        -f Dockerfile.local .
done

if [[ "$PUSH" != "push" ]]; then
    exit 0
fi

tag=`date +%Y%m%d`

for version in env $VERSIONS
do
    docker tag lrtfm/firedrake-$version lrtfm/firedrake-$version:$tag
    docker push lrtfm/firedrake-$version
    docker push lrtfm/firedrake-$version:$tag
done
