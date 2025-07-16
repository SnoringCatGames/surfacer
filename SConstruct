#!/usr/bin/env python
import os
import sys

from methods import print_error


# NOTE: Levi updated this.
libname = "Surfacer"
projectdir = "demo"

localEnv = Environment(tools=["default"], PLATFORM="")

# Build profiles can be used to decrease compile times.
# You can either specify "disabled_classes", OR
# explicitly specify "enabled_classes" which disables all other classes.
# Modify the example file as needed and uncomment the line below or
# manually specify the build_profile parameter when running SCons.

# localEnv["build_profile"] = "build_profile.json"

customs = ["custom.py"]
customs = [os.path.abspath(path) for path in customs]

opts = Variables(customs, ARGUMENTS)
opts.Update(localEnv)

Help(opts.GenerateHelpText(localEnv))

env = localEnv.Clone()

if not (os.path.isdir("godot-cpp") and os.listdir("godot-cpp")):
    print_error("""godot-cpp is not available within this folder, as Git submodules haven't been initialized.
Run the following command to download godot-cpp:

    git submodule update --init --recursive""")
    sys.exit(1)

env = SConscript("godot-cpp/SConstruct", {"env": env, "customs": customs})

# NOTE: Levi added this, to enable C++23.
# if env.get("is_msvc", False):
#     env["CXXFLAGS"].remove("/std:c++17")
#     env["CXXFLAGS"].insert(0, "/std:c++23preview")
#     env["CXXFLAGS"].insert(0, "/Zc:preprocessor")
# else:
#     env["CXXFLAGS"].remove("-std=c++17")
#     env["CXXFLAGS"].insert(0, "-std=c++23")

# NOTE: Levi updated this.
env.Append(CPPPATH=[
    "src/",
    "googletest/googletest/",
    "googletest/googletest/include/",
    "googletest/googlemock/",
    "googletest/googlemock/include/",
])

# NOTE: Levi updated this.
sources = (
    Glob("src/*.cpp") +
    Glob("src/scaffolder/*.cpp") +
    Glob("src/snore_core/*.cpp") +
    Glob("src/snore_core/internal/*.cpp") +
    Glob("src/snore_core/time/*.cpp") +
    Glob("src/surfacer/*.cpp") +
    Glob("src/surfacer/annotations/*.cpp") +
    Glob("src/surfacer/surface/*.cpp")
)

# NOTE: Levi added this, to include GoogleTest.
#       (tests=true is set when dev_mode=true is set).
# FIXME: Update build targets to optionally include `tests` and ensure all builds compile.
includes_tests = True
# includes_tests = "tests" in env and env["tests"]
if includes_tests:
    googletest_sources = (
        Glob("googletest/googletest/src/gtest-all.cc") +
        Glob("googletest/googlemock/src/gmock-all.cc")
        # Glob("googletest/googletest/src/*.cc") +
        # Glob("googletest/googlemock/src/*.cc")
    )
    googletest_exclusions = [
        # "googletest/googletest/src/gtest-all.cc",
        # "googletest/googletest/src/gtest_main.cc",
        # "googletest/googlemock/src/gmock-all.cc",
        # "googletest/googlemock/src/gmock_main.cc",
    ]
    sources.append([x for x in googletest_sources if str(x) not in googletest_exclusions])

if env["target"] in ["editor", "template_debug"]:
    try:
        doc_data = env.GodotCPPDocData("src/gen/doc_data.gen.cpp", source=Glob("doc_classes/*.xml"))
        sources.append(doc_data)
    except AttributeError:
        print("Not including class reference as we're targeting a pre-4.3 baseline.")

# .dev doesn't inhibit compatibility, so we don't need to key it.
# .universal just means "compatible with all relevant arches" so we don't need to key it.
# NOTE: Levi updated this.
# suffix = env['suffix'].replace(".dev", "").replace(".universal", "")
suffix = env['suffix']

lib_filename = "{}{}{}{}".format(env.subst('$SHLIBPREFIX'), libname, suffix, env.subst('$SHLIBSUFFIX'))

library = env.SharedLibrary(
    "bin/{}/{}".format(env['platform'], lib_filename),
    source=sources,
)

copy = env.Install("{}/bin/{}/".format(projectdir, env["platform"]), library)

default_args = [library, copy]
Default(*default_args)
