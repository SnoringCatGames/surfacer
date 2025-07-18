#ifndef TEST_UTILS_H
#define TEST_UTILS_H

#ifdef DEBUG_ENABLED

#include "snore_core/internal/test_utils.h"
#include <gtest/gtest.h>
#include <godot_cpp/classes/ref.hpp>

namespace godot {

#define EXPECT_VECTOR2_EQ(m_expected, m_actual)                                \
	do {                                                                       \
		EXPECT_FLOAT_EQ(m_expected.x, m_actual.x);                             \
		EXPECT_FLOAT_EQ(m_expected.y, m_actual.y);                             \
	} while (0)

#define EXPECT_STRING_EQ(m_expected, m_actual)                                 \
	EXPECT_EQ(String(m_expected), String(m_actual))

} //namespace godot

#endif // DEBUG_ENABLED

#endif // TEST_UTILS_H
