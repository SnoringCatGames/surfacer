#!/usr/bin/env python
import os
import sys

from scaffolder.build_utils import set_up as set_up_scaffolder
from snore_core.build_utils import \
    post_setup as post_setup_snore_core, \
    pre_setup as pre_setup_snore_core, \
    set_up as set_up_snore_core
from build_utils import set_up as set_up_surfacer


lib_name = "Surfacer"
addon_dir_name = "surfacer"

env = pre_setup_snore_core()

cpp_paths = []
sources = []

set_up_snore_core(env, cpp_paths, sources)
set_up_scaffolder(env, cpp_paths, sources)
set_up_surfacer(env, cpp_paths, sources)

post_setup_snore_core(env, cpp_paths, sources, lib_name, addon_dir_name)

# Make the SnoreCore GDExtension and GDScript addon files accessible from the Surfacer demo.
os.symlink("snore_core/demo/addons/snore_core", "demo/addons/snore_core", target_is_directory=True)
