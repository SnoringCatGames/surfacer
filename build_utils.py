import glob
import os
import sys

from snore_core.build_utils import (
    create_addon_platform_dir_name,
    create_lib_filename,
    print_error,
)


default_lib_name = "Surfacer"
default_addon_dir_name = "surfacer"


def set_up(
    env: object,
    cpp_paths: list[str],
    sources: list[str],
    libs: list[str],
    lib_paths: list[str],
    surfacer_addon_dir_name: str,
    is_setup_for_self=False,
) -> None:
    if not os.path.isdir("snore_core"):
        print_error("snore_core must be a submodule of the root repository.")
        sys.exit(1)

    if is_setup_for_self:
        cpp_paths.extend(["src/"])
        sources.extend(glob.glob("src/**/*.cpp", recursive=True))
    else:
        cpp_paths.extend([surfacer_addon_dir_name + "/src/"])
        # Use a DLL rather than statically including .cpp files.
        # sources.extend([])
        lib_filename = create_lib_filename(env, default_lib_name, False)
        libs.extend([lib_filename])
        addon_platform_dir_name = create_addon_platform_dir_name(
            env, surfacer_addon_dir_name
        )
        lib_paths.extend([addon_platform_dir_name])


# Make the Surfacer GDExtension and GDScript addon files accessible from the root module's demo.
def create_symlink() -> None:
    original_path = os.path.abspath("surfacer/demo/addons/surfacer")
    link_path = os.path.abspath("demo/addons/surfacer")
    if not os.path.lexists(link_path):
        os.symlink(original_path, link_path, target_is_directory=True)
