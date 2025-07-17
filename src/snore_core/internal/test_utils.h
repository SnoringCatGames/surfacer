#ifndef TEST_UTILS_H
#define TEST_UTILS_H

#ifdef DEBUG_ENABLED

#include <gtest/gtest.h>
#include <godot_cpp/classes/ref.hpp>

namespace godot {

#define EXPECT_VECTOR2_EQ(m_expected, m_actual)                                \
	do {                                                                       \
		EXPECT_FLOAT_EQ(m_expected.x, m_actual.x);                             \
		EXPECT_FLOAT_EQ(m_expected.y, m_actual.y);                             \
	} while (0)

} //namespace godot

#endif // DEBUG_ENABLED

#endif // TEST_UTILS_H
