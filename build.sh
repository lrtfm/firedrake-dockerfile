#!/bin/bash

set -e

_VERSIONS="real-int32 real-int32-debug complex-int64 complex-int64-debug"

help_fun() {
    echo ""
    echo "Build firedrake images"
    echo ""
    echo "Usage:"
    echo "  $0 [-b] [-p] [-t <versionlist>]"
    echo "    -p: push the build images"
    echo "    -b: build env and base images too"
    echo "    -t: a list of build versions"
    echo "        optinal versions are:"
    echo "          '$_VERSIONS'"
    echo "        build all the versions if this option is omit"
    echo "    -n: do not build local image"
    echo "    -x: do not use cached: `--no-cache` for build"
    echo ""
    echo "Example:"
    echo "  $0 # only build local image real-int32"
    echo "  $0 -t real-int32"
    echo "  $0 -t all # build local images all"
    echo "  $0 -b -t real-int32"
    echo "  $0 -p -t 'real-int32 real-int32-debug'"
    echo "  $0 -p -t \"real-int32 complex-int64\""
    echo ""
    exit -1
}

while getopts 'nbhpxt:' OPT
do
    case $OPT in
        p) PUSH="push";;
        t) VERSIONS=$OPTARG;;
        b) BUILD="build";;
        n) NOLOCAL="nolocal";;
        x) NOCACHE="--no-cache";;
        ?) help_fun;;
    esac
done

if [[ "$VERSIONS" == "all" || "$VERSIONS" == "" ]]
then
    VERSIONS=$_VERSIONS
fi

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

VERSIONS="${VERSIONS-real-int32}"

echo Versions: $VERSIONS

# set -x

BARGS='--network host'
if [[ "$BUILD" == "build" ]]; then
    docker build $BARGS -f Dockerfile.env --tag lrtfm/firedrake:env .
fi

for version in $VERSIONS
do
    if [[ "$BUILD" == "build" ]]; then
        echo ""
        echo "Build image: firedrake:$version"
        docker build $NOCACHE $BARGS -f Dockerfile --build-arg VERSION=$version --tag lrtfm/firedrake:$version .
        NOCACHE="" # use cache after the first image is taged, as all has been build without tag
    fi
    if [[ "$NOLOCAL" != "nolocal" ]]; then
        echo ""
        echo "Build local image: firedrake-$version-local-$USER"
        docker build $BARGS --build-arg BASE_IMAGE=lrtfm/firedrake:$version \
            --build-arg UID=`id -u` --tag firedrake-$version-local-$USER \
            -f Dockerfile.local .
        echo ""
    fi

done

if [[ "$PUSH" != "push" ]]; then
    exit 0
fi

# echo Those version will be pushed after the build process
for version in env $VERSIONS
do
    tag=`docker history --format "{{.CreatedAt}}" lrtfm/firedrake:$version | head -n1 | sed -e 's/\(.*\)T\(.*\)/\1/g'`
    tag=${tag//-/}
    docker tag  lrtfm/firedrake:$version lrtfm/firedrake:$version-$tag
    docker push lrtfm/firedrake:$version
    docker push lrtfm/firedrake:$version-$tag
    docker rmi  lrtfm/firedrake:$version-$tag
done
