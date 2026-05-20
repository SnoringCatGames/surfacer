import glob
import os
import sys

# Workspace-sibling layout: snore_core lives next to surfacer, not nested.
sys.path.insert(0, os.path.abspath(".."))

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
    if not os.path.isdir("../snore_core"):
        print_error(
            "../snore_core must be a workspace-sibling directory.\n"
            "Run scripts/bootstrap-workspace.ps1 from the bootstrapper repo "
            "to clone all required siblings."
        )
        sys.exit(1)

    src_path = (
        is_setup_for_self
        and "src/"
        or "../{}/src/".format(surfacer_addon_dir_name)
    )
    cpp_paths.extend([src_path])
    sources.extend(glob.glob("{}**/*.cpp".format(src_path), recursive=True))
