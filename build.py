#!/bin/env python3
import os
import sys
import click

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


def get_petsc_opts(int_type, complex=False, debug=False):

    common_pkgs = [
        # "bamg", "ctetgen", "egads", "exodusii",
        "fftw",
        # "hpddm",
        # "ks", "libceed",
        "mmg",  # "muparser", "opencascade",
        "p4est",
        "parmmg",
        "triangle",
        "tetgen",
    ]
    debug_map = {"debug": [], "nondebug": ["libpng"]}
    int_type_map = {"int32": ["pragmatic"], "int64": ["mumps", "scalapack"]}
    field_map = {"real": [], "complex": []}

    if int_type not in int_type_map.keys():
        raise "Int type {int_type} not in int_type_map.keys()!"

    pkgs = []
    pkgs += common_pkgs
    pkgs += int_type_map[int_type]
    pkgs += field_map["real" if not complex else "complex"]
    pkgs += debug_map["debug" if debug else "nondebug"]

    opts = ["--download-" + pkg for pkg in pkgs]

    return " \\\n".join(opts)


def get_firedrake_opts(int_type, complex=False, debug=False):
    common_opts = [
        "--slepc",
        "--no-package-manager",
        "--disable-ssh",
        "--documentation-dependencies",
        "--remove-build-files",
    ]

    debug_map = {
        "debug": [],
        "nondebug": [],
    }
    int_type_map = {
        "int32": [],
        "int64": ["--petsc-int-type int64"],
    }
    field_map = {
        "real": [],
        "complex": ["--complex"],
    }

    if int_type not in int_type_map.keys():
        raise "Precision {int_type} not in int_type_map.keys()!"

    opts = []
    opts += common_opts
    opts += int_type_map[int_type]
    opts += field_map["real" if not complex else "complex"]
    opts += debug_map["debug" if debug else "nondebug"]

    return " \\\n  ".join(opts)


def get_version_string(int_type, complex=False, debug=False):
    return ("complex-" if complex else "real-") + int_type + ("-debug" if debug else "")


def get_dockerfile_content(int_type, complex=False, debug=False):
    clean_pip_cached_cmd = "rm -rf /home/firedrake/.cached/pip"
    firedrake_install = "python3 firedrake_install"

    version = get_version_string(int_type, complex, debug)
    petsc_opts = get_petsc_opts(int_type, complex=complex, debug=debug)
    firedrake_opts = get_firedrake_opts(int_type, complex=complex, debug=debug)

    install_script_url = (
        "https://raw.githubusercontent.com/firedrakeproject"
        "/firedrake/master/scripts/firedrake-install"
    )

    content = f"""
FROM lrtfm/firedrake-env:latest

MAINTAINER Zongze Yang <yangzongze@gmail.com>

USER firedrake
WORKDIR /home/firedrake

ARG VERSION={version}
RUN echo "Build for firedrake-$VERSION"
RUN curl -O {install_script_url}
"""

    if debug:
        content += r"""
# Patch for debugging version
RUN bash -c "sed -i.bak -e 's/\(--with-debugging=\)0/\11/g' firedrake-install"
"""

    gnu_dialect = False
    if gnu_dialect:
        content += r"""
# Patch for gnu++11 dialect
RUN bash -c "sed -i.bkp -e 's/\(--with-cxx-dialect=\)C++11/\1gnu++11/g' firedrake-install"
"""

    content += f"""
ARG PETSC_CONFIGURE_OPTIONS="{petsc_opts}"
RUN bash -c "python3 firedrake-install {firedrake_opts} && \\
{clean_pip_cached_cmd}"
"""

    # TODO: use var to replace the pip packages
    content += r"""
RUN bash -c "\
. /home/firedrake/firedrake/bin/activate && \
pip install jupyterlab ipyparallel ipywidgets && \
pip install mpltools meshio gmsh scipy pyyaml pandas && \
rm -rf /home/firedrake/.cached/pip \
"

ENV OMP_NUM_THREADS=1
ENV PATH=/home/firedrake/firedrake/bin:$PATH

CMD /home/firedrake/firedrake/bin/jupyter-lab --ip 0.0.0.0 --no-browser --allow-root
"""

    return content


@click.command()
@click.option(
    "--int-type",
    type=click.Choice(["int32", "int64"]),
    default="int32",
    required=False,
    help="int type for the build",
)
@click.option(
    "-c",
    "-complex",
    "--complex",
    is_flag=True,
    default=False,
    required=False,
    help="build complex mode",
)
@click.option(
    "-d",
    "--debug",
    is_flag=True,
    default=False,
    required=False,
    help="build debug version",
)
@click.option(
    "-f",
    "--filename",
    default="Dockerfile",
    required=False,
    help="output the docker file",
)
@click.option(
    "-p", "--path", default="generate", required=False, help="output the docker file"
)
def generate_dockerfile(int_type, complex, debug, path, filename):

    version = get_version_string(int_type, complex, debug)
    content = get_dockerfile_content(int_type, complex, debug)
    if not os.path.exists(path):
        os.makedirs(path)
    fullname = os.path.join(path, ".".join([filename, version]))
    with open(fullname, "w") as f:
        f.write(content)


# TODO:
# def build_images():
#     if build_env:
#         build_docker_image("Dockerfile.env", tag="lrtfm/firedrake-env")
#
#     build_docker_image(fullname, tag=f"lrtfm/firedrake-{version}")

# def build_docker_image(fullname, tag, push):
#     common_args = "--network host"
#     cmd = f"docker build {common_args} -f {fullname} --tag {tag} ."
#

if __name__ == "__main__":
    generate_dockerfile()
