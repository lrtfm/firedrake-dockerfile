import subprocess
import sys
import os
from glob import iglob
from itertools import chain


def get_petsc_dir():
    petsc_dir = os.path.join(os.environ["VIRTUAL_ENV"], "src", "petsc")
    petsc_arch = "default"
    return petsc_dir, petsc_arch


def check_call(arguments):
    try:
        subprocess.check_output(arguments, stderr=subprocess.STDOUT, env=os.environ)
    except subprocess.CalledProcessError as e:
        print(e.output.decode())
        raise


def remove_build_files():
    petsc_dir, petsc_arch = get_petsc_dir()
    check_call(["rm", "-rf", os.path.join(petsc_dir, petsc_arch, "externalpackages")])
    check_call(["rm", "-rf", os.path.join(petsc_dir, "src", "docs")])
    tutorial_output = os.path.join(petsc_dir, "src", "**", "tutorials", "output", "*")
    test_output = os.path.join(petsc_dir, "src", "**", "tests", "output", "*")
    for deletefile in chain(iglob(tutorial_output, recursive=True),
                            iglob(test_output, recursive=True)):
        check_call(["rm", "-f", deletefile])


if __name__ == "__main__":
    remove_build_files()

