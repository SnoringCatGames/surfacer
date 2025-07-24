import glob
import os
import sys

from snore_core.build_utils import print_error


default_lib_name = "Surfacer"
default_addon_dir_name = "surfacer"


def set_up(
    env: object,
    cpp_paths: list[str],
    sources: list[str],
    surfacer_addon_dir_name: str,
    is_setup_for_self=False,
) -> None:
    if not os.path.isdir("snore_core"):
        print_error("snore_core must be a submodule of the root repository.")
        sys.exit(1)

    src_path = is_setup_for_self and "src/" or surfacer_addon_dir_name + "/src/"
    cpp_paths.extend([src_path])
    sources.extend(glob.glob(src_path + "**/*.cpp", recursive=True))
