#!/usr/bin/env python
import os
import sys

from scaffolder.build_utils import set_up_scaffolder
from snore_core.methods import print_error
from snore_core.build_utils import post_setup, pre_setup, set_up_snore_core
from squirrel_away.build_utils import set_up_squirrel_away
from surfacer.build_utils import set_up_surfacer


libname = "Surfacer"
projectdir = "demo"

env = pre_setup()

cpppaths = []
sources = []

set_up_snore_core(env, cpppaths, sources)
set_up_scaffolder(env, cpppaths, sources)
set_up_surfacer(env, cpppaths, sources)
set_up_squirrel_away(env, cpppaths, sources)

post_setup(env, cpppaths, sources, libname, projectdir)
