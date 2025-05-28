#include "scaffolder/canvas_layer_config.h"

#include "scaffolder/internal_utils.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

CanvasLayerConfig::CanvasLayerConfig() {}

CanvasLayerConfig::CanvasLayerConfig(
		const String &p_name,
		Node::ProcessMode p_process_mode) {
	name = p_name;
	process_mode = p_process_mode;
}

void CanvasLayerConfig::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_name"), &CanvasLayerConfig::get_name);
	ClassDB::bind_method(
			D_METHOD("set_name", "p_name"), &CanvasLayerConfig::set_name);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "name"), "set_name", "get_name");

	ClassDB::bind_method(
			D_METHOD("get_process_mode"), &CanvasLayerConfig::get_process_mode);
	ClassDB::bind_method(
			D_METHOD("set_process_mode", "p_process_mode"),
			&CanvasLayerConfig::set_process_mode);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::INT, "process_mode", PROPERTY_HINT_ENUM,
					PROCESS_MODE_HINT_STRING),
			"set_process_mode", "get_process_mode");
}
