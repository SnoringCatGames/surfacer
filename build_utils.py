import glob
import os
import sys

from snore_core.build_utils import print_error


def set_up(env: object, cpp_paths: list[str], sources: list[str], addon_dir_name: str, is_setup_for_self = False) -> None:
    if not os.path.isdir('snore_core'):
        print_error("snore_core must be a submodule of the root repository.")
        sys.exit(1)

    if is_setup_for_self:
        cpp_paths.extend([
            "src/",
        ])
        sources.extend(
            glob.glob("src/**/*.cpp", recursive=True)
        )
    else:
        cpp_paths.extend([
            addon_dir_name + "/src/",
        ])
        sources.extend(
            glob.glob(addon_dir_name + "/src/surfacer/**/*.cpp", recursive=True)
        )
