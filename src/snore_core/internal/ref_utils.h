#ifndef REF_UTILS_H
#define REF_UTILS_H

#include <godot_cpp/classes/ref.hpp>

namespace godot {

#define IS_VALID_REF(m_ref)                                                    \
	((m_ref).is_valid() && IS_VALID_OBJECT((m_ref).ptr()))
#define IS_VALID_OBJECT(m_object_ptr) ((m_object_ptr) != nullptr)

template <typename T> Ref<T> instantiate_ref() {
	Ref<T> ref;
	ref.instantiate();
	return ref;
}

// TODO: Go through and update classes to use set_up.

// A common pattern in SnoreCore is to use a SetUp method to initialize an
// object with arguments, since GDExtension doesn't currently support
// constructor arguments.
//
// This function will both instantiate a Ref containing the object and call
// set_up with the given arguments.
template <typename T, typename... Args> Ref<T> set_up_ref(Args... args) {
	Ref<T> ref;
	ref.instantiate();
	ref->set_up(args...);
	return ref;
}

} //namespace godot

#endif // REF_UTILS_H
