#!/bin/bash

set -e
# set -x
export DOCKER_BUILDKIT=0

# _VERSIONS="real-int32 real-int32-debug complex-int32 complex-int32-debug complex-int64 complex-int64-debug"
for field in real complex; do
    for int in -int32 -int64; do
        _VERSIONS=${_VERSIONS:+$_VERSIONS$'\n'}
        for debug in "" -debug; do
            _VERSIONS="$_VERSIONS $field$int$debug"
        done
    done
done

for field in real complex; do
    for int in -int32 -int64; do
        _MKL_VERSIONS=${_MKL_VERSIONS:+$_MKL_VERSIONS$'\n'}
        for debug in "" -debug; do
            _MKL_VERSIONS="$_MKL_VERSIONS $field$int-mkl$debug"
        done
    done
done

help_fun() {
    echo ""
    echo "$0 Build firedrake images"
    echo ""
    echo "Usage:"
    echo "  $0 [-b] [-p] [-t <versionlist>]"
    echo "    -b: build env and base images otherwise pull from repo"
    echo "    -i: int type: int32 or int64"
    echo "    -l: build local image"
    echo "    -m: build all mkl verion if '-t all' is given or omit"
    echo "    -p: push the build images (only for env and base images)"
    echo "    -t: a list of build versions"
    echo "        optinal versions are:"
    echo ""
    echo "          ${_VERSIONS//$'\n'/$'\n'          }"
    echo "          ${_MKL_VERSIONS//$'\n'/$'\n'          }"
    echo ""
    echo "        build all the versions without mkl if this option is omit"
    echo "    -v: print the selected versions and exit"
    echo "    -x: do not use cached \`--no-cache\` for build"
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


while getopts 'bhi:lmpt:vx' OPT
do
    case $OPT in
        b) BUILD="build";;
        i) INTTYPE=$OPTARG;;
        l) LOCAL="local";;
        m) MKL="mkl";;
        p) PUSH="push";;
        t) VERSIONS=$OPTARG;;
        v) DRYRUN="dryrun";;
        x) NOCACHE="--no-cache";;
        ?) help_fun;;
    esac
done

# VERSIONS="${VERSIONS-real-int32}"

if [[ "$VERSIONS" == "all" || "$VERSIONS" == "" ]]
then
    if [[ "$MKL" == "mkl" ]]; then
        __VERSIONS=$_MKL_VERSIONS
    else
        __VERSIONS=$_VERSIONS
    fi

    VERSIONS=""
    for v in $__VERSIONS; do
        if [[ "$v" =~ .*"$INTTYPE".* ]]; then
            VERSIONS="${VERSIONS:+$VERSIONS }$v"
        fi
    done
else
    # check the valid versions
    for v in $VERSIONS
    do
        _check=""
        for _v in $_VERSIONS $_MKL_VERSIONS
        do
            if [[ "$_v" == "$v" ]]
            then
                _check="ok"
            fi
        done
        if [[ "$_check" != "ok" ]]
        then
            echo ""
            echo "Error: version '$v' not in ${_VERSIONS//$'\n'/$'\n'    } ${_MKL_VERSIONS//$'\n'/$'\n'    }"
            help_fun
        fi
    done
fi

if [[ -z "$VERSIONS" ]]; then
   echo "List VERSIONS is EMPTY!"
   exit 0
fi

if [[ "$BUILD" == "build" || "$LOCAL" == "local" ]]; then
    sleep 0
else
    echo -e "\nNothing will be built!\n"
fi

function echo_versions_wrap()
{
    echo "    ""`echo $1 | sed -e 's/\([^[:space:]]\+\) \([^[:space:]]\+[[:space:]]\)/\1 \2\n    /g'`"
}

if [[ "$BUILD" == "build" ]]; then
    echo Versions:
    echo "    env env-mkl"
    echo_versions_wrap "$VERSIONS"
fi

if [[ "$LOCAL" == "local" ]]; then
    echo Local versions:
    LVERS=`echo $VERSIONS | sed -e 's/\([^[:space:]]\+\)/\1-local/g'`
    echo_versions_wrap "$LVERS"
fi

if [[ "$PUSH" == "push" ]]; then
    echo "Push versions:"
    echo "    env env-mkl"
    echo_versions_wrap "$VERSIONS"
fi

if [[ "$DRYRUN" == "dryrun" ]]; then
    exit 0
fi

BARGS='--network host'
if [[ "$BUILD" == "build" ]]; then
    docker build $BARGS -f Dockerfile.env --tag lrtfm/firedrake:env .
    docker build $BARGS -f Dockerfile.env-mkl --tag lrtfm/firedrake:env-mkl .
    ./build gen -a     # generate docker files
    ./build gen -a -m  # generate docker files with mkl
fi

for version in $VERSIONS
do
    if [[ "$BUILD" == "build" ]]; then
        echo ""
        echo "Build image: firedrake:$version"
        docker build $NOCACHE $BARGS -f generate/Dockerfile.$version --tag lrtfm/firedrake:$version .
        NOCACHE="" # use cache after the first image is taged, as all has been build without tag
    fi
    if [[ "$LOCAL" == "local" ]]; then
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
for version in env env-mkl $VERSIONS
do
    # tag=`docker history --format "{{.CreatedAt}}" lrtfm/firedrake:$version | head -n1 | sed -e 's/\(.*\)T\(.*\)/\1/g'`
    # tag=${tag//-/}
    #docker tag  lrtfm/firedrake:$version lrtfm/firedrake:$version-$tag
    docker push lrtfm/firedrake:$version
    # docker push lrtfm/firedrake:$version-$tag
    # docker rmi  lrtfm/firedrake:$version-$tag
done
