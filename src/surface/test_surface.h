#ifndef TEST_SURFACE_H
#define TEST_SURFACE_H

// FIXME: LEFT OFF HERE: --------------------------------
// - Use describe() and it() from tester.h, to auto-register the tests.
// - Update this file to test Surface logic.

#include "tester.h"

#include "godot_cpp/classes/packed_scene.hpp"
#include "godot_cpp/classes/resource_loader.hpp"
#include "godot_cpp/variant/utility_functions.hpp"

// clang-format off

describe("Hello test suite!", [](){
    it("Hello test case!", [](){
        TESTS(
            "Hello test",
            1 == 1,
            2 == 2,
            3 == 3,
            4 == 4
        )
    });
});

// void test_dictionary() {
//     godot::Dictionary map;
//     map["Hello"] = 0;
//     map["Hey"] = 999;
//     map["this_test_will_fail"] = -1;

//     TESTS(
//         "dictionary_test",
//         map["Hello"] == godot::Variant(0),
//         map["Hey"] == godot::Variant(999),
//         map["this_test_will_fail"] == godot::Variant(999),
//         map.has("Howdy"),
//         map.size() == 3
//     )

//     NAMED_TESTS(
//         "Dictionary Variant Test",
//         "Check equal to 0", VAR_CHECK(map["Hello"], 0),
//         "Check equal to 999", VAR_CHECK(map["Hey"], 999),
//         "This will always fail why even test it?", VAR_CHECK(map["this_test_will_fail"], 999),
//         "Check for non-existent member", map.has("Howdy"),
//     )
// }

// void test_custom_object() {
//     TEST_OBJECT(CustomObject, custom_object) // TEST_OBJECT safely tests an object in a way that will never skip any other tests (unless your test code causes a crash), see SFT.hpp for more info.
//     NAMED_TESTS(
//         "CustomObject",
//         "get_name", STRING_CHECK(custom_object->get_name(), "WrongName"),
//         "get_custom_function", VAR_CHECK(custom_object->get_custom_function(), "CustomFunctionReturn")
//     )
//     TEST_OBJECT_END(custom_object) // TEST_OBJECT_END must be put at the end of the thing TEST_OBJECT is testing so it can clean itself up.
// }

// void test_custom_scene() {
//     Control *root_node;
//     TEST_SCENE("res://scenes/main_menu.tscn", Control, root_node) // Same API as TEST_OBJECT but it instantiates the scene and from it's path.

//     NAMED_TESTS(
//         "MainMenu Tests",
//         "visibility", root_node->is_visible()
//     )

//     TEST_SCENE_END(root_node)  // TEST_SCENE_END must be put at the end of the thing TEST_SCENE is testing so it can clean itself up, see SFT.hpp for more info.

//     // Additional checks are optional, if you don't pass in any more it will still test if the scene is possible to instantiate.
//     Control *broken_root_node
//     TEST_SCENE("res://scenes/broken_scene.tscn", Control, broken_root_node)
//     TEST_SCENE_END(broken_root_node)
// }

// clang-format on

#endif
