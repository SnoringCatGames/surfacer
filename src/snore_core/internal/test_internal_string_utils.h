#ifndef TEST_STRING_UTILS_H
#define TEST_STRING_UTILS_H

#ifdef DEBUG_ENABLED

#include "snore_core/internal/string_utils.h"

#include <gtest/gtest.h>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/typed_array.hpp>

#include <string>
#include <vector>

TEST(StringUtilsTest, JoinStringsCStyleArray) {
	const char *strings[] = { "hello", "world", "test" };
	String result = join_strings(strings, 3, ", ");
	EXPECT_EQ("hello, world, test", result.utf8());
}

TEST(StringUtilsTest, JoinStringsCStyleArraySingleElement) {
	const char *strings[] = { "single" };
	String result = join_strings(strings, 1, ", ");
	EXPECT_EQ("single", result.utf8());
}

TEST(StringUtilsTest, JoinStringsCStyleArrayEmpty) {
	const char **strings = nullptr;
	String result = join_strings(strings, 0, ", ");
	EXPECT_EQ("", result.utf8());
}

TEST(StringUtilsTest, JoinStringsConstCStyleArray) {
	const char *const strings[] = { "foo", "bar", "baz" };
	String result = join_strings(strings, 3, "-");
	EXPECT_EQ("foo-bar-baz", result.utf8());
}

TEST(StringUtilsTest, JoinStringsStdVector) {
	std::vector<std::string> strings = { "alpha", "beta", "gamma" };
	String result = join_strings(strings, "|");
	EXPECT_EQ("alpha|beta|gamma", result.utf8());
}

TEST(StringUtilsTest, JoinStringsStdVectorEmpty) {
	std::vector<std::string> strings;
	String result = join_strings(strings, "|");
	EXPECT_EQ("", result.utf8());
}

TEST(StringUtilsTest, JoinStringsTypedArray) {
	TypedArray<String> strings;
	strings.push_back(String("first"));
	strings.push_back(String("second"));
	strings.push_back(String("third"));

	String result = join_strings(strings, " + ");
	EXPECT_EQ("first + second + third", result.utf8());
}

TEST(StringUtilsTest, JoinStringsTypedArrayEmpty) {
	TypedArray<String> strings;
	String result = join_strings(strings, " + ");
	EXPECT_EQ("", result.utf8());
}

TEST(StringUtilsTest, JoinStringsWithDifferentDelimiters) {
	const char *strings[] = { "a", "b", "c" };

	String result1 = join_strings(strings, 3, "");
	EXPECT_EQ("abc", result1.utf8());

	String result2 = join_strings(strings, 3, " -> ");
	EXPECT_EQ("a -> b -> c", result2.utf8());

	String result3 = join_strings(strings, 3, "\n");
	EXPECT_EQ("a\nb\nc", result3.utf8());
}

#endif // DEBUG_ENABLED

#endif // TEST_STRING_UTILS_H
