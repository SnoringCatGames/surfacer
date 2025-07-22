import glob
import os
import sys

from ..snore_core.methods import print_error


def set_up_snore_core(*env: object, cpppaths: list[str], sources: list[str], path_prefix="surfacer/") -> None:
    if not os.path.isdir('snore_core'):
        print_error("snore_core must be a submodule of the root repository.")
        sys.exit(1)

    cpppaths.extend([
        path_prefix + "src/",
    ])

    sources.extend(
        glob.glob(path_prefix + "src/surfacer/**/*.cpp", recursive=True)
    )
