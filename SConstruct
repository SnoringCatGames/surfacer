#!/usr/bin/env python
import os
import sys

from snore_core.build_utils import (
    default_addon_dir_name as snore_core_addon_dir_name,
    create_symlink as create_symlink_snore_core,
    post_setup as post_setup_snore_core,
    pre_setup as pre_setup_snore_core,
    set_up as set_up_snore_core,
)
from build_utils import (
    default_addon_dir_name as surfacer_addon_dir_name,
    default_lib_name as surfacer_lib_name,
    set_up as set_up_surfacer,
)


env = pre_setup_snore_core(ARGUMENTS, Environment, Variables, Help, SConscript)

cpp_paths = []
sources = []
libs = []
lib_paths = []

set_up_snore_core(
    env,
    cpp_paths,
    sources,
    libs,
    lib_paths,
    snore_core_addon_dir_name,
    is_setup_for_self=False,
)
set_up_surfacer(
    env,
    cpp_paths,
    sources,
    libs,
    lib_paths,
    surfacer_addon_dir_name,
    is_setup_for_self=True,
)

post_setup_snore_core(
    env,
    cpp_paths,
    sources,
    libs,
    lib_paths,
    surfacer_lib_name,
    surfacer_addon_dir_name,
    Default,
)

create_symlink_snore_core(False)
