---
mode: agent
---
Your goal is to port a GDScript file to C++ code.

Ask for the destination folder for the C++ code if not provided.

- Include GDExtension bindings in the generated C++ logic.
- Create a test file for the C++ code.
- The location of the new logic will determine which module the the C++ code belongs to; this module will be one of snore_core_main_module.cpp, scaffolder_module.cpp, or surfacer_module.cpp.
- Register the C++ class in the corresponding module.
- Include the test file in the corresponding module.
- Assertion functions for Vector equality can be found in internal_test_utils.h.
