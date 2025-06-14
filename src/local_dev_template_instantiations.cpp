#include "snore_core/snore_core_settings.h"

#include <godot_cpp/variant/String.hpp>
#include <godot_cpp/variant/typed_array.hpp>

#ifdef DEBUG_ENABLED

using namespace godot;

// Explicit template instantiation to prevent compiler optimization
template class TypedArray<SnoreCoreSettings>;

// Force instantiation of specific methods
template std::vector<SnoreCoreSettings *> TypedArray<SnoreCoreSettings>::debug()
		const;

String force_template_instantiations() {
	TypedArray<bool> bool_array;
	TypedArray<int> int_array;
	TypedArray<float> float_array;
	TypedArray<String> string_array;
	TypedArray<StringName> string_name_array;
	TypedArray<Vector2> vector2_array;
	TypedArray<Vector2i> vector2i_array;
	TypedArray<Vector3> vector3_array;
	TypedArray<Vector4> vector4_array;
	TypedArray<Transform2D> transform_array;
	TypedArray<Color> color_array;
	TypedArray<Object> object_array;
	const int total = bool_array.debug().size() + int_array.debug().size() +
			float_array.debug().size() + string_array.debug().size() +
			string_name_array.debug().size() + vector2_array.debug().size() +
			vector2i_array.debug().size() + vector3_array.debug().size() +
			vector4_array.debug().size() + transform_array.debug().size() +
			color_array.debug().size() + object_array.debug().size();
	return vformat("%d", total);
}

#endif // DEBUG_ENABLED
